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

#include "js/jsPurchase.h"
#import "platform/purchase.h"

static js_core *m_core = nil;


JSAG_MEMBER_BEGIN(buy, 1)
{
	JSAG_ARG_NSTR(pid);

	[[PaymentObserver get] buy:pid];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(restore)
{
	[[PaymentObserver get] restore];
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(confirmPurchase, 1)
{
	JSAG_ARG_NSTR(tid);

	[[PaymentObserver get] finishTransaction:tid];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(onResult)
{
	JSAG_RETURN_BOOL(false);
}
JSAG_MEMBER_END_NOARGS


JSAG_OBJECT_START(purchase)
JSAG_OBJECT_MEMBER(buy)
JSAG_OBJECT_MEMBER(restore)
JSAG_OBJECT_MEMBER(confirmPurchase)
JSAG_MUTABLE_OBJECT_MEMBER(onResult)
JSAG_OBJECT_END


static JSBool defSupported(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	vp.setBoolean([[PaymentObserver get] marketAvailable]);

	JS_EndRequest(cx);
	return JS_TRUE;
}


@implementation jsPurchase

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

	JSObject *purchase = JS_NewObject(js.cx, NULL, NULL, NULL);
	JS_DefineProperty(js.cx, purchase, "supported", JSVAL_FALSE, defSupported, NULL, PROPERTY_FLAGS);
	JSAG_OBJECT_ATTACH_EXISTING(js.cx, js.native, purchase, purchase);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end
