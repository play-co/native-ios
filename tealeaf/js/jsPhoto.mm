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

JSAG_MEMBER_BEGIN(getPhoto, 3)
{
    JSAG_ARG_CSTR(url)
    JSAG_ARG_INT32(width)
    JSAG_ARG_INT32(height)
    camera_get_photo(url, width, height);
	JSAG_RETURN_INT32(3);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(processQR, 3)
{
    JSAG_ARG_NSTR(b64image)
    JSAG_ARG_INT32(width)
    JSAG_ARG_INT32(height)

	LOG("{qr} Decoding base64 data");

	// Decode base64 data
	NSData *data = decodeBase64(b64image);
	int length = 0;
	const void *bytes = 0;

	// If data was decoded,
	if (data) {
		length = [data length];
		bytes = [data bytes];

		LOG("{qr} Successfully decoded base64 data with %d bytes", length);
	} else {
		LOG("{qr} WARNING: Could not decode base64 data!");
	}

	// Default is empty string
	char textbuffer[512] = {0};
	const char *text = textbuffer;

	if (bytes && length > 0) {
		// If length indicates it is already monochrome,
		if (length == width * height) {
			LOG("{qr} QR processing provided monochrome luminance image");
			
			qr_process((const unsigned char *)bytes, width, height, textbuffer);
		} else if (length == 3 * width * height) {
			unsigned char *lum = new unsigned char[width * height];
			
			LOG("{qr} Processing RGB/BGR input data to luminance raster");
			
			// Convert to luminance
			const unsigned char *input = (const unsigned char *)bytes;
			unsigned char *output = lum;
			for (int y = 0; y < height; ++y) {
				for (int x = 0; x < width; ++x) {
					// Green is 2x as intense as other colors, assume RGB or BGR
					int mag = (unsigned int)input[0] + ((unsigned int)input[1] << 1) + (unsigned int)input[2];
					mag /= (256 * 4);
					//if (mag < 0) mag = 0;
					if (mag > 255) mag = 255;
					*output++ = (unsigned char)mag;
					input += 3;
				}
			}
			
			LOG("{qr} QR processing luminance image");
			
			qr_process((const unsigned char *)bytes, width, height, textbuffer);
			
			delete []lum;
		} else if (length == 4 * width * height) {
			unsigned char *lum = new unsigned char[width * height];
			
			LOG("{qr} Processing RGBA-type input data to luminance raster");
			
			// Convert to luminance
			const unsigned char *input = (const unsigned char *)bytes;
			unsigned char *output = lum;
			for (int y = 0; y < height; ++y) {
				for (int x = 0; x < width; ++x) {
					// Not sure if alpha comes first or last so do not attempt green tweak here
					int mag = (unsigned int)input[0] + (unsigned int)input[1] + (unsigned int)input[2] + (unsigned int)input[3];
					mag /= (256 * 4);
					//if (mag < 0) mag = 0;
					if (mag > 255) mag = 255;
					*output++ = (unsigned char)mag;
					input += 4;
				}
			}
			
			LOG("{qr} QR processing luminance image");
			
			qr_process((const unsigned char *)bytes, width, height, textbuffer);
			
			delete []lum;
		}
	} else {
		text = "Invalid input image";
	}

	LOG("{qr} Result is: '%s'", text);

	// Return decoded text
	JSAG_RETURN_CSTR(text);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(camera)
JSAG_OBJECT_MEMBER(getPhoto)
JSAG_OBJECT_MEMBER(processQR)
JSAG_OBJECT_END


JSAG_MEMBER_BEGIN(galleryGetPhoto, 3)
{
    JSAG_ARG_CSTR(url)
    JSAG_ARG_INT32(width)
    JSAG_ARG_INT32(height)
    gallery_get_photo(url, width, height);
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
