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

#import "TeaLeafAppDelegate.h"

@class TeaLeafAppDelegate;


// Required and optional methods to implement
@protocol GCPluginProtocol
@required
- (void) initializeWithManifest: (NSDictionary *) manifest appDelegate:(TeaLeafAppDelegate *) appDelegate;
- (void) sendEvent: (NSString *) eventName jsonObject:(NSDictionary *) jsonObject;
@optional
- (void) didFailToRegisterForRemoteNotificationsWithError: (NSError *) error application: (UIApplication *) app;
- (void) didReceiveRemoteNotification:(NSDictionary *) userInfo application: (UIApplication *) app;
- (void) didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken application: (UIApplication *) app;
- (void) didReceiveLocalNotification:(UILocalNotification *)notification application: (UIApplication *) app;
- (void) applicationDidBecomeActive: (UIApplication *) app;
- (void) applicationWillTerminate: (UIApplication *) app;
- (void) handleOpenURL: (NSURL *) url;
@end


@interface PluginManager : NSObject<GCPluginProtocol>
@property (nonatomic, retain) NSMutableArray *plugins;

- (void) postNotification:(NSString *)selector obj1:(id)obj1 obj2:(id)obj2;
@end


// Derive from this object to receive notification events
@interface GCPlugin : NSObject<GCPluginProtocol>
- (void) onPluginNotification:(NSNotification *) notification;
@end


//START_PLUGIN_CODE

// Your plugin header code will be injected here.

// Here's an example plugin that will be replaced with yours:

#import <CoreLocation/CoreLocation.h>

@interface MyPlugin : GCPlugin
@end

//END_PLUGIN_CODE
