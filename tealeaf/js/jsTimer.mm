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

#import "js/jsTimer.h"
#include "core/timestep/timestep_animate.h"
#include "GCAPI.h"

static JSObject *m_callback = nil;
static js_core *m_core = nil;


#define GC_REPORT_INCREMENTAL_TIMES

static unsigned int gc_tick_twiddle = 0;


static void window_on_error(JSContext *cx, const char *msg, const char *url, int line_number) {
	JS_BeginRequest(cx);
		
	JSObject *global = get_global_object();
		
  JS::RootedValue onerror(cx);
	JS_GetProperty(cx, global, "onerror", &onerror);
		
	if (!JSVAL_IS_VOID(onerror)) {
		jsval args[3] = {
			CSTR_TO_JSVAL(cx, msg),
			CSTR_TO_JSVAL(cx, url),
			INT_TO_JSVAL(line_number)
		};
			
		jsval ret;
		JS_CallFunctionValue(cx, global, onerror, 3, args, &ret);
	}
		
	JS_EndRequest(cx);
}

CEXPORT void js_tick(long dt) {
	if (m_callback) {
    JSAutoRequest ar(m_core.cx);

		jsval args[] = {
      JS::NumberValue(dt)
		};
    
    JS::RootedValue ret(m_core.cx);

		JS_CallFunctionValue(m_core.cx, m_core.global, OBJECT_TO_JSVAL(m_callback), 1, args, ret.address());
	}

	view_animation_tick_animations(dt);




	if ((gc_tick_twiddle++ & 60) == 0) {
		JS_MaybeGC(m_core.cx);


		if (LAST_ERROR.valid) {
			window_on_error(get_js_context(), LAST_ERROR.msg, LAST_ERROR.url, LAST_ERROR.line_number);
			
			LAST_ERROR.valid = false;
		}
	}
}


JSAG_MEMBER_BEGIN(start, 1)
{
	JSAG_ARG_FUNCTION(cb);

	m_callback = cb;

	JS_AddObjectRoot(cx, &m_callback);
}
JSAG_MEMBER_END


JSAG_OBJECT_START(timer)
JSAG_OBJECT_MEMBER(start)
JSAG_OBJECT_END


@implementation jsTimer

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

	JSAG_OBJECT_ATTACH(js.cx, js.native, timer);
}

+ (void) onDestroyRuntime {
	m_callback = nil;
	m_core = nil;
}

@end
