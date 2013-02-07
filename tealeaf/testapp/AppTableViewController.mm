/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.	 If not, see <http://www.gnu.org/licenses/>.
 */

#import "AppTableViewController.h"
#include "TeaLeafAppDelegate.h"
#include "jansson.h"
#include "jsonUtil.h"
#import "JSONKit.h"
#include "log.h"
#include "iosVersioning.h"

static NSThread *appLoadListThread = nil;


//// AppInfo

@interface AppInfo : NSObject

@property (nonatomic, retain) NSString *_id;
@property (nonatomic, retain) NSString *appTitle;
@property (nonatomic, retain) NSString *appID;
@property (nonatomic, retain) NSString *orientation;
@property (nonatomic, retain) NSString *group;

@end

@implementation AppInfo

- (AppInfo *)initWithID:(const char*)id_str appTitle:(const char*)title_str appID:(const char*)app_id_str orientation:(const char*)supported_orientation_str group:(const char*)group_str {
	self = [super init];

	self._id = [NSString stringWithUTF8String:id_str];
	self.appTitle = [NSString stringWithUTF8String:title_str];
	self.appID = [NSString stringWithUTF8String:app_id_str];
	self.orientation = [NSString stringWithUTF8String:supported_orientation_str];
	self.group = [NSString stringWithUTF8String:group_str];

	return self;
}

- (void) dealloc {
	self._id = nil;
	self.appTitle = nil;
	self.appID = nil;
	self.orientation = nil;
	self.group = nil;
	
	[super dealloc];
}

@end


//// AppTableViewController

@interface AppTableViewController ()

@property (nonatomic, assign) TeaLeafAppDelegate *appDelegate;

@end

@implementation AppTableViewController

- (void) dealloc {
	self.listData = nil;

	[super dealloc];
}

- (void)viewDidLoad {
	self.listData = [[[NSMutableArray alloc] init] autorelease];
	CGRect frame = self.view.frame;
	CGRect tableRect = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - frame.size.height * .1);
	CGRect backButtonRect =	 CGRectMake(frame.origin.x, frame.size.height - frame.size.height * .1, frame.size.width, frame.size.height * .1);

	UIButton *backButton =	[UIButton buttonWithType:UIButtonTypeRoundedRect];
	[backButton setFrame:backButtonRect];
	[backButton setTitle:@"Back" forState:UIControlStateNormal];
	backButton.titleLabel.textColor = [UIColor blackColor];
	backButton.titleLabel.textAlignment = UITextAlignmentCenter;
	[backButton addTarget:self action:@selector(backButtonFunc) forControlEvents:UIControlEventTouchUpInside];

		
	self.tableView = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStylePlain];
	UIView *base = [[UIView alloc] initWithFrame:self.view.frame];
	[base addSubview:self.tableView];
	[base addSubview:backButton];
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
	[self.view addSubview:base];
	//create progress bar / progress bar view
	progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
   
	[progressBar setProgress:0.f];
	CGRect progressViewBackingRect = CGRectMake(frame.origin.x + frame.size.width / 8,
												frame.origin.y + frame.size.width/3,
												frame.size.width - frame.size.width / 4,
												frame.size.height / 6);
	
	progressviewBacking = [[UIView alloc] initWithFrame:frame];
	UIView *floatingBacking = [[UIView alloc] initWithFrame:progressViewBackingRect];
	[[floatingBacking layer] setCornerRadius:8.0f];
	[[floatingBacking layer] setMasksToBounds:YES];
	[progressviewBacking addSubview:floatingBacking];
	loadingTextView = [[UITextView alloc] initWithFrame:CGRectMake(0,
																   0,
																   frame.size.width - frame.size.width / 4,
																   frame.size.height / 6)];
	[[loadingTextView layer] setCornerRadius:8.0f];
	[[loadingTextView layer] setMasksToBounds:YES];
	loadingTextView.text = @"Loading...";
	loadingTextView.textAlignment = NSTextAlignmentCenter;
	loadingTextView.textColor = [UIColor whiteColor];
	loadingTextView.backgroundColor = [UIColor blackColor];
	loadingTextView.font = [UIFont fontWithName:@"Arial" size:frame.size.height / 6 / 2];
	CGRect progressRect = CGRectMake(progressViewBackingRect.size.width * .1f,
									 progressViewBackingRect.size.height - progressViewBackingRect.size.height * .2f,
									 progressViewBackingRect.size.width * .8f,
									 progressViewBackingRect.size.height * .2f);
   
	progressBar = [[UIProgressView alloc] initWithFrame:progressRect];
	
	[floatingBacking addSubview:loadingTextView];
	[floatingBacking addSubview:progressBar];
	[loadingTextView sizeToFit];
	[floatingBacking setBackgroundColor:[UIColor blackColor]];
	[progressviewBacking setBackgroundColor:[UIColor grayColor]];
	
	self.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);
	
	//make a thread
	appLoadListThread = [[NSThread alloc] initWithTarget:self selector:@selector(appLoadListThread) object:nil];
	[appLoadListThread start];
	
	[super viewDidLoad];
}


- (void)backButtonFunc {
	//check version and go
	if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		 [self.view removeFromSuperview];
		
		[((TeaLeafAppDelegate*)[UIApplication sharedApplication].delegate).window addSubview:self.appDelegate.tableViewController.view];
	} else {
		[((TeaLeafAppDelegate*)[UIApplication sharedApplication].delegate).window setRootViewController:self.appDelegate.tableViewController ];
	}
}


- (void) appLoadListThread {
	NSString *ip = [self.appDelegate.config objectForKey:@"code_host"];
	NSString *port = [self.appDelegate.config objectForKey:@"code_port"];
	NSString *url = [NSString stringWithFormat:@"http://%@:%@", ip, port];
	NSString *projectsURL = [NSString stringWithFormat:@"%@/projects", url];
	NSData *data = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:projectsURL]];
	NSString * dataString = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];
	json_error_t err;
	json_t *projects = json_loads([dataString UTF8String] , 0, &err);
	if (projects && json_is_object(projects)) {
		const char *key;
		json_t *app;
		void *iter = json_object_iter(projects);
		//loop through all games in projects list
		while(iter)
		{
		
			key = json_object_iter_key(iter);
			app = json_object_iter_value(iter);
			if (json_is_object(app)) {
				//check for id
				json_t *id_obj = json_object_get(app, "id");
				if (!json_is_string(id_obj)) {
					LOG("No id in app!");
					continue;
				}
				const char *id_str = json_string_value(id_obj);

				//check for manifest object
				json_t *manifest_obj = json_object_get(app, "manifest");
				if (!json_is_object(manifest_obj)) {
					LOG("No manifest object!");
					continue;
				}

				//get title from manifest
				json_t *title_obj = json_object_get(manifest_obj, "title");
				if (!json_is_string(title_obj)) {
					LOG("No title in manifest!");
					continue;
				}
				const char *title_str = json_string_value(title_obj);

				//get appid from manifest
				json_t *app_id_obj = json_object_get(manifest_obj, "appID");
				if (!json_is_string(app_id_obj)) {
					LOG("No appid in manifest!");
					continue;
				}
				const char *app_id_str = json_string_value(app_id_obj);

				//get group from manifest
				json_t *group_obj = json_object_get(manifest_obj, "group");
				const char *group_str = " no group"; // space at front to sort to top
				if (json_is_string(group_obj)) {
					group_str = json_string_value(group_obj);
				}

				//TODO: GET ICON(S)
				json_t *supported_orientations_obj_arr = json_object_get(manifest_obj, "supportedOrientations");
				if (!json_is_array(supported_orientations_obj_arr)) {
					LOG("No supported orientations in manifest!");
					continue;
				}
				json_t * supported_orientation_obj = json_array_get(supported_orientations_obj_arr, 0);
				if (!json_is_string(supported_orientation_obj)) {
					LOG("supported orientation not a string!");
					continue;
				}
				const char *supported_orientation_str = json_string_value(supported_orientation_obj);
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					AppInfo *appInfo = [[[AppInfo alloc] initWithID:id_str appTitle:title_str appID:app_id_str orientation:supported_orientation_str group:group_str] autorelease];

					[self insertApp:appInfo];
				}];
				
			}
		   
			/* use key and value ... */
			iter = json_object_iter_next(projects, iter);
		}
	}

}

-(void)insertApp:(AppInfo*)appInfo {
	// Insert sort
	int insert_index, list_len;
	
	for (insert_index = 0, list_len = [self.listData count]; insert_index < list_len; ++insert_index) {
		AppInfo *app = [self.listData objectAtIndex:insert_index];
		
		if (app) {
			NSComparisonResult result = [appInfo.group caseInsensitiveCompare:app.group];
			
			if (result == NSOrderedAscending) {
				break;
			} else if (result == NSOrderedSame) {
				NSComparisonResult result = [appInfo.appTitle caseInsensitiveCompare:app.appTitle];
				
				if (result == NSOrderedAscending) {
					break;
				} else if (result == NSOrderedSame) {
					NSComparisonResult result = [appInfo.appID caseInsensitiveCompare:app.appID];
					
					if (result == NSOrderedAscending) {
						break;
					} else if (result == NSOrderedSame) {
						NSLog(@"{testapp} WARNING: Ignoring duplicate app ID");
						return;
					}
				}
			}
		}
	}
	
	[self.listData insertObject:appInfo atIndex:insert_index];
	
	[self.tableView reloadData];
}

-(void)createDirectory:(NSString *)directoryName
{
	

	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtPath:directoryName withIntermediateDirectories:YES attributes:nil error:nil];
}

//creates directory if it doesn't exist and writes data to file
-(void)writeDataToFile:(NSString *)fileName withData:(NSData*)data
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *file = [documentsDirectory stringByAppendingPathComponent:fileName];
	BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:[file stringByDeletingLastPathComponent]];
	if (!dirExists) {
		[self createDirectory:[file stringByDeletingLastPathComponent]];
	}
	[data writeToFile:file atomically:YES];
  
}

-(NSString*)readDataFromFile:(NSString *)fileName
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString* file = [documentsDirectory stringByAppendingPathComponent:fileName];
	return [NSString stringWithContentsOfFile:file encoding:(NSUTF8StringEncoding) error:nil];

}

-(NSString*)getAppDir:(NSString*) appID {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:appID];

}

- (NSString*)encodeURL:(NSString *)string
{
	NSString *newString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	
	if (newString)
	{
		return newString;
	}
	
	return @"";
}

- (void)loadAppThread:(AppInfo*)appInfo {
	[self.appDelegate.config setObject:[self getAppDir:appInfo.appID] forKey:@"app_files_dir"];
	NSString *ip = [self.appDelegate.config objectForKey:@"code_host"];
	NSString *port = [self.appDelegate.config objectForKey:@"code_port"];
	NSString *url = [NSString stringWithFormat:@"http://%@:%@", ip, port];
	NSString *simulateURL = [NSString stringWithFormat:@"%@/simulate/%@/native-ios/", url, appInfo._id];
	//get native.js.mp3
	NSData *jsData = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@native.js.mp3", simulateURL]]];
	//write native.js.mp3 to file
	[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"native.js.mp3"] withData:jsData];
	//get loading.png
	NSData *loadingPNG = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@loading.png", simulateURL]]];
	//write loading.png to file
	[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"loading.png"] withData:loadingPNG];
	//get resource list
	NSData *resources = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@resource_list.json", simulateURL]]];
	NSString *resourcesStr = [[NSString alloc] initWithData:resources encoding:NSASCIIStringEncoding];
	const char * res_str = [resourcesStr UTF8String];
	json_error_t err;
	json_t *res_obj = json_loads(res_str , 0, &err);

	
	const char *prev_hashes_str = [[self readDataFromFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"resource_list.json"]] UTF8String];
	[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"resource_list.json"] withData:resources];
	json_t *prev_hashes = json_loads(prev_hashes_str, 0, &err);

	if (res_obj && json_is_object(res_obj)) {
		const char *key;
		json_t *value;
		__block int obj_count =	 json_object_size(res_obj);
		__block int cur_obj_index = 0;
		json_object_foreach(res_obj, key, value) {
			//skip native.js.mp3
			
			if (strcmp(key, "native.js.mp3") == 0) {
				continue;
			}
			const char *value_str = json_string_value(value);
			json_t *prev_hash = json_object_get(prev_hashes, key);
			bool cached = false;
			if (prev_hash && json_is_string(prev_hash)) {
				const char *prev_hash_str = json_string_value(prev_hash);
				if (strcmp(prev_hash_str, value_str) == 0) {
					cached = true;
				}
				
			}
			
			//if not cached, get and write it
			if (!cached) {
				NSString *valueStr = [NSString stringWithFormat:@"%s" , key];
				NSData *resData = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", simulateURL, valueStr]]];
				if (resData == nil) {
					//cancel everything, we need all the files to continue forward
					//run on ui thread
					dispatch_async(dispatch_get_main_queue(), ^{
						[progressviewBacking removeFromSuperview];
					});
					return;
				}
				
				[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, valueStr] withData:resData];
				NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
				NSString *documentsDirectory = [paths objectAtIndex:0];
				NSString* foofile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", appInfo.appID, valueStr]];
				BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
				NSLOG(@"EXISTS %i %@", (int)fileExists, foofile );
				
			}
			
			//run on ui thread
			dispatch_async(dispatch_get_main_queue(), ^{
				[progressBar setProgress:(float)(cur_obj_index++ / (float)obj_count)];
			});
			
		}
	}
  

	//set appid in config
	[self.appDelegate.config setObject:appInfo.appID forKey:@"app_id"];
	//run on ui thread
	dispatch_async(dispatch_get_main_queue(), ^{
		[progressviewBacking removeFromSuperview];
		//present tealeafviewcontroller
		self.appDelegate.tealeafShowing = YES;
		[self.appDelegate.tealeafViewController release];
		self.appDelegate.tealeafViewController = [[TeaLeafViewController alloc] init];

		//check version and go
		if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
			[((TeaLeafAppDelegate*)[UIApplication sharedApplication].delegate).window addSubview:self.appDelegate.tealeafViewController.view];
		}
		else {
			[((TeaLeafAppDelegate*)[UIApplication sharedApplication].delegate).window setRootViewController:self.appDelegate.tealeafViewController ];
		}
		
	});
  
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


#pragma mark -
#pragma mark Table View Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[[UITableViewCell alloc] init] autorelease];
	cell.textLabel.font = [UIFont systemFontOfSize:34.0];
	NSUInteger row = [indexPath row];
	cell.textLabel.text = [((AppInfo*)[self.listData objectAtIndex:row]) appTitle];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	AppInfo *appInfo = (AppInfo*)[self.listData objectAtIndex:row];
	
	progressBar.progress = 0.0f;
	[self.view addSubview:progressviewBacking];
	NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadAppThread:) object:appInfo];
	[thread start];
	[tableView reloadData];
	
	
}

@end
