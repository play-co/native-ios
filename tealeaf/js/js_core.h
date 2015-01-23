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

#ifndef JS_CORE_H
#define JS_CORE_H

#include "core/util/detect.h"
#include "platform/log.h"
#include "jsapi.h"
#include "jsMacros.h"


#define JS_CORE_NUM(x) #x
#define JS_CORE_NAME(line, v) (__FILE__ ":" JS_CORE_NUM(line) " -> " #v)
#define JS_AddValueRoot(cx,vp) JS_AddNamedValueRoot((cx), (vp), JS_CORE_NAME(__LINE__, vp))
#define JS_AddStringRoot(cx,vp) JS_AddNamedStringRoot((cx), (vp), JS_CORE_NAME(__LINE__, vp))
#define JS_AddObjectRoot(cx,vp) JS_AddNamedObjectRoot((cx), (vp), JS_CORE_NAME(__LINE__, vp))
#define JS_AddGCThingRoot(cx,vp) JS_AddNamedGCThingRoot((cx), (vp), JS_CORE_NAME(__LINE__, vp))


CEXPORT JSContext *get_js_context();
CEXPORT JSObject *get_global_object();


#if (__OBJC__) == 1

#import <Foundation/Foundation.h>

@class PluginManager;

#ifndef DISABLE_DEBUG_SERVER
#import "debug/DebugServer.h"
@class DebugServer;
#endif

@interface js_core : NSObject

@property (nonatomic, retain) NSMutableArray *extensions;
@property (nonatomic, retain) NSDictionary *privateStore;
@property (nonatomic, retain) PluginManager *pluginManager;
@property (nonatomic, retain) NSDictionary *config;
#ifndef DISABLE_DEBUG_SERVER
@property (nonatomic, assign) DebugServer *debugServer; // Store assigned to force synchronous shutdown
#endif
@property (nonatomic) JSRuntime *rt;
@property (nonatomic) JSContext *cx;
@property (nonatomic) JSObject *global;
@property (nonatomic) JSCompartment *globalCompartment;
@property (nonatomic) JSObject *native;

// Call this first from the main thread to initialize the runtime thread info
- (id) initRuntime;

- (void) shutdown;

// Then call this from another thread to parallelize the initialization code
- (id) setConfig:(NSDictionary*)config  pluginManager:(PluginManager*)pluginManager;

-(jsval) eval: (char *) source;
-(jsval) evalStr: (NSString *) source;
-(jsval) evalStr: (NSString *) source withPath: (NSString *) path;

-(void) addExtension: (id) extension;


-(void) dispatchEvent:(JS::HandleValue)arg;
-(void) dispatchEvent:(JS::HandleValue)arg withRequestId:(int)id;

-(void) dispatchEventFromString:(NSString *)evt withRequestId:(int)id;
-(void) dispatchEventFromString:(NSString *)evt;

-(void) performGC;
-(void) performMaybeGC;

+(js_core*) lastJS;
+(NSString*) getDeviceId;

@end

struct LastErrorInfo {
	bool valid;
	char msg[2048];
	char url[256];
	int line_number;
};

extern LastErrorInfo LAST_ERROR;

#endif


// Internal: Calls initRuntime method
CEXPORT bool setup_js_runtime();


#endif // JS_CORE_H
