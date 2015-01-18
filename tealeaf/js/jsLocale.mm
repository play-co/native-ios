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

#include "core/platform/get_locale.h"
#import "js/jsLocale.h"

@implementation jsLocale

+ (void) addToRuntime:(js_core *)js {
	locale_info *info = locale_get_locale();

	JSContext *cx = js.cx;

  JS::RootedObject obj_locale(cx, JS_NewObject(cx, NULL, NULL, NULL));
	JS_DefineProperty(cx, obj_locale, "language", CSTR_TO_JSVAL(cx, info->language), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, obj_locale, "country", CSTR_TO_JSVAL(cx, info->country), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(cx, js.native, "locale", OBJECT_TO_JSVAL(obj_locale), NULL, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	
}

@end
