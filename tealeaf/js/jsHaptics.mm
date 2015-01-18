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


static bool JSPOP_HasVibrator(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	bool hasVibe = false;

	// TODO
	
	JS_BeginRequest(cx);
	vp.setBoolean(hasVibe);
	JS_EndRequest(cx);

	return true;
}


@implementation jsHaptics

+(void) addToRuntime:(js_core *)js {
	m_core = js;

  JSContext* cx = get_js_context();
  JS::RootedObject obj(cx, JS_NewObject(js.cx, NULL, NULL, NULL));

	JSAG_OBJECT_ATTACH_EXISTING(js.cx, js.native, haptics, obj);

	JS_DefineProperty(js.cx, obj, "hasVibrator", JSVAL_FALSE, JSPOP_HasVibrator, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end
