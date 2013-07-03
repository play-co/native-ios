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

#import "jsPhoto.h"
#import "js_core.h"
#import "jsMacros.h"
#include "photo.h"


JSAG_MEMBER_BEGIN(getPhoto, 1)
{
    JSAG_ARG_NSTR(url)
    camera_get_photo(url);
	JSAG_RETURN_INT32(3);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(camera)
JSAG_OBJECT_MEMBER(getPhoto)
JSAG_OBJECT_END


JSAG_MEMBER_BEGIN(galleryGetPhoto, 1)
{
    JSAG_ARG_NSTR(url)
    gallery_get_photo(url);
	JSAG_RETURN_INT32(3);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(gallery)
JSAG_OBJECT_MEMBER_NAMED(getPhoto, galleryGetPhoto)
JSAG_OBJECT_END

@implementation jsPhoto

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, camera);
	JSAG_OBJECT_ATTACH(js.cx, js.native, gallery);
}

+ (void) onDestroyRuntime {
	
}

@end
