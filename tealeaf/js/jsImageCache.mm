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

#import "js/jsImageCache.h"
#import "core/image-cache/include/image_cache.h"

JSAG_MEMBER_BEGIN(remove, 1)
{
	JSAG_ARG_CSTR(url);
	image_cache_remove(url);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(imageCache)
JSAG_OBJECT_MEMBER(remove)
JSAG_OBJECT_END


@implementation jsImageCache

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, imageCache);
}

+ (void) onDestroyRuntime {
	
}

@end
