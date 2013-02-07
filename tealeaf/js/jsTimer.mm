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

#import "js/jsTimer.h"
#include "core/timestep/timestep_animate.h"

static JSObject *m_callback = nil;
static js_core *m_core = nil;


#define GC_REPORT_INCREMENTAL_TIMES

static unsigned int gc_tick_twiddle = 0;


CEXPORT void js_tick(int dt) {
	if (m_callback) {
		jsval ret, args[] = {
			INT_TO_JSVAL(dt)
		};

		JS_BeginRequest(m_core.cx);
		JS_CallFunctionValue(m_core.cx, m_core.global, OBJECT_TO_JSVAL(m_callback), 1, args, &ret);
		JS_EndRequest(m_core.cx);
	}

	view_animation_tick_animations(dt);

#ifdef GC_REPORT_INCREMENTAL_TIMES
	NSDate *start_date = [NSDate date];
#endif

	if ((gc_tick_twiddle++ & 3) == 0) {
		JS_MaybeGC(m_core.cx);
	}
	
#ifdef GC_REPORT_INCREMENTAL_TIMES
	NSTimeInterval msInterval = fabs([start_date timeIntervalSinceNow] * 1000.0);

	if (msInterval > 1.5f) {
		LOG("{js} GC took %lf ms (incremental)", msInterval);
	}
#endif
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
