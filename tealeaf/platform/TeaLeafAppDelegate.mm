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

#import "TeaLeafAppDelegate.h"
#import "ResourceLoader.h"
#import "SoundManager.h"
#import "OpenGLView.h"
#import <CommonCrypto/CommonDigest.h>
#include "tealeaf_canvas.h"
#include "core.h"
#include "texture_manager.h"
#include "core/config.h"
#include "core/events.h"
#import "core/core_js.h"
#include "platform.h"
#include "jsonUtil.h"
#import "JSONKit.h"
#include "events.h"
#import "platform/log.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "arpa/inet.h"


@interface TeaLeafAppDelegate ()
@end

@implementation TeaLeafAppDelegate

- (void) dealloc {
	self.window = nil;
	self.config = nil;
	self.tealeafViewController = nil;
	self.js = nil;
	self.canvas = nil;
	self.pluginManager = nil;
	self.screenBestSplash = nil;
	self.testAppManifest = nil;

	[super dealloc];
}

- (void) setJSReady:(bool) isReady {
	js_ready = isReady;
}

- (BOOL) getJSReady {
	return js_ready;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *) options {
	//SEARCH FOR NETWORKS
	self.services = [NSMutableArray array];
	self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[self.serviceBrowser setDelegate:self];
	[self.serviceBrowser searchForServicesOfType:@"_tealeaf._tcp" inDomain:@"local."];
	self.tealeafShowing = NO;
	self.launchNotification = [options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	self.wasPaused = NO;
	UIApplication *app = [UIApplication sharedApplication];
	[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	[self.window makeKeyAndVisible];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

	//TEALEAF_SPECIFIC_START
	self.tealeafViewController = [[TeaLeafViewController alloc] init];
	self.signalRestart = NO;

	NSString *path = [[NSBundle mainBundle] resourcePath];
	NSString *finalPath = [path stringByAppendingPathComponent:@"config.plist"];
	self.config = [NSMutableDictionary dictionaryWithContentsOfFile:finalPath];

	for (id key in self.config) {
		NSLOG(@"{tealeaf} Config[%@] = %@", key, [self.config objectForKey:key]);
	}

	self.tableViewController = [[[ServerTableViewController alloc] init] autorelease];
	self.appTableViewController = [[[AppTableViewController alloc] init] autorelease];
	//TEALEAF_SPECIFIC_END

	bool isRemoteLoading = [[self.config objectForKey:@"remote_loading"] boolValue];
	if (!isRemoteLoading) {
		[self.window addSubview:self.tealeafViewController.view];
		self.window.rootViewController = self.tealeafViewController;
	} else {
		[self.window addSubview:self.tableViewController.view];
		self.window.rootViewController = self.tableViewController;
	}
	[self.window makeKeyAndVisible];

	return YES;
}

- (void) restartJS {
	bool isRemoteLoading = [[self.config objectForKey:@"remote_loading"] boolValue];
	if (!isRemoteLoading) {
		if (js_ready) {
			if (!self.signalRestart) {
				self.signalRestart = YES;

				dispatch_async(dispatch_get_main_queue(), ^{
					self.signalRestart = NO;
					core_reset();
					
					[self.tealeafViewController release];
					
					self.tealeafViewController = [[TeaLeafViewController alloc] init];
					
					[self.window addSubview:self.tealeafViewController.view];
					self.window.rootViewController = self.tealeafViewController;
				});
			}
		}
	} else {
		// NOTE: This works but in the TestApp case I would rather allow it to hang
		// so that remote debugging can be performed posthumously.
		//[self.tealeafViewController restartJS];
	}
}



//// Online State

- (void) initializeOnlineState {
	self.reach = [Reachability reachabilityForInternetConnection];

	// Set initial state
	self.isOnline = [self getNetworkStatus:self.reach];

	if (self.isOnline) {
		LOG("{reachability} Online (initially)");
	} else {
		LOG("{reachability} Offline (initially)");
	}
}

- (void) hookOnlineState {
	// Listen to network-reachable events
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

	[self.reach startNotifier];

	// Post current state event always at least once on startup
	[self postNetworkStatusEvent:self.isOnline];
}

- (BOOL) getNetworkStatus:(Reachability *)reach {
	NetworkStatus internetStatus = [reach currentReachabilityStatus];

	// Convert internetStatus into a Boolean indicating if it is online
	BOOL nowReachable = NO;
	switch (internetStatus) {
		case ReachableViaWiFi:
		case ReachableViaWWAN:
			nowReachable = YES;
			break;
		default:
		case NotReachable:
			nowReachable = NO;
			break;
	}

	return nowReachable;
}

- (void) updateNetworkStatus:(Reachability *)reach {
	// Convert internetStatus into a Boolean indicating if it is online
	BOOL nowReachable = [self getNetworkStatus:reach];

	// If state really changed,
	if (self.isOnline != nowReachable) {
		// Update wasReachable
		self.isOnline = nowReachable;

		[self postNetworkStatusEvent: nowReachable];

		if (nowReachable) {
			LOG("{reachability} Online");
		} else {
			LOG("{reachability} Offline");
		}
	}
}

- (void) postNetworkStatusEvent:(BOOL) tobeOnline {
	// Post notification to javascript
	NSString *type = tobeOnline ? @"online" : @"offline";
	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"networkStatus\",\"type\":\"%@\"}", type];
	core_dispatch_event([evt UTF8String]);
}

- (void) reachabilityChanged:(NSNotification*) notice {
	[self updateNetworkStatus: [notice object]];
}

- (void) postPauseEvent:(BOOL) isPaused {
	NSString* evt = isPaused ? @"{\"name\":\"pause\"}" : @"{\"name\":\"resume\"}";
	core_dispatch_event([evt UTF8String]);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self.canvas startRendering];
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
	UIBackgroundTaskIdentifier bgTask = nil;

	bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
		// With the mighty power of closures, smite this task!
		[application endBackgroundTask:bgTask];
	}];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[NSThread sleepForTimeInterval:5.f];
		// With the mighty power of closures, smite this task!
		[application endBackgroundTask:bgTask];
	});

	[self.canvas stopRendering];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	self.wasPaused = YES;
	
	[self.canvas stopRendering];
	
	if (js_ready) {
		[self postPauseEvent:self.wasPaused];
	}
	
	LOG("{focus} Lost focus");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	self.wasPaused = NO;
	[self.canvas startRendering];
	[self postPauseEvent:self.wasPaused];
	
	if (js_ready) {
		[self postPauseEvent:self.wasPaused];
	}

	if (self.pluginManager) {
		[self.pluginManager applicationDidBecomeActive:application];
	}
	
	LOG("{focus} Gained focus");
}


//What else should we do here? TODO
- (void)applicationWillTerminate:(UIApplication *)application {
	if (self.js) {
		[self.js dealloc];
	}
	if (self.pluginManager) {
		[self.pluginManager applicationWillTerminate:application];
	}

}


#pragma mark Network Search
// Sent when browsing begins
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
			 didNotSearch:(NSDictionary *)errorDict
{
   NSLOG(@"netServiceBrowser didNotSearch %@", [errorDict objectForKey:NSNetServicesErrorCode]);
	
	//searching = NO;
	//[self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLOG(@"netService didNotResolve %@", [errorDict objectForKey:NSNetServicesErrorCode]);

}

// Sent when a service appears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing
{
	 
	[self.services addObject:aNetService];
	[aNetService retain];
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout:20.0];
}

- (NSString *)getStringFromAddressData:(NSData *)dataIn {
	//Function to parse address from NSData
	struct sockaddr_in	*socketAddress = nil;
	NSMutableString			   *ipString = nil;
	
	socketAddress = (struct sockaddr_in *)[dataIn bytes];
	ipString = [NSMutableString stringWithFormat: @"%s",
				inet_ntoa(socketAddress->sin_addr)];  ///problem here
	[ipString appendString:@":"];
	int port = ntohs(socketAddress->sin_port);
	[ipString appendFormat:@"%d", port];
	return ipString;
}

// Sent when a service disappears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing
{
	[self.services removeObject:aNetService];
}


- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	//delegate of NSNetService resolution process
	if (sender.addresses.count > 0) {
		[self.tableViewController addServerInfoFromAddressData:[sender.addresses objectAtIndex:0]];
	}
}

- (BOOL)application:(UIApplication *)application
			openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
		 annotation:(id)annotation
{
	if (self.pluginManager) {
		[self.pluginManager handleOpenURL:url  sourceApplication:sourceApplication];
	}

	return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
	// Dump JS garbage and sound effects immediately
	[[js_core lastJS] performSelectorOnMainThread:@selector(performGC) withObject:nil waitUntilDone:NO];
	[[SoundManager get] clearEffects];

	// Allow texture manager to react to a low memory warning as it deems appropriate
	texture_manager_memory_warning(texture_manager_get());

}

- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken
{
    [self.pluginManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken application:app];
}

- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error
{
	NSLOG(@"{notifications} Push notification registration failed: %@", error);

	[self.pluginManager didFailToRegisterForRemoteNotificationsWithError:error application:app];
}

- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	[self.pluginManager didReceiveRemoteNotification:userInfo application:app];
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notification
{
	[self.pluginManager didReceiveLocalNotification:notification application:app];
}


//// Splash Screen

- (void) updateScreenProperties {
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	// Detect iPad portrait mode
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

	if (orientation == UIDeviceOrientationUnknown) {
		NSLog(@"{core} WARNING: Device orientation unknown");

		orientation = self.tealeafViewController.interfaceOrientation;
	}

	bool portraitMode = (orientation == UIDeviceOrientationFaceUp ||
						 orientation == UIDeviceOrientationPortrait ||
						 orientation == UIDeviceOrientationPortraitUpsideDown);

	if (!self.gameSupportsPortrait) {
		self.screenPortraitMode = NO;
	} else {
		self.screenPortraitMode = portraitMode ? YES : NO;
	}

	// Calculate screen dimensions
	CGRect frame = [self.window frame];

	float scale = 1.0;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		scale = [[UIScreen mainScreen] scale];
	}

	int w, h;
	w = frame.size.width;
	h = frame.size.height;

	bool swap = false;

	if (!self.gameSupportsPortrait) {
		if (h > w) {
			swap = true;
		}
	}

	if (!self.gameSupportsLandscape) {
		if (w > h) {
			swap = true;
		}
	}
	
	// Swap orientation if needed
	if (swap) {
		int t = w;
		w = h;
		h = t;
	}
	
	self.initFrame = CGRectMake(0, 0, w, h);
	w = (int)(w * scale + 0.5f);
	h = (int)(h * scale + 0.5f);
	self.screenFrame = CGRectMake(0, 0, w, h);

	// Determine longer side
	int longerScreenSide = w;
	if (h > longerScreenSide) {
		longerScreenSide = h;
	}
	
	// Store dimensions
	self.screenWidthPixels = w;
	self.screenHeightPixels = h;
	self.screenLongerSide = longerScreenSide;
	self.screenBestSplash = [self findBestSplash];

	NSLog(@"{core} Device screen (%d, %d), portrait=%d, using splash '%@'", w, h, (int)self.screenPortraitMode, self.screenBestSplash);
}

enum Splashes {
	SPLASH_PORTRAIT_480,
	SPLASH_PORTRAIT_960,
	SPLASH_PORTRAIT_1024,
	SPLASH_PORTRAIT_1136,
	SPLASH_PORTRAIT_2048,
	SPLASH_LANDSCAPE_768,
	SPLASH_LANDSCAPE_1536,
};

SplashDescriptor SPLASHES[] = {
	{"portrait480", "@root://Default.png"},
	{"portrait960", "@root://Default@2x.png"},
	{"portrait1024", "@root://Default-Portrait~ipad.png"},
	{"portrait1136", "@root://Default-568h@2x.png"},
	{"portrait2048", "@root://Default-Portrait@2x~ipad.png"},
	{"landscape768", "@root://Default-Landscape~ipad.png"},
	{"landscape1536", "@root://Default-Landscape@2x~ipad.png"}
};

- (SplashDescriptor *) findBestSplashDescriptor {
	// Determine longer side
	const int longerScreenSide = self.screenLongerSide;
	SplashDescriptor *splash = &SPLASHES[SPLASH_PORTRAIT_480];
	
	// If on iPad,
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		// If portrait mode,
		if (self.screenPortraitMode) {
			if (longerScreenSide >= 2048) {
				splash = &SPLASHES[SPLASH_PORTRAIT_2048];
			} else {
				splash = &SPLASHES[SPLASH_PORTRAIT_1024];
			}
		} else { // Landscape:
			if (longerScreenSide >= 2048) {
				splash = &SPLASHES[SPLASH_LANDSCAPE_1536];
			} else {
				splash = &SPLASHES[SPLASH_LANDSCAPE_768];
			}
		}
	} else { // iPhone:
		if (longerScreenSide >= 1136) {
			splash = &SPLASHES[SPLASH_PORTRAIT_1136];
		} else if (longerScreenSide >= 960) {
			splash = &SPLASHES[SPLASH_PORTRAIT_960];
		} else {
			splash = &SPLASHES[SPLASH_PORTRAIT_480];
		}
	}
	return splash;
}

- (NSString *) findBestSplash {

	SplashDescriptor *splash = [self findBestSplashDescriptor];	

	NSString *splashResource = [NSString stringWithUTF8String:splash->resource];

	if (self.testAppManifest) {
		splashResource = @"loading.png";
	}

	return splashResource;
}

+ (void)initPluginMode {
	NSLog(@"{tealeaf} Initializing in plugin mode");
}

@end
