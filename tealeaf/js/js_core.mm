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

#import "js/js_core.h"
#include "jsapi.h"
#include "GCAPI.h" // SpiderMonkey Garbage Collect API
#include "Tracer.h"
#import "js/jsMacros.h"
#include <stddef.h>
#include <stdio.h>
#include "core/log.h"
#include "core/core.h"
#include "core/timer.h"
#include "core/config.h"
#include "gen/js_animate_template.gen.h"
#include "gen/js_timestep_image_map_template.gen.h"
#include "gen/js_timestep_view_template.gen.h"
#import "core/platform/location_manager.h"
#import "core/platform/native.h"
#import "js/jsBase.h"
#import "platform/PluginManager.h"
#import "iosVersioning.h"
#import "NativeCalls.h"

// JS Ready flag: Indicates that the JavaScript engine is running (see core/core_js.h)
bool js_ready = false;

static js_core *lastJS = nil;
static JSObject *global_obj = nil;
static NSDate *m_start_date = nil;
static NSString *m_uuid = nil;

CEXPORT JSContext *get_js_context() {
	return lastJS.cx;
}

CEXPORT JSObject *get_global_object() {
	return lastJS.global;
}

LastErrorInfo LAST_ERROR = {
	0
};

/* The error reporter callback. */
static void reportError(JSContext *cx, const char *message, JSErrorReport *report) {
	const char *url = report->filename ? report->filename : "<no filename>";
	NSLOG(@"{js} JavaScript error in %s:%d", url, (unsigned int) report->lineno);
	LOG("{js} Error: %s", message);

  JS::AutoRequest areq(cx);

  JS::RootedValue exception(cx);
	if (JS_GetPendingException(cx, &exception) && exception.isObject()) {
		JSObject *exn = exception.toObjectOrNull();

    JS::RootedValue stack(cx);
		JS_GetProperty(cx, exn, "stack", &stack);

    JSString *s = JS::ToString(cx, stack);

		if (s) {
			JSTR_TO_CSTR_PERSIST(cx, s, cstr);

			LOG("{js} Traceback:\n%s\n\n", cstr);

			PERSIST_CSTR_RELEASE(cstr);
		}
	}

	// Store last error.  This is done because the reportError() callback cannot use JSAPI
	LAST_ERROR.valid = true;
	strncpy(LAST_ERROR.msg, message, sizeof(LAST_ERROR.msg));
	LAST_ERROR.msg[sizeof(LAST_ERROR.msg) - 1] = '\0';
	strncpy(LAST_ERROR.url, url, sizeof(LAST_ERROR.url));
	LAST_ERROR.url[sizeof(LAST_ERROR.url) - 1] = '\0';
	LAST_ERROR.line_number = report->lineno;

	// If getting an out of memory error,
	if (strcmp(message, "out of memory") == 0) {
		// Restart JS from main thread
		TeaLeafAppDelegate *app = (TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app restartJS];
	}
}

#define TIMER_DICT_KEY(timer) [[NSNumber numberWithInt:timer->timerId] stringValue]


static void js_global_finalize(JSFreeOp *fop, JSObject *obj) {
	// Do nothing
}

/* The class of the global object. */
JSClass global_class = {
	"global", JSCLASS_GLOBAL_FLAGS | JSCLASS_HAS_PRIVATE,
	JS_PropertyStub, JS_DeletePropertyStub, JS_PropertyStub, JS_StrictPropertyStub,
	JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, js_global_finalize,
	JSCLASS_NO_OPTIONAL_MEMBERS
};

typedef struct js_timer_info_t {
  JS::Heap<JSObject*> callback;
	JSContext *cx;
	JSObject *global;
} js_timer_info;

void js_timer_unlink(core_timer *timer) {
	js_timer_info *js_data = (js_timer_info*)timer->js_data;
	JSContext *cx = js_data->cx;
  JS::AutoRequest areq(cx);
  js_data->callback = nullptr;
}

void js_timer_fire(core_timer *timer) {
	js_timer_info *js_data = (js_timer_info*)timer->js_data;
	JSContext *cx = js_data->cx;
  JS::AutoRequest areq(cx);
  JS::RootedValue ret(cx);
  JS::RootedObject cbObject(cx, js_data->callback);
  JS::RootedValue cb(cx, OBJECT_TO_JSVAL(cbObject));
  
  JS_CallFunctionValue(cx, js_data->global, cb, 0, NULL, ret.address());
}

static int startTimer(BOOL repeats, JSContext *cx, JS::HandleObject callback, double interval) {
	js_timer_info *js_data = (js_timer_info *)malloc(sizeof(js_timer_info));

	js_data->cx = cx;
	js_data->global = global_obj;
  js_data->callback = callback;

	core_timer *timer = core_get_timer((void*)js_data, interval, repeats);
	core_timer_schedule(timer);
	return timer->id;
}

JSAG_MEMBER_BEGIN(setTimeout, 1)
{
	JSAG_ARG_FUNCTION(callback);
	JSAG_ARG_DOUBLE_OPTIONAL(interval, 0);

	JSAG_RETURN_INT32(startTimer(NO, cx, callback, interval));
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setInterval, 1)
{
	JSAG_ARG_FUNCTION(callback);
	JSAG_ARG_DOUBLE_OPTIONAL(interval, 0);

	JSAG_RETURN_INT32(startTimer(YES, cx, callback, interval));
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(clearTimeout, 1)
{
	JSAG_ARG_INT32(timerId);
	
	core_timer_clear(timerId);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(clearInterval, 1)
{
	JSAG_ARG_INT32(timerId);

	core_timer_clear(timerId);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setLocation, 1)
{
	JSAG_ARG_NSTR(location);

	LOG("{js} setLocation %@", location);

	[jsBase setLocation:location];
}
JSAG_MEMBER_END

JSAG_OBJECT_START(GLOBAL)
JSAG_OBJECT_MEMBER(setTimeout)
JSAG_OBJECT_MEMBER(setInterval)
JSAG_OBJECT_MEMBER(clearTimeout)
JSAG_OBJECT_MEMBER(clearInterval)
JSAG_OBJECT_MEMBER(setLocation)
JSAG_OBJECT_END


//// NATIVE

JSAG_MEMBER_BEGIN_NOARGS(doneLoading)
{
	core_hide_preloader();

	LOG("{js} Game is done loading");
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(stayAwake, 1)
{
	JSAG_ARG_INT32(enable);

	bool on = (enable != 0);
	
	LOG("{js} Setting stay-awake: %d", on);

	native_stay_awake(on);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(_call, 2)
{
	JSAG_ARG_NSTR(name);
   	JSAG_ARG_NSTR(str);
  	NSError *err = nil;

    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingMutableContainers
                                                           error:&err];
    
   	LOG("{js} _call %@ %@", name, str);
    NSMutableDictionary *ret = [NativeCalls Call:name withArgs:json];
    NSString *retStr = @"{}";
    if (ret != nil) {
        NSData* data = [NSJSONSerialization dataWithJSONObject:ret options:0 error:nil];
        retStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    JSAG_RETURN_NSTR(retStr);
    
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(isSimulator, 0)
{
    bool is_simulator = device_is_simulator();
    JSAG_RETURN_BOOL(is_simulator);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(NATIVE)
JSAG_OBJECT_MEMBER(doneLoading)
JSAG_OBJECT_MEMBER(stayAwake)
JSAG_OBJECT_MEMBER(_call)
JSAG_OBJECT_MEMBER(isSimulator)
JSAG_OBJECT_END


static void jsGCcb(JSRuntime* rt, JSGCStatus status, void* data) {
  switch (status) {
    case JSGC_BEGIN:
      if (m_start_date) {
        [m_start_date release];
      }
      m_start_date = [[NSDate date] retain];
      break;

    case JSGC_END:
      if (m_start_date != nil) {
        // Get time in milliseconds
        NSTimeInterval msInterval = fabs([m_start_date timeIntervalSinceNow] * 1000.0);
        m_start_date = nil;

        if (JS::WasIncrementalGC(rt)) {
          LOG("{js} GC took %lf ms (incremental)", msInterval);
        } else {
          LOG("{js} GC took %lf ms", msInterval);
        }
      }
      break;

    default: // JSGC_MARK_END, JSGC_FINALIZE_END
      LOG("{js} GC MARK/FINALIZE END");
      break;
  }
}

@implementation js_core

-(void) dealloc {
	self.extensions = nil;
	self.privateStore = nil;
	self.pluginManager = nil;
	self.config = nil;
	
	lastJS = nil;
	global_obj = nil;
	m_start_date = nil;

	[super dealloc];
}

-(void) shutdown {
#ifndef DISABLE_DEBUG_SERVER
	// Kill debug server immediately
	if (self.debugServer) {
		[self.debugServer close];
		[self.debugServer release];
		self.debugServer = nil;
		
		LoggerSetDebugger(nil);
	}
#endif

	JS_GC(self.rt);
	JS_DestroyContext(self.cx);
	JS_DestroyRuntime(self.rt);
	JS_ShutDown();
}

static bool
CheckObjectAccess(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JSAccessMode mode,
                  JS::MutableHandleValue vp) {
  return true;
}

static const
JSSecurityCallbacks securityCallbacks = {
  CheckObjectAccess,
  nullptr
};

void trace_core_timer_list(JSTracer* tracer, core_timer* head) {
  core_timer* timer = head;
  js_timer_info* js_timer;
  while (timer != NULL) {
    js_timer = (js_timer_info*)(timer->js_data);
    JS_CallHeapObjectTracer(tracer, &(js_timer->callback), "timer");
    if (timer->next == head) {
      break;
    }
    timer = timer->next;
  }
}

void trace_js_gc_things(JSTracer* tracer, void * data) {
  trace_core_timer_list(tracer, core_get_timers());
  trace_core_timer_list(tracer, core_get_queued_timers());
}

- (id) initRuntime {
	self = [super init];
	lastJS = self;
  self.globalCompartment = nullptr;
  
  if (!JS_Init()) {
    return nullptr;
  }

  JSRuntime* rt;
	self.rt = rt = JS_NewRuntime(8L * 1024L * 1024L, JS_USE_HELPER_THREADS);
	if (!self.rt) {
		LOG("{js} FATAL: Unable to create JS runtime");
		return nullptr;
	}
  
  JS_SetGCParameter(rt, JSGC_MAX_BYTES, 0xfffffff);
  JS_SetGCParameter(rt, JSGC_SLICE_TIME_BUDGET, 20);
  JS_SetGCParameter(rt, JSGC_MODE, JSGC_MODE_INCREMENTAL);
  JS_SetGCCallback(rt, &jsGCcb, nullptr);
  
  JS_AddExtraGCRootsTracer(self.rt, trace_js_gc_things, nullptr);
  
  JSPrincipals trustedPrincipals;
  trustedPrincipals.refcount = 1;
  JS_SetTrustedPrincipals(rt, &trustedPrincipals);
  
  JS_SetSecurityCallbacks(rt, &securityCallbacks);
  
  JS_SetNativeStackQuota(rt, 128 * sizeof(size_t) * 1024);
  
	// Create a context
  JSContext * cx;
  self.cx = cx = JS_NewContext(rt, 8192);
	if (!cx) {
		LOG("{js} FATAL: Unable to create JS context");
		return NULL;
	}
  
  JSAutoRequest areq(cx);
  JS::ContextOptionsRef(cx).setVarObjFix(true);
  
	JS_SetErrorReporter(cx, reportError);
	
	// Create the global object
  JS::RootedObject global(cx);
  global_obj = self.global = JS_NewGlobalObject(cx, &global_class, nullptr, JS::DontFireOnNewGlobalHook);
  global = self.global;
	if (self.global == nullptr) { return nullptr; }

  self.globalCompartment = JS_EnterCompartment(cx, global);
  
	// Populate the global object with the standard globals, like Object and Array
	if (!JS_InitStandardClasses(cx, global)) { return NULL; }
	
	JS_GC(self.rt);
	
	return self;
}

- (id) setConfig:(NSDictionary*)config pluginManager:(PluginManager*)pluginManager {
	self.config = config;
	self.pluginManager = pluginManager;
  JSContext *cx = self.cx;
  JSAutoRequest areq(cx);

	LOG("{js} SpiderMonkey version: %s", JS_GetImplementationVersion());

	self.privateStore = [NSMutableDictionary dictionary];
	[self.privateStore setValue:self forKey:@"self"];
	JS_SetContextPrivate(cx, self.privateStore);
  
	self.native = JS_NewObject(cx, NULL, NULL, NULL);
  JS::RootedValue uuid(cx, NSTR_TO_JSVAL(cx, [js_core getDeviceId]));
	JS_SetProperty(cx, self.native, "deviceUUID", uuid);

	JSAG_OBJECT_ATTACH_EXISTING(self.cx, self.global, GLOBAL, self.global);
	JSAG_OBJECT_ATTACH_EXISTING(self.cx, self.global, NATIVE, self.native);

  JSObject* screenObject = JS_NewObject(cx, nullptr, nullptr, nullptr);
  int screenW = config_get_screen_width();
  int screenH = config_get_screen_height();

  JS::RootedValue screen(cx, JS::ObjectValue(*screenObject));
  JS::RootedValue jscreenW(cx, JS::NumberValue(screenW));
  JS::RootedValue jscreenH(cx, JS::NumberValue(screenH));
  JS::RootedValue global_val(cx, JS::ObjectValue(*self.global));

	JS_SetProperty(self.cx, self.native, "screen", screen);
	JS_SetProperty(self.cx, JSVAL_TO_OBJECT(screen), "width", jscreenW);
	JS_SetProperty(self.cx, JSVAL_TO_OBJECT(screen), "height", jscreenH);
  
	JS_SetProperty(self.cx, self.global, "window", global_val);
	JS_SetProperty(self.cx, self.global, "GLOBAL", global_val);
	JS_SetProperty(self.cx, self.global, "screen", screen);
	
  JS::RootedValue gid(cx, NSTR_TO_JSVAL(cx, [js_core getDeviceId]));
  JS::RootedValue _device(cx, OBJECT_TO_JSVAL(JS_NewObject(self.cx, NULL, NULL, NULL)));

  JS::RootedValue device(cx, _device);
  
	JS_SetProperty(self.cx, JSVAL_TO_OBJECT(device), "globalID", gid);
	JS_SetProperty(self.cx, self.native, "device", device);
  
  JS::RootedValue tcpport(cx, JS::NumberValue([[self.config objectForKey:@"tcp_port"] intValue]));
  JS::RootedValue tcphost(cx, NSTR_TO_JSVAL(cx, [self.config objectForKey:@"tcp_host"]));
  
	JS_SetProperty(self.cx, self.native, "tcpHost", tcphost);
	JS_SetProperty(self.cx, self.native, "tcpPort", tcpport);

#ifndef DISABLE_DEBUG_SERVER
	// If remote loading is enabled,
	TeaLeafAppDelegate *app = (TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate];
	if (app.isTestApp) {
		self.debugServer = [[[DebugServer alloc] init:self] autorelease];
	}
#endif
  
#ifndef RELEASE
  if (!self.debugServer) {
    self.debugServer = [[[DebugServer alloc] init:self] autorelease];
  }
#endif
  
	return self;
}

+(NSString *) getDeviceId {
	if (m_uuid == nil) {
		if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
			m_uuid = [[[NSUUID UUID] UUIDString] retain];
		} else {
			m_uuid = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] retain];
		}
	}

	return m_uuid;
}

-(void) addExtension:(id)extension {
	[self.extensions addObject:extension];
}

-(jsval) eval:(char *)source {
	return [self evalStr: [NSString stringWithUTF8String:source]];
}

-(jsval) evalStr:(NSString *)source {
	return [self evalStr:source withPath:@"eval"];
}

-(jsval) evalStr:(NSString *)source withPath:(NSString *)path {

  const size_t length = [source lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  const char* buffer = [source UTF8String];

	NSString *uniqueName;
#ifndef DISABLE_DEBUG_SERVER
	if (self.debugServer) {
		// Store off the script
		uniqueName = [self.debugServer setScriptForPath:path source:source];
	} else
#endif
	{
		uniqueName = @"eval";
	}
  const char * filename = [uniqueName cStringUsingEncoding:NSASCIIStringEncoding];

  JSAutoRequest ar(self.cx);

  JS::RootedObject global(self.cx, self.global);
  JSAutoCompartment(self.cx, global);
  JS::CompileOptions opts(self.cx, JSVERSION_LATEST);
  opts.setUTF8(true).setFileAndLine(filename, 1);
  JS::RootedValue rval(self.cx);
  
  if(!JS::Evaluate(self.cx, global, opts, buffer, length, rval.address())) {
    NSLOG(@"{js} Error while evaluating JavaScript from %@ (%d script chars)", path, (int)length);
  }

	return rval;
}

-(void) dispatchEvent:(JS::HandleValue)arg {
    [self dispatchEvent:arg withRequestId:0];
}

-(void) dispatchEvent:(JS::HandleValue)arg withRequestId:(int)requestId {
  JSContext* cx = self.cx;
  JSAutoRequest req(cx);
  
  JS::RootedValue events(cx), dispatch(cx), rval(cx);
  JS::Value args[] = {arg, JS::NumberValue(requestId)};
  
	if (js_ready) {
		JS_GetProperty(self.cx, self.native, "events", &events);
    
		if (events.isObject()) {
      JS::RootedObject eventsObject(cx, events.toObjectOrNull());
			JS_GetProperty(self.cx, eventsObject, "dispatchEvent", &dispatch);
      
			if (!dispatch.isUndefined()) {
				JS_CallFunctionName(self.cx, eventsObject, "dispatchEvent", 2, args, rval.address());
        return;
			}
		}
	}
  
	LOG("{js} ERROR: Firing event failed");
}

-(void) dispatchEventFromString:(NSString *)evt withRequestId:(int)id{
  JS::RootedValue str(self.cx, NSTR_TO_JSVAL(self.cx, evt));
	[self dispatchEvent:str withRequestId:id];
}

-(void) dispatchEventFromString:(NSString *)evt {
    [self dispatchEventFromString:evt withRequestId:0];
}

-(void) performGC {
	LOG("{js} Full GC");
  JS_GC(self.rt);
}

-(void) performMaybeGC {
	LOG("{js} Maybe GC");
  JS_MaybeGC(self.cx);
}

+(js_core*) lastJS {
	return lastJS;
}

@end
