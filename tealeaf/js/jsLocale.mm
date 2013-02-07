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

#include "core/platform/get_locale.h"
#import "js/jsLocale.h"

@implementation jsLocale

+ (void) addToRuntime:(js_core *)js {
	locale_info *info = locale_get_locale();

	JSContext *cx = js.cx;

	JSObject *obj_locale = JS_NewObject(cx, NULL, NULL, NULL);
	JS_DefineProperty(cx, obj_locale, "language", CSTR_TO_JSVAL(cx, info->language), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_locale, "country", CSTR_TO_JSVAL(cx, info->country), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, js.native, "locale", OBJECT_TO_JSVAL(obj_locale), NULL, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	
}

@end
