/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.	 If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import "ServerTableViewController.h"
#import "TeaLeafAppDelegate.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "arpa/inet.h"
#import "iosVersioning.h"
#import "platform/LocalStorage.h"

@implementation ServerInfo
@end


@interface ServerTableViewController ()
@property (nonatomic, assign) TeaLeafAppDelegate *appDelegate;
@end

@implementation ServerTableViewController

- (void)viewDidLoad {
	self.listData = [[[NSMutableArray alloc] init] autorelease];

	NSString *prevIP = local_storage_get(@"testapp_prev_ip");
	if (!prevIP || [prevIP length] <= 0) {
		prevIP = @"10.0.1.16";
	}

	NSString *prevPort = local_storage_get(@"testapp_prev_port");
	if (!prevPort || [prevPort length] <= 0) {
		prevPort = @"9200";
	}

	CGRect frame = self.view.frame;

	CGRect tableRect = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height * .15f, frame.size.width, frame.size.height * .85f);
	self.tableView = [[UITableView alloc] initWithFrame:tableRect
														  style:UITableViewStylePlain];
	CGRect ipInputViewRect = CGRectMake(0, frame.size.height *.01f, frame.size.width * .52f, frame.size.height * .10f);
	self.ipInputView = [[UITextField alloc] initWithFrame:ipInputViewRect];
	[self.ipInputView setText:prevIP];
	[self.ipInputView setFont:[UIFont systemFontOfSize:25.0]];
	[self.ipInputView setBackgroundColor:[UIColor lightGrayColor]];
	[self.ipInputView setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	self.ipInputView.textAlignment = (NSTextAlignment)UITextAlignmentCenter;
	
	CGRect portInputViewRect = CGRectMake(frame.size.width *.54f, frame.size.height *.01f, frame.size.width *.28f, frame.size.height * .10f);
	self.portInputView = [[UITextField alloc] initWithFrame:portInputViewRect];
	[self.portInputView setText:prevPort];
	[self.portInputView setFont:[UIFont systemFontOfSize:25.0]];
	[self.portInputView setBackgroundColor:[UIColor lightGrayColor]];
	[self.portInputView setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	self.portInputView.textAlignment = (NSTextAlignment)UITextAlignmentCenter;
	
	CGRect buttonRect = CGRectMake(frame.size.width - frame.size.width * .16f, frame.size.height *.01f, frame.size.width * .15f, frame.size.height * .10f);
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button setFrame:buttonRect];
	[button setEnabled:YES];
	[button setUserInteractionEnabled:YES];
	[button setTitle:@"Go!" forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont systemFontOfSize:25.0];
	[button addTarget:self action:@selector(goButtonFunc) forControlEvents:UIControlEventTouchUpInside];
	UIView *base = [[UIView alloc] initWithFrame:self.view.frame];
	[base addSubview:button];
	[base addSubview:self.tableView];
	[base addSubview:self.ipInputView];
	[base addSubview:self.portInputView];
	
	[self.tableView setAllowsSelection:YES];
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
	[self.view addSubview:base];
	
	self.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);

	self.tapGestureRecognizer = [[[UITapGestureRecognizer alloc]
								  initWithTarget:self
								  action:@selector(dismissKeyboard)] autorelease];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
	   
	[super viewDidLoad];
	
}

-(void)keyboardDidShow {
	[self.view addGestureRecognizer:self.tapGestureRecognizer];
}

-(void)keyboardDidHide {
	[self.view removeGestureRecognizer:self.tapGestureRecognizer];
}

-(void)dismissKeyboard {
	[self.ipInputView resignFirstResponder];
}

- (ServerInfo *)addServerInfoFromAddressData:(NSData *)dataIn {
	struct sockaddr_in *addr = (struct sockaddr_in *)[dataIn bytes];

	char ip_str[256];
	if (!inet_ntop(AF_INET, &addr->sin_addr, ip_str, sizeof(ip_str))) {
		NSLog(@"{testapp} WARNING: Unable to stringize an IP address");
		return nil;
	}

	NSString *ns_ip_str = [NSString stringWithUTF8String:ip_str];
	size_t insert_index, list_len;

	for (insert_index = 0, list_len = [self.listData count]; insert_index < list_len; ++insert_index) {
		ServerInfo *server = [self.listData objectAtIndex:insert_index];

		if (server) {
			NSComparisonResult result = [server.ip compare:ns_ip_str];

			if (result == NSOrderedAscending) {
				break;
			} else if (result == NSOrderedSame) {
				NSLog(@"{testapp} WARNING: Ignoring duplicate IP");
				return nil;
			}
		}
	}

	// Function to parse address from NSData
	ServerInfo *serverInfo = [[[ServerInfo alloc] init] autorelease];
	serverInfo.ip = ns_ip_str;
	serverInfo.port = ntohs(addr->sin_port);

	[self.listData insertObject:serverInfo atIndex:insert_index];
	[self.tableView reloadData];

	return serverInfo;
}

- (void)launch {
	[self.appDelegate.config setObject:self.ipInputView.text forKey:@"code_host"];
	[self.appDelegate.config setObject:self.portInputView.text forKey:@"code_port"];
	self.appDelegate.appTableViewController = [[[AppTableViewController alloc] init] autorelease];
	
	local_storage_set(@"testapp_prev_ip", self.ipInputView.text);
	local_storage_set(@"testapp_prev_port", self.portInputView.text);
	
	//check version and go
	if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		[self.view removeFromSuperview];
		[((TeaLeafAppDelegate *)[UIApplication sharedApplication].delegate).window addSubview:self.appDelegate.appTableViewController.view];
	} else
		[((TeaLeafAppDelegate *)[UIApplication sharedApplication].delegate).window setRootViewController:self.appDelegate.appTableViewController ];
}

- (void)goButtonFunc {
	[self launch];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	return (toInterfaceOrientation == UIInterfaceOrientationPortrait) ||
		   (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(BOOL)shouldAutorotate {
	return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait |
		   UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)dealloc {
	[listData dealloc];
	[super dealloc];
}

#pragma mark -
#pragma mark Table View Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[[UITableViewCell alloc] init] autorelease];
	cell.textLabel.font = [UIFont systemFontOfSize:34.0];
	NSUInteger row = [indexPath row];
	cell.textLabel.text = [((ServerInfo *)[self.listData objectAtIndex:row]) ip];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger row = [indexPath row];
	ServerInfo *serverInfo = (ServerInfo *)[self.listData objectAtIndex:row];
	if (serverInfo != nil) {
		self.ipInputView.text = serverInfo.ip;
		self.portInputView.text = [NSString stringWithFormat:@"%ld", (long)serverInfo.port];

		[self launch];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath;
}

@end
