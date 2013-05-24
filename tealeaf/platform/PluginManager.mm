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
#include <objc/runtime.h>
#include <stdlib.h>

@implementation PluginManager

- (void) dealloc {
	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}

	Class *classes = 0;
	int numClasses = objc_getClassList(0, 0);
	if (numClasses > 0 ) {
		classes = (Class *)malloc(sizeof(Class) * numClasses);

		numClasses = objc_getClassList(classes, numClasses);
		for (int index = 0; index < numClasses; index++) {
			Class nextClass = classes[index];

			if (class_conformsToProtocol(nextClass, @protocol(GCPluginProtocol))) {
				// TODO: Instantiate here, and check if it's PluginManager
			}
		}
		free(classes);
	}

	return self;
}

- (void) postNotification:(NSString *)selector obj1:(id)obj1 obj2:(id)obj2 {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  selector,@"selector",
						  obj1,@"obj1",
						  obj2,@"obj2",
						  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GameClosurePlugin" object:self userInfo:dict];
}

- (void) initializeWithManifest: (NSDictionary *) manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	[self postNotification:@"initializeWithManifest" obj1:manifest obj2:appDelegate];
}

- (void) sendEvent: (NSString *) eventName jsonString:(NSString *) jsonString {
	[self postNotification:@"sendEvent" obj1:eventName obj2:jsonString];
}

- (void) didFailToRegisterForRemoteNotificationsWithError: (NSError *) error application: (UIApplication *) app {
	[self postNotification:@"didFailToRegisterForRemoteNotificationsWithError" obj1:error obj2:app];
}

- (void) didReceiveRemoteNotification:(NSDictionary *) userInfo application: (UIApplication *) app {
	[self postNotification:@"didReceiveRemoteNotification" obj1:userInfo obj2:app];
}
- (void) didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken application: (UIApplication *) app {
	[self postNotification:@"didRegisterForRemoteNotificationsWithDeviceToken" obj1:deviceToken obj2:app];
}

- (void) didReceiveLocalNotification:(UILocalNotification *)notification application:(UIApplication *)app {
	[self postNotification:@"didReceiveLocalNotification" obj1:notification obj2:app];
}

- (void)applicationDidBecomeActive:(UIApplication *)app {
	[self postNotification:@"applicationDidBecomeActive" obj1:app obj2:nil];
}

- (void)applicationWillTerminate:(UIApplication *)app {
	[self postNotification:@"applicationWillTerminate" obj1:app obj2:nil];
}

- (void) handleOpenURL:(NSURL* )url {
	[self postNotification:@"handleOpenURL" obj1:url obj2:nil];
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

static const char *MyPlugins[] = {
	"MyPlugin",
	0
};

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

- (void) initializeWithManifest: (NSDictionary *) manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	NSLog(@"CAT: initializeWithManifest called! %@", [manifest debugDescription]);
}

- (void) sendEvent: (NSString *) eventName jsonString:(NSString *) jsonString {
	NSLog(@"CAT: sendEvent called! %@ %@", eventName, jsonString);
}

@end

//END_PLUGIN_CODE
