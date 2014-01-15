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
#import "Base64.h"
#import "adapter/QRCodeProcessor.h"
#import "core/image_loader.h"

JSAG_MEMBER_BEGIN(getPhoto, 4)
{
    JSAG_ARG_CSTR(url)
    JSAG_ARG_INT32(width)
    JSAG_ARG_INT32(height)
    JSAG_ARG_INT32(crop)

	LOG("{photo} Camera get photo for URL=%s crop=%d", url, crop);

    camera_get_photo(url, width, height, crop);
	JSAG_RETURN_INT32(3);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(processQR, 1)
{
    JSAG_ARG_NSTR(b64image)

	char text[512];
	qr_process_base64_image([b64image UTF8String], text);

	JSAG_RETURN_CSTR(text);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(encodeQR, 1)
{
    JSAG_ARG_CSTR(text)

	int width, height;
	char *b64image = qr_generate_base64_image(text, &width, &height);

	JSAG_RETURN_CSTR(b64image);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(camera)
JSAG_OBJECT_MEMBER(getPhoto)
JSAG_OBJECT_MEMBER(processQR)
JSAG_OBJECT_MEMBER(encodeQR)
JSAG_OBJECT_END


JSAG_MEMBER_BEGIN(galleryGetPhoto, 4)
{
    JSAG_ARG_CSTR(url)
    JSAG_ARG_INT32(width)
    JSAG_ARG_INT32(height)
    JSAG_ARG_INT32(crop)

	LOG("{photo} Gallery get photo for URL=%s crop=%d", url, crop);

    gallery_get_photo(url, width, height, crop);

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

