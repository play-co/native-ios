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

//START_PLUGINS_IMPORTS
//END_PLUGINS_IMPORTS

@protocol PluginManagerDelegate <NSObject>
- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *) userInfo;
- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;
- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
- (void) handleOpenURL:(NSURL* )url;
- (void) initializeUsingJSON:(NSDictionary *)json;
@end

@interface PluginManager : NSObject  
//START_DEF_DELEGATES
//END_DEF_DELEGATES
{
//START_DECL_VARS
//END_DECL_VARS
}

//START_PLUGINS_FUNCS
//END_PLUGINS_FUNCS

- (void) sendEvent:(NSString*) eventInfo isJS:(BOOL) isJS;
- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *) userInfo;
- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;
- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;
- (void) initializeUsingJSON:(NSDictionary *)json;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
- (void) handleOpenURL:(NSURL* )url;

@end
