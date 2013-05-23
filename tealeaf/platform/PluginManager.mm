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
#include <Foundation/NSNotification.h>


@implementation PluginManager

- (void) dealloc {
	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	return self;
}

- (void) initializeUsingJSON:(NSDictionary *)json appDelegate:(TeaLeafAppDelegate *)appDelegate {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"initializeUsingJSON",@"selector",
						  json,@"obj1",
						  appDelegate,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) sendEventForPlugin:(NSString *) eventName jsonString:(NSString *) jsonString {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"sendEventForPlugin",@"selector",
						  eventName,@"obj1",
						  jsonString,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) didFailToRegisterForRemoteNotificationsWithError: (NSError *) error application: (UIApplication *) app {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"didFailToRegisterForRemoteNotificationsWithError",@"selector",
						  error,@"obj1",
						  app,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) didReceiveRemoteNotification:(NSDictionary *) userInfo application: (UIApplication *) app {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"didReceiveRemoteNotification",@"selector",
						  userInfo,@"obj1",
						  app,@"obj2",
						  nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}
- (void) didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken application: (UIApplication *) app {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"didRegisterForRemoteNotificationsWithDeviceToken",@"selector",
						  deviceToken,@"obj1",
						  app,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) didReceiveLocalNotification:(UILocalNotification *)notification application:(UIApplication *)app {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"didReceiveLocalNotification",@"selector",
						  notification,@"obj1",
						  app,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"applicationDidBecomeActive",@"selector",
						  application,@"obj1",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"applicationWillTerminate",@"selector",
						  application,@"obj1",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) handleOpenURL:(NSURL* )url {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"handleOpenURL",@"selector",
						  url,@"obj1",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

@end


// Note: Intentional incomplete implementation
@implementation GCPlugin

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onPluginNotification:)
												 name:@"GameClosurePlugin"
											   object:nil];
	
	return self;
}

- (void) onPluginNotification:(NSNotification *) notification {
	NSLog(@"CAT: Got notification %@", [notification name]);
	
	if ([[notification name] isEqualToString:@"GameClosurePlugin"]) {
		PluginManager *mgr = (PluginManager *)[notification object];
		NSDictionary *dict = [notification userInfo];
		if (!!dict && !!mgr) {
			NSString *selectorString = [dict objectForKey:@"selector"];
			
			if (!!selectorString) {
				SEL selector = NSSelectorFromString(selectorString);
				if ([self respondsToSelector:selector]) {
					id obj1 = [dict objectForKey:@"obj1"];
					id obj2 = [dict objectForKey:@"obj2"];
					
					NSLog(@"CAT: Delivering %@", selectorString);
					
					if (!obj1) {
						[self performSelector:selector];
					} else {
						if (!obj2) {
							[self performSelector:selector withObject:obj1];
						} else {
							[self performSelector:selector withObject:obj1 withObject:obj2];
						}
					}
				}
			}
		}
	}
}

@end


//START_PLUGIN_CODE

// Your plugin source code will be injected here.

@implementation MyPlugin

// The plugin must call super init.
- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	return self;
}

// The plugin must call super dealloc.
- (void) dealloc {
	[super dealloc];
}

- (void) initializeUsingJSON: (NSDictionary *) json appDelegate:(TeaLeafAppDelegate *)appDelegate {
	NSLog(@"CAT: initializeUsingJSON called! %@", [json debugDescription]);
}

- (void) sendEventForPlugin: (NSString *) eventName jsonString:(NSString *) jsonString {
	NSLog(@"CAT: sendEventForPlugin called! %@ %@", eventName, jsonString);
}

@end

//END_PLUGIN_CODE
