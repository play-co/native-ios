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

#import "js/jsLocalStorage.h"
#import "platform/LocalStorage.h"


JSAG_MEMBER_BEGIN(setItem, 2)
{
	JSAG_ARG_NSTR(key);
	JSAG_ARG_NSTR(val);

	bool rval = !local_storage_get(key);

	local_storage_set(key, val);

	JSAG_RETURN_BOOL(rval);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(getItem, 1)
{
	JSAG_ARG_NSTR(key);
	
	NSString *value = local_storage_get(key);

	if (value) {
		JSAG_RETURN_NSTR(value);
	} else {
		JSAG_RETURN_NULL;
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(removeItem, 1)
{
	JSAG_ARG_NSTR(key);

	local_storage_remove(key);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(clear)
{
	local_storage_clear();
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(key, 1)
{
	JSAG_ARG_INT32(index);

	NSString *key = local_storage_key(index);
	
	if (key) {
		JSAG_RETURN_NSTR(key);
	} else {
		JSAG_RETURN_VOID;
	}
}
JSAG_MEMBER_END


JSAG_OBJECT_START(localStorage)
JSAG_OBJECT_MEMBER(setItem)
JSAG_OBJECT_MEMBER(getItem)
JSAG_OBJECT_MEMBER(removeItem)
JSAG_OBJECT_MEMBER(clear)
JSAG_OBJECT_MEMBER(key)
JSAG_OBJECT_END


@implementation jsLocalStorage

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, localStorage);
}

+ (void) onDestroyRuntime {
	
}

@end
