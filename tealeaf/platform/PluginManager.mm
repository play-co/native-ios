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
	JSAG_ARG_NSTR(pluginName); // Unused
	JSAG_ARG_NSTR(eventName);
	JSAG_ARG_CSTR(str);
	
	NSError *err = nil;
	NSDictionary *json = [m_decoder objectWithUTF8String:(const unsigned char *)str length:(NSUInteger)str_len error:&err];
	
	if (!json || err) {
		NSLOG(@"{plugins} WARNING: Event passed to NATIVE.plugins.sendEvent does not contain a valid JSON string.");
	} else {
		[m_core.pluginManager sendEvent:eventName jsonObject:json];
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
	
}

@end


@implementation PluginManager

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
	
	self.plugins = [NSMutableArray array];
	
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
					[self.plugins addObject:pluginInstance];
					
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

- (void) initializeWithManifest: (NSDictionary *) manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	[self postNotification:@"initializeWithManifest:appDelegate:" obj1:manifest obj2:appDelegate];
}

- (void) sendEvent: (NSString *) eventName jsonObject:(NSDictionary*)jsonObject {
	[self postNotification:@"sendEvent:jsonObject:" obj1:eventName obj2:jsonObject];
}

- (void) didFailToRegisterForRemoteNotificationsWithError: (NSError *) error application: (UIApplication *) app {
	[self postNotification:@"didFailToRegisterForRemoteNotificationsWithError:application:" obj1:error obj2:app];
}

- (void) didReceiveRemoteNotification:(NSDictionary *) userInfo application: (UIApplication *) app {
	[self postNotification:@"didReceiveRemoteNotification:application:" obj1:userInfo obj2:app];
}
- (void) didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken application: (UIApplication *) app {
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

- (void) handleOpenURL:(NSURL* )url {
	[self postNotification:@"handleOpenURL:" obj1:url obj2:nil];
}

- (void) dispatchJSEvent:(NSDictionary *)evt {
	if (m_core) {
		JSContext *cx = m_core.cx;
		JS_BeginRequest(cx);
		
		NSString *evt_nstr = [evt JSONString];
		
		jsval evt_val = NSTR_TO_JSVAL(cx, evt_nstr);
		
		[m_core dispatchEvent:&evt_val count:1];
		
		JS_EndRequest(cx);
	} else {
		NSLOG(@"WARNING: Plugin attempted to dispatch a JS event before the JS subsystem was created");
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

- (void) onPluginNotification:(NSNotification *) notification {
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


//START_PLUGIN_CODE

// Your plugin source code will be injected here.

@implementation MyPlugin

// The plugin must call super dealloc.
- (void) dealloc {
	[super dealloc];
}

// The plugin must call super init.
- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}

	return self;
}

- (void) initializeWithManifest: (NSDictionary *) manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	NSLOG(@"{myplugin} Initialized with manifest");
}

- (void) sendEvent: (NSString *) eventName jsonObject:(NSDictionary *)jsonObject {
	@try {
		NSString *method = [jsonObject valueForKey:@"method"];
		
		if ([method isEqualToString:@"getRequestedData"]) {
			NSLOG(@"{myplugin} Got request");
		}
	}
	@catch (NSException *exception) {
		NSLOG(@"{myplugin} Exception while processing event: ", exception);
	}
}

@end

//END_PLUGIN_CODE
