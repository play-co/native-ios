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

#import "js/jsMarket.h"
#import "core/platform/native.h"

static js_core *m_core = NULL;

static bool defMarketUrl(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	vp.setString(CSTR_TO_JSTR(cx, get_market_url()));

	JS_EndRequest(cx);
	return true;
}

@implementation jsMarket

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

  JS::RootedObject market(js.cx, JS_NewObject(js.cx, NULL, NULL, NULL));
	JS_DefineProperty(js.cx, js.native, "market", OBJECT_TO_JSVAL(market), NULL, NULL, PROPERTY_FLAGS);
	JS_DefineProperty(js.cx, market, "url", JSVAL_FALSE, defMarketUrl, NULL, PROPERTY_FLAGS);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end
