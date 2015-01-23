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

#import "js/jsXHR.h"
#import "core/platform/xhr.h"
#import "platform/xhr.h"
#import "platform/log.h"

static js_core *m_core = nil;
static NSMutableDictionary *m_xhrs = nil;

JSAG_MEMBER_BEGIN(send, 6)
{
	JSAG_ARG_NSTR(method);
	JSAG_ARG_NSTR(url);
	JSAG_ARG_INT32(async);
	JSAG_ARG_NSTR(data);
	JSAG_ARG_INT32(state);
	JSAG_ARG_INT32(idi);
	JSAG_ARG_OBJECT_OPTIONAL(hdr_obj);
  
  JSAutoRequest areq(cx);

	NSMutableDictionary *headers = nil;

	if (hdr_obj) {
		JSIdArray *idArray = JS_Enumerate(cx, hdr_obj);

		if (idArray) {
			const int count = JS_IdArrayLength(cx, idArray);

			headers = [NSMutableDictionary dictionaryWithCapacity:count];

			for (int ii = 0; ii < count; ++ii) {
				jsid jid = JS_IdArrayGet(cx, idArray, ii);
				jsval idval;
        JS::RootedValue propval(cx);

				JS_IdToValue(cx, jid, &idval);
				JS_LookupPropertyById(cx, hdr_obj, jid, &propval);

        JS::RootedValue idvalRooted(cx, idval);
				if (likely(JSVAL_IS_STRING(idval) && JSVAL_IS_STRING(propval))) {
					JSVAL_TO_NSTR(cx, idvalRooted, nsid);
					JSVAL_TO_NSTR(cx, propval, nsprop);
					
					[headers setObject:nsprop forKey:nsid];
				}
			}
			
			JS_DestroyIdArray(cx, idArray);
		}
	}

	if ([url hasPrefix: @"//"]) {
		url = [NSString stringWithFormat: @"http:%@", url];
	}
	
	if (![url hasPrefix: @"http"]) {
		NSLOG(@"{xhr} ERROR: '%@' is not a url", url);

		int state = 4;
		int status = 0;
		jsval jsid, jsstate, jsstatus, jsresponse, jsname;
		jsid = INT_TO_JSVAL(idi);
		jsstate = INT_TO_JSVAL(state);
		jsstatus = INT_TO_JSVAL(status);
		jsresponse = CSTR_TO_JSVAL(cx, "");
		jsname = CSTR_TO_JSVAL(cx, "xhr");

    JS::RootedObject xhr_obj(cx, JS_NewObject(cx, NULL, NULL, NULL));
    JS::RootedValue _jsid(cx, jsid);
    JS::RootedValue _jsstate(cx, jsstate);
    JS::RootedValue _jsstatus(cx, jsstatus);
    JS::RootedValue _jsresponse(cx, jsresponse);
    JS::RootedValue _jsname(cx, jsname);
		JS_SetProperty(cx, xhr_obj, "id", _jsid);
		JS_SetProperty(cx, xhr_obj, "state", _jsstate);
		JS_SetProperty(cx, xhr_obj, "status", _jsstatus);
		JS_SetProperty(cx, xhr_obj, "response", _jsresponse);
		JS_SetProperty(cx, xhr_obj, "name", _jsname);
    JS::RootedValue xhr_val(cx, OBJECT_TO_JSVAL(xhr_obj));

		[m_core dispatchEvent:xhr_val];
	} else {
		LOG("{xhr} Send state:%i async:%i id:%i", state, async, idi);

		XHR *req = [XHR httpRequestForURL:[NSURL URLWithString:url] withMethod:method andBody:data andHeaders:headers andID:idi];
		[m_xhrs setObject:req forKey:[NSNumber numberWithInt:idi]];
	}
}
JSAG_MEMBER_END

JSAG_OBJECT_START(xhr)
JSAG_OBJECT_MEMBER(send)
JSAG_OBJECT_END



@implementation jsXHR

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

	JSAG_OBJECT_ATTACH(js.cx, js.native, xhr);

	m_xhrs = [[NSMutableDictionary alloc] init];
}

+ (void) onResponse:(NSString *)response fromRequest:(XHR *)sender {
	NSLOG(@"{xhr} Response status:%d length:%d", sender.status, [response length]);

	JSContext *cx = m_core.cx;
  JSAutoRequest areq(cx);

	int myID = sender.myID;
	int state = sender.state;
	int status = sender.status;
	jsval jsid, jsstate, jsstatus, jsresponse, jsname;
	jsid = INT_TO_JSVAL(myID);
	jsstate = INT_TO_JSVAL(state);
	jsstatus = INT_TO_JSVAL(status);
	jsresponse = NSTR_TO_JSVAL(cx, response);
	jsname = CSTR_TO_JSVAL(cx, "xhr");

	JSObject *header_keys = JS_NewArrayObject(cx, 0, NULL);
	JSObject *header_values = JS_NewArrayObject(cx, 0, NULL);
	int i = 0;

	for (NSObject *key in sender.headers) {
		NSObject *value = [sender.headers objectForKey:key];

		if ([key isKindOfClass:[NSString class]] &&
			[value isKindOfClass:[NSString class]])
		{
			jsval key_val = NSTR_TO_JSVAL(cx, (NSString *)key);
      JS::RootedValue _key_val(cx, key_val);
			JS_SetElement(cx, header_keys, i, &_key_val);

			jsval value_val = NSTR_TO_JSVAL(cx, (NSString *)value);
      JS::RootedValue _value_val(cx, value_val);
			JS_SetElement(cx, header_values, i, &_value_val);

			i++;
		}
	}

  JS::RootedObject xhr_obj(cx, JS_NewObject(cx, NULL, NULL, NULL));
  JS::RootedValue _jsid(cx, jsid);
  JS::RootedValue _jsstate(cx, jsstate);
  JS::RootedValue _jsstatus(cx, jsstatus);
  JS::RootedValue _jsresponse(cx, jsresponse);
  JS::RootedValue _jsname(cx, jsname);
	JS_SetProperty(cx, xhr_obj, "id", _jsid);
	JS_SetProperty(cx, xhr_obj, "state", _jsstate);
	JS_SetProperty(cx, xhr_obj, "status", _jsstatus);
	JS_SetProperty(cx, xhr_obj, "response", _jsresponse);
	JS_SetProperty(cx, xhr_obj, "name", _jsname);
  JS::RootedValue header_keys_val(cx, OBJECT_TO_JSVAL(header_keys));
  JS::RootedValue header_values_val(cx, OBJECT_TO_JSVAL(header_values));
	JS_SetProperty(cx, xhr_obj, "headerKeys", header_keys_val);
	JS_SetProperty(cx, xhr_obj, "headerValues", header_values_val);
  JS::RootedValue xhr_val(cx, OBJECT_TO_JSVAL(xhr_obj));

  [m_core dispatchEvent:xhr_val];
	
	[m_xhrs removeObjectForKey:[NSNumber numberWithInt:myID]];
}

+ (void) onDestroyRuntime {
	m_core = nil;

	if (m_xhrs) {
		[m_xhrs release];
	}
}

@end
