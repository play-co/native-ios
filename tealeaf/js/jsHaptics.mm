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

#import "js/jsHaptics.h"

static js_core *m_core = nil;


JSAG_MEMBER_BEGIN_NOARGS(cancel)
{
	// TODO
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(vibrate, 1)
{
	JSAG_ARG_OBJECT(opts);

	// TODO
}
JSAG_MEMBER_END

JSAG_OBJECT_START(haptics)
JSAG_OBJECT_MEMBER(cancel)
JSAG_OBJECT_MEMBER(vibrate)
JSAG_OBJECT_END


static JSBool JSPOP_HasVibrator(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	bool hasVibe = false;

	// TODO
	
	JS_BeginRequest(cx);
	vp.setBoolean(hasVibe);
	JS_EndRequest(cx);

	return JS_TRUE;
}


@implementation jsHaptics

+(void) addToRuntime:(js_core *)js {
	m_core = js;

	JSObject *obj = JS_NewObject(js.cx, NULL, NULL, NULL);

	JSAG_OBJECT_ATTACH_EXISTING(js.cx, js.native, haptics, obj);

	JS_DefineProperty(js.cx, obj, "hasVibrator", JSVAL_FALSE, JSPOP_HasVibrator, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end
