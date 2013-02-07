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

#import "PluginManager.h"
#include "jsonUtil.h"
#import "JSONKit.h"
#import "platform/log.h"
#include "core.h"
#include "events.h"
#include "core/events.h"
//START_PLUGINS_IMPORTS
//END_PLUGINS_IMPORTS
@implementation PluginManager

- (id) init {
	self = [super init];
//START_init
//END_init
	return self; 
}

- (void)sendEvent:(NSString*) eventInfo isJS:(BOOL) isJS {
//START_sendEvent
//END_sendEvent
}

- (void) initializeUsingJSON:(NSDictionary *)json {
	if (!json) return;
//START_initializeUsingJSON
//END_initializeUsingJSON
}

- (void) application: (UIApplication *) app didFailToRegisterForRemoteNotificationsWithError: (NSError *) error {
//START_didFailToRegisterForRemoteNotificationsWithError
//END_didFailToRegisterForRemoteNotificationsWithError
}

- (void) application: (UIApplication *) app didReceiveRemoteNotification:(NSDictionary *) userInfo {
//START_didReceiveRemoteNotification
//END_didReceiveRemoteNotification
}
- (void) application: (UIApplication *) app didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken {
//START_didRegisterForRemoteNotificationsWithDeviceToken
//END_didRegisterForRemoteNotificationsWithDeviceToken
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
//START_didRegisterForRemoteNotificationsWithDeviceToken
//TODO: Implement full workflow
// For now, dont do anything. We dont present notifications if app is running in the foreground.
//END_didRegisterForRemoteNotificationsWithDeviceToken

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//START_applicationDidBecomeActive
//END_applicationDidBecomeActive
}

- (void)applicationWillTerminate:(UIApplication *)application {
//START_applicationWillTerminate
//END_applicationWillTerminate
}

- (void) handleOpenURL:(NSURL* )url {
//START_handleOpenURL
//END_handleOpenURL
}


- (void) dealloc {
//START_dealloc
//END_dealloc
}

//START_PLUGINS_FUNCS
//END_PLUGINS_FUNCS

@end
