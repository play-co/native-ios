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
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import <UIKit/UIKit.h>
#import "TeaLeafViewController.h"
#ifndef DISABLE_TESTAPP
#import "ServerTableViewController.h"
#import "AppTableViewController.h"
#endif
#import "PluginManager.h"
#import "js_core.h"
#import "OpenGLView.h"
#import "Reachability.h"

// Splash Screen Descriptor
struct SplashDescriptor {
	const char *key;		// Manifest.json key name under "splash" section
	const char *resource;	// Local resource name used by Xcode
};


@interface TeaLeafAppDelegate : NSObject <UIApplicationDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic) BOOL debugModeBuild;					// Set to true if --debug flag was used during building
@property (nonatomic) BOOL isTestApp;						// Is in test-app mode?
@property (nonatomic, retain) NSMutableDictionary *config;	// Configuration config.plist file dictionary
@property (nonatomic, retain) js_core *js;
@property (nonatomic, retain) OpenGLView *canvas;
@property (nonatomic) BOOL isOnline;                        // Indicates that upon the previous notice, that the internet was reachable
@property (nonatomic) BOOL wasPaused;                       // Indicates that upon the previous notice, that the app was paused
@property (nonatomic) BOOL tealeafShowing;
@property (nonatomic) BOOL signalRestart;
@property (nonatomic, retain) TeaLeafViewController *tealeafViewController;
#ifndef DISABLE_TESTAPP
@property (nonatomic, retain) ServerTableViewController *tableViewController;
@property (nonatomic, retain) AppTableViewController *appTableViewController;
#endif
@property (nonatomic, retain) PluginManager *pluginManager;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, retain) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic, strong) UILocalNotification *launchNotification;
@property (nonatomic, retain) NSDictionary *appManifest;
@property (nonatomic, retain) NSDictionary *startOptions;

// Test app
@property (nonatomic, retain) NSDictionary *testAppManifest;

// Game orientation
@property (nonatomic) BOOL gameSupportsPortrait;
@property (nonatomic) BOOL gameSupportsLandscape;

- (void) selectOrientation;

// Splash screen properties
@property (nonatomic) int screenWidthPixels;
@property (nonatomic) int screenHeightPixels;
@property (nonatomic) CGRect screenFrame; // This may be scaled by 2, but these are the coordinates the Canvas cares about
@property (nonatomic) CGRect initFrame; // This may be scaled by 2, but these are the coordinates the Canvas cares about
@property (nonatomic) int screenLongerSide;
@property (nonatomic) BOOL screenPortraitMode;
@property (nonatomic) BOOL ignoreMemoryWarnings;
@property (nonatomic, retain) NSString *screenBestSplash;

// Online state
- (void) initializeOnlineState;
- (void) hookOnlineState;
- (BOOL) getNetworkStatus: (Reachability*) reach;
- (void) updateNetworkStatus: (Reachability*) reach;

// Update the screen properties
- (void) updateScreenProperties;
- (NSString *) findBestSplash; // Called automatically by updateScreenProperties
- (SplashDescriptor *) findBestSplashDescriptor;

// Callback for network status changes
- (void) reachabilityChanged: (NSNotification*) notice;

// Called when JavaScript engine is ready from another thread
- (void) setJSReady:(bool)isReady;
- (BOOL) getJSReady;
- (void) restartJS;

// JavaScript event generators
- (void) postNetworkStatusEvent: (BOOL) isOnline;
- (void) postPauseEvent: (BOOL) isPaused;

// Notifications
- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *) userInfo;
- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;

#ifndef DISABLE_TESTAPP
// NSNetServiceBrowser delegate methods for service browsing
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing;
#endif

- (void) sleepJS;
- (void) wakeJS;

@end

