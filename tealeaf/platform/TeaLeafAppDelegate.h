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
 * along with the Game Closure SDK.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <UIKit/UIKit.h>
#import "TeaLeafViewController.h"
#import "ServerTableViewController.h"
#import "AppTableViewController.h"
#import "PluginManager.h"
#import "PaymentObserver.h"
#import "js_core.h"
#import "OpenGLView.h"
#import "Reachability.h"

@interface TeaLeafAppDelegate : NSObject <UIApplicationDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) NSMutableDictionary *config;         // Configuration config.plist file dictionary
@property (nonatomic, retain) js_core *js;
@property (nonatomic, retain) OpenGLView *canvas;
@property (nonatomic) BOOL isOnline;                        // Indicates that upon the previous notice, that the internet was reachable
@property (nonatomic) BOOL wasPaused;                       // Indicates that upon the previous notice, that the app was paused
@property (nonatomic) BOOL tealeafShowing;
//@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, retain) TeaLeafViewController *tealeafViewController;
@property (nonatomic, retain) ServerTableViewController *tableViewController;
@property (nonatomic, retain) AppTableViewController *appTableViewController;
@property (nonatomic, retain) PluginManager *pluginManager;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, retain) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic, strong) NSNotification *launchNotification;
- (void) setJSReady:(bool)isReady;
- (BOOL) getJSReady;

// Initialize the reachability callback
- (void) initializeOnlineState;
- (void) hookOnlineState;
- (BOOL) getNetworkStatus: (Reachability*) reach;
- (void) updateNetworkStatus: (Reachability*) reach;

// Callback for network status changes
- (void) reachabilityChanged: (NSNotification*) notice;

// Called when JavaScript engine is ready from another thread
- (void) onJSReady;

// JavaScript event generators
- (void) postNetworkStatusEvent: (BOOL) isOnline;
- (void) postPauseEvent: (BOOL) isPaused;

- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *) userInfo;
- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;


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

@end
