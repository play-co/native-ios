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

#import "AppTableViewController.h"
#include "TeaLeafAppDelegate.h"
#include "jansson.h"
#include "jsonUtil.h"
#include "log.h"
#include "iosVersioning.h"

static NSThread *appLoadListThread = nil;


//// AppInfo

@interface AppInfo : NSObject

@property (nonatomic, retain) NSString *_id;
@property (nonatomic, retain) NSString *appTitle;
@property (nonatomic, retain) NSString *appID;
@property (nonatomic, assign) BOOL portrait;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, retain) NSString *group;
@property (nonatomic, retain) NSDictionary *manifest;

@end

@implementation AppInfo

- (AppInfo *)initWithID:(NSString*)id_str appTitle:(NSString*)title_str appID:(NSString*)app_id_str portrait:(BOOL)portrait landscape:(BOOL)landscape group:(NSString*)group_str manifest:(NSDictionary*)manifest {
	self = [super init];

	self._id = id_str;
	self.appTitle = title_str;
	self.appID = app_id_str;
	self.portrait = portrait;
	self.landscape = landscape;
	self.group = group_str;
	self.manifest = manifest;

	return self;
}

- (void) dealloc {
	self._id = nil;
	self.appTitle = nil;
	self.appID = nil;
	self.group = nil;
	self.manifest = nil;

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
	backButton.titleLabel.textAlignment = (NSTextAlignment)UITextAlignmentCenter;
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
	NSData *data = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[projectsURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

	NSError *err;
	@try {
        NSDictionary *apps = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&err];

		for (NSString *key in apps) {
			NSDictionary *app = [apps objectForKey:key];

			NSString *id_str = [app objectForKey:@"id"];
			NSDictionary *manifest = [app objectForKey:@"manifest"];
			NSString *group = [manifest objectForKey:@"group"];
			NSString *title = [manifest objectForKey:@"title"];
			NSString *app_id = [manifest objectForKey:@"appID"];
			NSArray *orientations = [manifest objectForKey:@"supportedOrientations"];

			if (!id_str) {
				LOG("{testapp} WARNING: No id for app (ignored)");
				continue;
			}
			if (!manifest) {
				LOG("{testapp} WARNING: No manifest in app %@", id_str);
				continue;
			}
			if (!group) {
				// Use space at front to sort to top
				group = @" no group";
			}
			if (!title) {
				LOG("{testapp} WARNING: No title in manifest for app %@", id_str);
				continue;
			}
			if (!app_id) {
				LOG("{testapp} WARNING: No appID in manifest for app %@", title);
				continue;
			}

			BOOL portrait = NO, landscape = NO;
			if (orientations) {
				for (NSString *orientation in orientations) {
					if ([orientation caseInsensitiveCompare:@"landscape"] == NSOrderedSame) {
						landscape = YES;
					} else if ([orientation caseInsensitiveCompare:@"portrait"] == NSOrderedSame) {
						portrait = YES;
					} else {
						LOG("{testapp} WARNING: Typo in supportedOrientations in manifest for '%s': '%s'", title, orientation);
					}
				}
			}

			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				AppInfo *appInfo = [[[AppInfo alloc] initWithID:id_str appTitle:title appID:app_id portrait:portrait landscape:landscape group:group manifest:manifest] autorelease];

				[self insertApp:appInfo];
			}];
		}
	}
	@catch (NSException *e) {
		NSLOG(@"{testapp} ERROR: Exception while parsing app list: %@", e);
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
	self.appDelegate.testAppManifest = appInfo.manifest;

	NSString *ip = [self.appDelegate.config objectForKey:@"code_host"];
	NSString *port = [self.appDelegate.config objectForKey:@"code_port"];
	NSString *url = [NSString stringWithFormat:@"http://%@:%@", ip, port];
	NSString *simulateURL = [NSString stringWithFormat:@"%@/simulate/debug/%@/native-ios/", url, appInfo._id];
	//get native.js
    NSString *nativeJSURL = [[NSString stringWithFormat:@"%@native.js", simulateURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSData *jsData = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:nativeJSURL]];
    
    if (!jsData) {
        NSLog(@"native.js failed to download from %@", nativeJSURL);
        exit(1);
    }
    
	//write native.js to file
	[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"native.js"] withData:jsData];

	// Select orientation from manifest
	[self.appDelegate selectOrientation];

	// Update screen properties from orientation to select a splash screen
	[self.appDelegate updateScreenProperties];
	
	//get the correct loading.png
	SplashDescriptor* bestSplash = [self.appDelegate findBestSplashDescriptor];
	if (bestSplash) {
		//get loading.png
		NSData *splashData = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[[NSString stringWithFormat:@"%@splash/%s", simulateURL, bestSplash->key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		if(splashData) {
			//write splash to file
			[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, @"loading.png"] withData:splashData];
		}
	}

	//get resource list
	NSData *resources = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[[NSString stringWithFormat:@"%@resource_list.json", simulateURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
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
		__block size_t obj_count =	 json_object_size(res_obj);
		__block size_t cur_obj_index = 0;

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];

		json_object_foreach(res_obj, key, value) {
			//skip native.js
			if (strcmp(key, "native.js") == 0) {
				continue;
			}

			const char *value_str = json_string_value(value);
			NSString *valueStr = [NSString stringWithFormat:@"%s" , key];
			NSString* foofile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", appInfo.appID, valueStr]];

			BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];

			json_t *prev_hash = json_object_get(prev_hashes, key);
			bool cached = false;
			if (prev_hash && json_is_string(prev_hash)) {
				const char *prev_hash_str = json_string_value(prev_hash);
				if (strcmp(prev_hash_str, value_str) == 0) {
					if (fileExists) {
						cached = true;
						NSLOG(@"{testapp} [Hash match] Cached: %@", valueStr);
					} else {
						NSLOG(@"{testapp} [Hash match] Cache miss: %@", valueStr);
					}
				} else {
					// If the file exists already,
					if (fileExists) {
						// Remove it so that next time we will not mark it cached if it fails to download now
						[[NSFileManager defaultManager] removeItemAtPath:foofile error:nil];

						NSLOG(@"{testapp} [Mismatch hash] Removed cache: %@", valueStr);
					} else {
						NSLOG(@"{testapp} [Mismatch hash] Not found: %@", valueStr);
					}
				}
			} else {
				NSLOG(@"{testapp} [New file]: %@", valueStr);
			}

			//if not cached, get and write it
			if (!cached) {
				NSData *resData = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[[NSString stringWithFormat:@"%@%@", simulateURL, valueStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
				if (resData == nil) {
					//cancel everything, we need all the files to continue forward
					//run on ui thread
					NSLOG(@"{testapp} WARNING: Unable to find a requested file: %@", valueStr);
				} else {
					[self writeDataToFile:[NSString stringWithFormat:@"%@/%@", appInfo.appID, valueStr] withData:resData];
					BOOL fileNowExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
					
					if (!fileNowExists) {
						NSLOG(@"{testapp} WARNING: Unable to write %@", foofile);
					} else {
						NSLOG(@"{testapp} Cache update: %@", valueStr);
					}
				}
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

		self.appDelegate.tealeafViewController = nil;

		self.appDelegate.tealeafViewController = [[[TeaLeafViewController alloc] init] autorelease];

		UIWindow *window = ((TeaLeafAppDelegate*)[UIApplication sharedApplication].delegate).window;

		if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
			[self.view removeFromSuperview];

			[window addSubview:self.appDelegate.tealeafViewController.view];
		} else {
			[window setRootViewController:self.appDelegate.tealeafViewController];
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
	cell.textLabel.font = [UIFont systemFontOfSize:24.0];
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
