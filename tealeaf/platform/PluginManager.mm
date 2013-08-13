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

#import "PluginManager.h"
#include "jsonUtil.h"
#import <deps/JSONKit.h>
#import "platform/log.h"
#include "core.h"
#include "events.h"
#include "core/events.h"
#include <Foundation/NSNotification.h>
#include <objc/runtime.h>
#include <stdlib.h>

static js_core *m_core = nil;
static JSONDecoder *m_decoder = nil;
static PluginManager *m_pluginManager = nil;


JSAG_MEMBER_BEGIN(sendEvent, 3)
{
	JSAG_ARG_NSTR(pluginName);
	JSAG_ARG_NSTR(eventName);
	JSAG_ARG_CSTR(str);
	
	NSError *err = nil;
	NSDictionary *json = [m_decoder objectWithUTF8String:(const unsigned char *)str length:(NSUInteger)str_len error:&err];
	
	if (!json || err) {
		NSLOG(@"{plugins} WARNING: Event passed to NATIVE.plugins.sendEvent does not contain a valid JSON string.");
	} else {
		[m_pluginManager plugin:pluginName name:eventName event:json];
	}
}
JSAG_MEMBER_END


JSAG_OBJECT_START(plugins)
JSAG_OBJECT_MEMBER(sendEvent)
JSAG_OBJECT_END


@implementation jsPluginManager

+ (void) addToRuntime:(js_core *)js {
	m_core = js;
	
	m_decoder = [[JSONDecoder decoderWithParseOptions:JKParseOptionStrict] retain];
	
	JSAG_OBJECT_ATTACH(js.cx, js.native, plugins);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end


@implementation PluginManager

+ (PluginManager *) get {
	return m_pluginManager;
}

- (void) dealloc {
	self.plugins = nil;
	
	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	m_pluginManager = self;
	
	self.plugins = [NSMutableDictionary dictionary];
	
	Class *classes = 0;
	int numClasses = objc_getClassList(0, 0);
	if (numClasses > 0 ) {
		classes = (Class *)malloc(sizeof(Class) * numClasses);
		
		numClasses = objc_getClassList(classes, numClasses);
		for (int index = 0; index < numClasses; index++) {
			Class nextClass = classes[index];
			Class superClass = class_getSuperclass(nextClass);
			const char *superClassName = class_getName(superClass);
			
			if (superClassName && strcmp(superClassName, "GCPlugin") == 0) {
				const char *className = class_getName(nextClass);
				
				id pluginInstance = [[[objc_lookUpClass(className) alloc] init] autorelease];
				
				if (pluginInstance) {
					NSString *key = [NSString stringWithUTF8String:className];
					
					[self.plugins setObject:pluginInstance forKey:key];
					
					NSLog(@"{plugins} Instantiated %s", className);
				}
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

- (void) initializeWithManifest:(NSDictionary *)manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	[self postNotification:@"initializeWithManifest:appDelegate:" obj1:manifest obj2:appDelegate];
}

- (void) didFailToRegisterForRemoteNotificationsWithError:(NSError *)error application:(UIApplication *)app {
	[self postNotification:@"didFailToRegisterForRemoteNotificationsWithError:application:" obj1:error obj2:app];
}

- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo application:(UIApplication *)app {
	[self postNotification:@"didReceiveRemoteNotification:application:" obj1:userInfo obj2:app];
}
- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken application:(UIApplication *)app {
	[self postNotification:@"didRegisterForRemoteNotificationsWithDeviceToken:application:" obj1:deviceToken obj2:app];
}

- (void) didReceiveLocalNotification:(UILocalNotification *)notification application:(UIApplication *)app {
	[self postNotification:@"didReceiveLocalNotification:application:" obj1:notification obj2:app];
}

- (void)applicationDidBecomeActive:(UIApplication *)app {
	[self postNotification:@"applicationDidBecomeActive:" obj1:app obj2:nil];
}

- (void)applicationWillTerminate:(UIApplication *)app {
	[self postNotification:@"applicationWillTerminate:" obj1:app obj2:nil];
}

- (void) handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
	[self postNotification:@"handleOpenURL:sourceApplication:" obj1:url obj2:sourceApplication];
}

- (void) onPause {
	[self postNotification:@"onPause" obj1:nil obj2:nil];
}

- (void) onResume {
	[self postNotification:@"onResume" obj1:nil obj2:nil];
}

- (void) dispatchJSEvent:(NSDictionary *)evt {
	if (m_core) {
		// Run JS synchronously in the main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			// Check again in case the JS subsystem was destroyed in the meantime
			if (m_core) {
				JSContext *cx = m_core.cx;
				JS_BeginRequest(cx);
				
				NSString *evt_nstr = [evt JSONString];
				
				jsval evt_val = NSTR_TO_JSVAL(cx, evt_nstr);
				
				[m_core dispatchEvent:&evt_val count:1];
				
				JS_EndRequest(cx);
			}
		});
	} else {
		NSLOG(@"WARNING: Plugin attempted to dispatch a JS event before the JS subsystem was created");
	}
}

- (void) plugin:(NSString *)plugin name:(NSString *)name event:(NSDictionary *)event {
	id instance = [self.plugins valueForKey:plugin];
	if (instance) {
		SEL selector = NSSelectorFromString([name stringByAppendingString:@":"]);
		if ([instance respondsToSelector:selector]) {
			[instance performSelector:selector withObject:event];
		}
	} else {
		NSLOG(@"{plugins} WARNING: Event could not be delivered for plugin: %@", plugin);
	}
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

- (void) onPluginNotification:(NSNotification *)notification {
	if ([[notification name] isEqualToString:@"GameClosurePlugin"]) {
		//PluginManager *mgr = (PluginManager *)[notification object];
		NSDictionary *dict = [notification userInfo];
		
		if (dict) {
			NSString *selectorString = [dict objectForKey:@"selector"];
			
			if (selectorString) {
				SEL selector = NSSelectorFromString(selectorString);
				if ([self respondsToSelector:selector]) {
					id obj1 = [dict objectForKey:@"obj1"];
					id obj2 = [dict objectForKey:@"obj2"];
					
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
