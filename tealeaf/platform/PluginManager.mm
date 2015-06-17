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
#import "platform/log.h"
#include "core.h"
#include "events.h"
#include "core/events.h"
#include <Foundation/NSNotification.h>
#include <objc/runtime.h>
#include <stdlib.h>

static js_core *m_core = nil;
static PluginManager *m_pluginManager = nil;


JSAG_MEMBER_BEGIN(sendEvent, 3)
{
	JSAG_ARG_NSTR(pluginName);
	JSAG_ARG_NSTR(eventName);
	JSAG_ARG_NSTR(str);
	
	NSError *err = nil;
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                           options:0
                                             error:&err];

    
	if (!json || err) {
		NSLOG(@"{plugins} WARNING: Event passed to NATIVE.plugins.sendEvent does not contain a valid JSON string.");
	} else {
		id returnValue = [m_pluginManager plugin:pluginName name:eventName event:json];
        if ([returnValue isKindOfClass: [NSDictionary class]]) {
            NSData* data = [NSJSONSerialization dataWithJSONObject:returnValue options:0 error:nil];
            NSString *returnValueString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            JSAG_RETURN_NSTR(returnValueString);
        } else {
            JSAG_RETURN_NSTR((NSString *) returnValue);
        }
	}
}
JSAG_MEMBER_END


JSAG_MEMBER_BEGIN(_sendRequest, 3)
{
	JSAG_ARG_NSTR(pluginName);
	JSAG_ARG_NSTR(eventName);
	JSAG_ARG_NSTR(str);
    JSAG_ARG_INT32(id);
	
	NSError *err = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&err];
	if (!json || err) {
		NSLOG(@"{plugins} WARNING: Event passed to NATIVE.plugins.sendRequest does not contain a valid JSON string.");
	} else {
		[m_pluginManager plugin:pluginName name:eventName event:json id:[NSNumber numberWithInt:id]];
	}
    
    JSAG_RETURN_VOID;
}
JSAG_MEMBER_END

JSAG_OBJECT_START(plugins)
JSAG_OBJECT_MEMBER(sendEvent)
JSAG_OBJECT_MEMBER(_sendRequest)
JSAG_OBJECT_END


@implementation jsPluginManager

+ (void) addToRuntime:(js_core *)js {
	m_core = js;
    
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
					
					NSLOG(@"{plugins} Instantiated %s", className);
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

- (void) dispatchJSEventWithJSONString: (NSString*) str andRequestId:(NSNumber *)requestId {
    if (m_core) {
        JSContext *cx = m_core.cx;
		dispatch_async(dispatch_get_main_queue(), ^{
            if (m_core) {
                JSAutoRequest areq(cx);
                JS::RootedValue evt_val(cx, NSTR_TO_JSVAL(cx, str));
                [m_core dispatchEvent:evt_val withRequestId:[requestId intValue]];
            }
        });
    } else {
            NSLOG(@"WARNING: Plugin attempted to dispatch a JS event before the JS subsystem was created");
    }
}

- (void) dispatchEvent:(NSString *)name forPlugin:(id)plugin withData:(NSDictionary *)data {
    [self dispatchJSEvent: [NSDictionary dictionaryWithObjectsAndKeys:
                            @"pluginEvent",@"name",
                            NSStringFromClass([plugin class]),@"pluginName",
                            name,@"eventName",
                            data,@"data",
                            nil]];
}

- (void) dispatchEvent:(NSString *)name forPluginName:(NSString *)pluginName withData:(NSDictionary *)data {
    [self dispatchJSEvent: [NSDictionary dictionaryWithObjectsAndKeys:
                            @"pluginEvent",@"name",
                            pluginName,@"pluginName",
                            name,@"eventName",
                            data,@"data",
                            nil]];
}

- (void) dispatchJSEvent:(NSDictionary *)evt {
    [self dispatchJSEvent:evt withRequestId:0];
}

- (void) dispatchJSEvent:(NSDictionary *)evt withRequestId:(NSNumber *)requestId {
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:evt options:0 error:&error];
    NSString *evt_nstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self dispatchJSEventWithJSONString:evt_nstr andRequestId:requestId];
}

- (void) dispatchJSResponse:(NSDictionary *)response withError:(id)error andRequestId:(NSNumber *)requestId {
    if ([error isKindOfClass:[NSError class]]) {
        error = ((NSError *)error).localizedDescription;
    }
    
    [self dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"plugins",@"name",
                           error ? error : [NSNumber numberWithBool:false],@"error",
                           (response != nil ? response : [NSNull null]),@"response",
                           nil]
            withRequestId: requestId];
}

- (void) plugin:(NSString *)plugin name:(NSString *)name event:(NSDictionary *)event id:(NSNumber *)requestId {
    @try {
		id instance = [self.plugins valueForKey:plugin];
		if (instance) {
			SEL selector = NSSelectorFromString([name stringByAppendingString:@":withRequestId:"]);
			if ([instance respondsToSelector:selector]) {
				[instance performSelector:selector withObject:event withObject:requestId];
			} else {
                NSLOG(@"{plugins} WARNING: Event could not be delivered for plugin %@ : %@", plugin, name);
            }
		}
	}
	@catch (NSException *e) {
		NSLOG(@"{plugins} WARNING: Event could not be delivered for plugin %@ : %@ (Exception: %@)", plugin, name, e);
	}
}

- (NSDictionary *) plugin:(NSString *)plugin name:(NSString *)name event:(NSDictionary *)event {
	id returnValue = nil;

	@try {
		id instance = [self.plugins valueForKey:plugin];
		if (instance) {
			SEL selector = NSSelectorFromString([name stringByAppendingString:@":"]);
			SEL selectorWithReturnValue = NSSelectorFromString([name stringByAppendingString:@"WithReturnValue:"]);
			if ([instance respondsToSelector:selector]) {
				[instance performSelector:selector withObject:event];
			} else if ([instance respondsToSelector:selectorWithReturnValue]) {
				returnValue = [instance performSelector:selectorWithReturnValue withObject:event];
			}
		} else {
			NSLOG(@"{plugins} WARNING: Event could not be delivered for plugin %@ : %@", plugin, name);
		}

		if (![returnValue isKindOfClass:[NSDictionary class]] && ![returnValue isKindOfClass:[NSString class]]) {
			returnValue = nil;
		}
	}
	@catch (NSException *e) {
		NSLOG(@"{plugins} WARNING: Event could not be delivered for plugin %@ : %@ (Exception: %@)", plugin, name, e);
	}

    return returnValue;
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
