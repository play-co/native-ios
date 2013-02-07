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

#import "js/jsBase.h"
#import "platform/ResourceLoader.h"
#include "platform/log.h"
#include "core/platform/location_manager.h"

static js_core *m_core = 0;
static NSString *m_location = nil; // window.location cache


JSAG_MEMBER_BEGIN(getFileSync, 1)
{
	JSAG_ARG_NSTR(url);

	NSLOG(@"{base} GET %@", url);

	NSString *source = [[ResourceLoader get] initStringWithContentsOfURL:url];

	if (source == nil) {
		JSAG_RETURN_FALSE;
	} else {
		[source autorelease];
		JSAG_RETURN_NSTR(source);
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(eval, 2)
{
	JSAG_ARG_NSTR(source);
	JSAG_ARG_NSTR(path);
	
	JSAG_RETURN_JSVAL([m_core evalStr:source withPath:path]);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(native)
JSAG_OBJECT_MEMBER(eval)
JSAG_OBJECT_MEMBER(getFileSync)
JSAG_OBJECT_END


// GLOBAL.location setter/getter

static JSBool jsSetLocation(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	JSString *jsurl = vp.toString();

	JSTR_TO_NSTR(cx, jsurl, url);

	// Pass the string over to jsBase
	[jsBase setLocation:url];

	JS_EndRequest(cx);
	return JS_TRUE;
}

static JSBool jsGetLocation(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	NSString *url = m_location;

	// If location has not been set for some reason,
	if (!url) {
		// Return the empty string ""
		vp.setString(JS_GetEmptyString(JS_GetRuntime(cx)));
	} else {
		vp.setString(NSTR_TO_JSTR(cx, url));
	}

	JS_EndRequest(cx);
	return JS_TRUE;
}


@implementation jsBase

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

	JS_DefineFunctions(js.cx, js.native, (JSFunctionSpec*)jsag_native_members);
}

+ (void) setLocation:(NSString *)location {
	// If location has not been set yet,
	if (!m_location) {
		// Add the property to the global object AND the native object (backwards compat)
		JS_DefineProperty(m_core.cx, m_core.global, "location", NSTR_TO_JSVAL(m_core.cx, location), jsGetLocation, jsSetLocation, JSPROP_ENUMERATE | JSPROP_PERMANENT);
		JS_DefineProperty(m_core.cx, m_core.native, "location", NSTR_TO_JSVAL(m_core.cx, location), jsGetLocation, jsSetLocation, JSPROP_ENUMERATE | JSPROP_PERMANENT);
	} else {
		// Release the old location
		[m_location release];

		// Browse to the new location
		location_manager_set_location([location UTF8String]);
	}

	// Copy the provided location and retain it
	m_location = [[NSString stringWithString:location] retain];
}

+ (void) onDestroyRuntime {
	m_core = nil;

	// Free location cache
	if (m_location) {
		[m_location release];
		m_location = nil;
	}
}

@end
