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


JSAG_MEMBER_BEGIN_NOARGS(cameraNextId)
{
	JSAG_RETURN_INT32(camera_get_next_id());
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(camera)
JSAG_OBJECT_MEMBER_NAMED(getNextId, cameraNextId)
JSAG_OBJECT_END


JSAG_MEMBER_BEGIN_NOARGS(galleryNextId)
{
	JSAG_RETURN_INT32(gallery_get_next_id());
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(gallery)
JSAG_OBJECT_MEMBER_NAMED(getNextId, galleryNextId)
JSAG_OBJECT_END


@implementation jsPhoto

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, camera);
	JSAG_OBJECT_ATTACH(js.cx, js.native, gallery);
}

+ (void) onDestroyRuntime {
	
}

@end
