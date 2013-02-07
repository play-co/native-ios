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

	[super dealloc];
}


- (void) setJSReady:(bool) isReady
{
	js_ready = isReady;
}

- (BOOL) getJSReady {
	return js_ready;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *) options
{
	
	//SEARCH FOR NETWORKS
	self.services = [NSMutableArray array];
	self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[self.serviceBrowser setDelegate:self];
	[self.serviceBrowser searchForServicesOfType:@"_tealeaf._tcp" inDomain:@"local."];
	self.tealeafShowing = NO;
	self.launchNotification = [options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	self.wasPaused = NO;
	[self performSelectorInBackground:@selector(reportAppOpenToAdMob) withObject:nil];
	UIApplication *app = [UIApplication sharedApplication];
	[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	[self.window makeKeyAndVisible];

	  
	
	//TEALEAF_SPECIFIC_START
	
	self.tealeafViewController = [[TeaLeafViewController alloc] init];
	
	NSString *path = [[NSBundle mainBundle] resourcePath];
	NSString *finalPath = [path stringByAppendingPathComponent:@"config.plist"];
	self.config = [NSMutableDictionary dictionaryWithContentsOfFile:finalPath];
	//log config 
	 
	for (id key in self.config) {
		NSLOG(@"{tealeaf} Config[%@] = %@", key, [self.config objectForKey:key]);
	}

	//TEALEAF_SPECIFIC_END
	
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
		[self.pluginManager handleOpenURL:url];
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
	//sendToken(self.js, deviceToken);
	[self.pluginManager	 application:app didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error
{
	NSLOG(@"Push notification registration failed: %@", error);
	// TODO later: reschedule activating push notifications
	[self.pluginManager	 application:app didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	//TODO: Implement full workflow
	[self.pluginManager	 application:app didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	//TODO: Implement full workflow
	// For now, dont do anything. We dont present notifications if app is running in the foreground.
}


/***********************
* Admob stuff
**********************/

- (NSString *)hashedISU {
	NSString *result = nil;
	NSString *isu = [UIDevice currentDevice].uniqueIdentifier;

	if(isu) {
		unsigned char digest[16];
		NSData *data = [isu dataUsingEncoding:NSASCIIStringEncoding];
		CC_MD5([data bytes], [data length], digest);

		result = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		digest[0], digest[1],
		digest[2], digest[3],
		digest[4], digest[5],
		digest[6], digest[7],
		digest[8], digest[9],
		digest[10], digest[11],
		digest[12], digest[13],
		digest[14], digest[15]];
		result = [result uppercaseString];
	}
	return result;
}

- (void)reportAppOpenToAdMob {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
	// Have we already reported an app open?
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
	NSUserDomainMask, YES) objectAtIndex:0];
	NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"admob_app_open"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:appOpenPath]) {
		// Not yet reported -- report now
		NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://a.admob.com/f0?isu=%@&md5=1&app_id=%@", [self hashedISU], @"462152931"];
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
		NSURLResponse *response;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0)) {
			[fileManager createFileAtPath:appOpenPath contents:nil attributes:nil]; // successful report, mark it as such
		}
	}
	[pool release];
							   
}
@end
