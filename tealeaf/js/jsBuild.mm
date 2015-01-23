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

#import "jsBuild.h"

@implementation jsBuild

+ (void) addToRuntime:(js_core *)js {
  JSContext* cx = get_js_context();
  JS::RootedObject build_obj(cx, JS_NewObject(js.cx, NULL, NULL, NULL));
  JS::RootedValue build_val(cx, OBJECT_TO_JSVAL(build_obj));
	
	NSString *sdk_hash = [js.config objectForKey:@"sdk_hash"];
	if (sdk_hash != nil) {
		JS_DefineProperty(cx, build_obj, "sdkHash", NSTR_TO_JSVAL(cx, sdk_hash), NULL, NULL, PROPERTY_FLAGS);
	}
	
	NSString *native_hash = [js.config objectForKey:@"native_hash"];
	if (native_hash != nil) {
		JS_DefineProperty(cx, build_obj, "iosHash", NSTR_TO_JSVAL(cx, native_hash), NULL, NULL, PROPERTY_FLAGS);
	}
	
	NSString *game_hash = [js.config objectForKey:@"game_hash"];
	if (game_hash != nil) {
		JS_DefineProperty(cx, build_obj, "gameHash", NSTR_TO_JSVAL(cx, game_hash), NULL, NULL, PROPERTY_FLAGS);
	}

	JS_DefineProperty(cx, js.native, "build", build_val, NULL, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	
}

@end
