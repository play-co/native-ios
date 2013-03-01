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

#import "js/jsNavigator.h"
#import "TeaLeafAppDelegate.h"

#include "core/platform/get_locale.h"
#include "core/config.h"


static JSBool JSPOP_Online(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	TeaLeafAppDelegate *app = (TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate];

	JS_BeginRequest(cx);
	vp.setBoolean(app.isOnline == YES);
	JS_EndRequest(cx);

	return JS_TRUE;
}


@implementation jsNavigator

+ (void) addToRuntime:(js_core *)js {
	locale_info *info = locale_get_locale();

	JSContext *cx = js.cx;
	JSObject *obj_navigator = JS_NewObject(cx, NULL, NULL, NULL);

	// Support older versions of iOS conditionally
	float scale = 1;
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		scale = [[UIScreen mainScreen] scale];
	}

	// Fix formula for various device types
	float dpi;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		dpi = 132.f;
	} else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		dpi = 163.f;
	} else {
		dpi = 160.f;
	}
	dpi *= scale;

	//add the pixel ratio to the window object
	JSObject* window = get_global_object();
	JS_DefineProperty(cx, window, "devicePixelRatio", DOUBLE_TO_JSVAL(scale), NULL, NULL, PROPERTY_FLAGS);

	// displayMetrics subobject
	JSObject *obj_metric = JS_NewObject(cx, NULL, NULL, NULL);
	JS_DefineProperty(cx, obj_metric, "densityDpi", DOUBLE_TO_JSVAL(dpi), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_navigator, "displayMetrics", OBJECT_TO_JSVAL(obj_metric), NULL, NULL, PROPERTY_FLAGS);

	NSString *sdk_hash = [js.config objectForKey:@"sdk_hash"];
	NSString *native_hash = [js.config objectForKey:@"native_hash"];
	NSString *game_hash = [js.config objectForKey:@"game_hash"];

	// NOTE: .model will be a string like "iPad" or "iPhone"
	NSString *ua = [NSString stringWithFormat:@"%@/%@ TeaLeaf/%@ GC/%@", [UIDevice currentDevice].model, game_hash, native_hash, sdk_hash, nil];
	JS_DefineProperty(cx, obj_navigator, "userAgent", NSTR_TO_JSVAL(cx, ua), NULL, NULL, PROPERTY_FLAGS);

	JS_DefineProperty(cx, obj_navigator, "onLine", JSVAL_FALSE, JSPOP_Online, NULL, PROPERTY_FLAGS);

	JS_DefineProperty(cx, obj_navigator, "width", INT_TO_JSVAL(config_get_screen_width()), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_navigator, "height", INT_TO_JSVAL(config_get_screen_height()), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_navigator, "language", CSTR_TO_JSVAL(cx, info->language), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_navigator, "country", CSTR_TO_JSVAL(cx, info->country), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, js.global, "navigator", OBJECT_TO_JSVAL(obj_navigator), NULL, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	
}

@end
