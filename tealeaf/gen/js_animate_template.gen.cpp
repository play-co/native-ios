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
 * along with the Game Closure SDK.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "js_animate_template.gen.h"
#include "js/js_animate.h"



#include "js/js_core.h"





static const JSFunctionSpec functions[] = {
	
		JS_FN("now", def_animate_now, 1, FUNCTION_FLAGS),
	
		JS_FN("then", def_animate_then, 1, FUNCTION_FLAGS),
	
		JS_FN("commit", def_animate_commit, 0, FUNCTION_FLAGS),
	
		JS_FN("clear", def_animate_clear, 0, FUNCTION_FLAGS),
	
		JS_FN("wait", def_animate_wait, 1, FUNCTION_FLAGS),
	
		JS_FN("pause", def_animate_pause, 0, FUNCTION_FLAGS),
	
		JS_FN("resume", def_animate_resume, 0, FUNCTION_FLAGS),
	
		JS_FN("isPaused", def_animate_isPaused, 0, FUNCTION_FLAGS),
	
		JS_FN("hasFrames", def_animate_hasFrames, 0, FUNCTION_FLAGS),
	
		JS_FS_END
};



#define BAR_PROPERTY_FLAGS (JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_SHARED)

static const JSPropertySpec properties[] = {
	
	{0}
};

#undef BAR_PROPERTY_FLAGS


static const JSClass animate_class = {
	"Animator",
	JSCLASS_HAS_PRIVATE,
	JS_PropertyStub, JS_DeletePropertyStub, JS_PropertyStub, JS_StrictPropertyStub,
	JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, def_animate_class_finalize,
	JSCLASS_NO_OPTIONAL_MEMBERS
};

CEXPORT JSObject *animate_create_ctor_object(JSContext *cx, jsval *vp) {
	return JS_NewObjectForConstructor(cx, (JSClass*)&animate_class, vp);
}

CEXPORT void animate_add_to_object(JSObject *parent) {
	JSContext *cx = get_js_context();
	JS_InitClass(cx, parent, NULL, (JSClass*)&animate_class, def_animate_class_constructor,
		2, (JSPropertySpec *)properties, (JSFunctionSpec *)functions, NULL, NULL);
}
