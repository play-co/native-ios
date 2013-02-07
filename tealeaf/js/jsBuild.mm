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

#import "jsBuild.h"

@implementation jsBuild

+ (void) addToRuntime:(js_core *)js {
	JSObject *build_obj = JS_NewObject(js.cx, NULL, NULL, NULL);
	jsval build_val = OBJECT_TO_JSVAL(build_obj);
	
	NSString *sdk_hash = [js.config objectForKey:@"sdk_hash"];
	if (sdk_hash != nil) {
		JS_DefineProperty(js.cx, build_obj, "sdkHash", NSTR_TO_JSVAL(js.cx, sdk_hash), NULL, NULL, PROPERTY_FLAGS);
	}
	
	NSString *native_hash = [js.config objectForKey:@"native_hash"];
	if (native_hash != nil) {
		JS_DefineProperty(js.cx, build_obj, "iosHash", NSTR_TO_JSVAL(js.cx, native_hash), NULL, NULL, PROPERTY_FLAGS);
	}
	
	NSString *game_hash = [js.config objectForKey:@"game_hash"];
	if (game_hash != nil) {
		JS_DefineProperty(js.cx, build_obj, "gameHash", NSTR_TO_JSVAL(js.cx, game_hash), NULL, NULL, PROPERTY_FLAGS);
	}

	JS_DefineProperty(js.cx, js.native, "build", build_val, NULL, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	
}

@end
