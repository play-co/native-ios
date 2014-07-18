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

#import "TeaLeafAppDelegate.h"
#import "js/js_core.h"

@class TeaLeafAppDelegate;


@interface jsPluginManager : NSObject
+ (void) addToRuntime:(js_core *)js;
+ (void) onDestroyRuntime;
@end


// Required and optional methods to implement
@protocol GCPluginProtocol
@required
- (void) initializeWithManifest:(NSDictionary *)manifest appDelegate:(TeaLeafAppDelegate *)appDelegate;
@optional
- (void) didFailToRegisterForRemoteNotificationsWithError:(NSError *)error application:(UIApplication *)app;
- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo application:(UIApplication *)app;
- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken application:(UIApplication *)app;
- (void) didReceiveLocalNotification:(UILocalNotification *)notification application:(UIApplication *)app;
- (void) applicationDidBecomeActive:(UIApplication *)app;
- (void) applicationWillTerminate:(UIApplication *)app;
- (void) handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;
- (void) onPause;
- (void) onResume;
@end


@interface PluginManager : NSObject<GCPluginProtocol>
@property (nonatomic, retain) NSMutableDictionary *plugins;

- (void) postNotification:(NSString *)selector obj1:(id)obj1 obj2:(id)obj2;
- (void) dispatchEvent:(NSString *)name forPlugin:(id)plugin withData:(NSDictionary *)data;
- (void) dispatchEvent:(NSString *)name forPluginName:(NSString *)pluginName withData:(NSDictionary *)data;
- (void) dispatchJSEvent:(NSDictionary *)evt;
- (void) dispatchJSEventWithJSONString: (NSString*) str andRequestId:(NSNumber *)requestId;
- (void) dispatchJSResponse:(NSDictionary *)response withError:(id)error andRequestId:(NSNumber *)requestId;

- (id) plugin:(NSString *)plugin name:(NSString *)name event:(NSDictionary *)event;
- (void) plugin:(NSString *)plugin name:(NSString *)name event:(NSDictionary *)event id:(NSNumber *)requestId;

+ (PluginManager *) get;
@end


// Derive from this object to receive notification events
@interface GCPlugin : NSObject<GCPluginProtocol>
- (void) onPluginNotification:(NSNotification *) notification;
@end
