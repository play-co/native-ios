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

	LOG("{qr} Decoding base64 data");

	// Decode base64 data
	NSData *data = decodeBase64(b64image);
	unsigned char *image = 0;
	int width, height, channels;

	// If data was decoded,
	if (data) {
		int length = [data length];
		const void *bytes = [data bytes];
		
		LOG("{qr} Successfully decoded base64 data with %d bytes", length);

		image = load_image_from_memory((unsigned char *)bytes, length, &width, &height, &channels);

		if (image) {
			LOG("{qr} Successfully decoded image data with width=%d, height=%d, channels=%d", width, height, channels);
		} else {
			LOG("{qr} WARNING: Unable to load image from memory");
		}
	} else {
		LOG("{qr} WARNING: Could not decode base64 data!");
	}

	// Default is empty string
	char textbuffer[512] = {0};
	const char *text = textbuffer;

	if (image && width > 0 && height > 0 && channels > 0) {
		if (channels == 1) {
			LOG("{qr} QR processing provided monochrome luminance image");
			
			qr_process((const unsigned char *)image, width, height, textbuffer);
		} else if (channels == 3) {
			LOG("{qr} Processing RGB/BGR input data to luminance raster");
			
			// Convert to luminance
			const unsigned char *input = (const unsigned char *)image;
			unsigned char *output = image;
			for (int y = 0; y < height; ++y) {
				for (int x = 0; x < width; ++x) {
					// Green is 2x as intense as other colors, assume RGB or BGR
					int mag = (unsigned int)input[0] + ((unsigned int)input[1] << 1) + (unsigned int)input[2];
					mag /= 4;
					//if (mag < 0) mag = 0;
					if (mag > 255) mag = 255;
					*output++ = (unsigned char)mag;
					input += 3;
				}
			}
			
			LOG("{qr} QR processing luminance image");
			
			qr_process((const unsigned char *)image, width, height, textbuffer);
		} else if (channels == 4) {
			LOG("{qr} Processing RGBA-type input data to luminance raster");
			
			// Convert to luminance
			const unsigned char *input = (const unsigned char *)image;
			unsigned char *output = image;
			for (int y = 0; y < height; ++y) {
				for (int x = 0; x < width; ++x) {
					// Green is 2x as intense as other colors, assume RGBA or BGRA and ignore alpha (experimentally true)
					int mag = (unsigned int)input[0] + ((unsigned int)input[1] << 1) + (unsigned int)input[2];
					mag /= 4;
					//if (mag < 0) mag = 0;
					if (mag > 255) mag = 255;
					*output++ = (unsigned char)mag;
					input += 4;
				}
			}
			
			LOG("{qr} QR processing luminance image");
			
			qr_process((const unsigned char *)image, width, height, textbuffer);
		}
	} else {
		text = "Invalid input image";
	}

	LOG("{qr} Result is: '%s'", text);

	free(image);
	
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

