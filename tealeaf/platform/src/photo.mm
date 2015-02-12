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

#include "photo.h"
#import "TeaLeafAppDelegate.h"

int camera_get_photo(const char *url_str, int width, int height, int crop) {
	NSString  *url = [NSString stringWithUTF8String: url_str];
    TeaLeafAppDelegate *appDelegate = (TeaLeafAppDelegate*)[[UIApplication sharedApplication] delegate];
    TeaLeafViewController *viewController = [appDelegate tealeafViewController];
    [viewController showImagePickerForCamera:url width:width height:height crop:crop];
    return 0;
}

int gallery_get_photo(const char *url_str, int width, int height, int crop) {
	NSString  *url = [NSString stringWithUTF8String: url_str];
    TeaLeafAppDelegate *appDelegate = (TeaLeafAppDelegate*)[[UIApplication sharedApplication] delegate];
    TeaLeafViewController *viewController = [appDelegate tealeafViewController];
    [viewController showImagePickerForPhotoPicker:url width:width height:height crop:crop];
    return 0;
}

int camera_get_next_id() {
    // TeaLeafAppDelegate *appDelegate = (TeaLeafAppDelegate*)[[UIApplication sharedApplication] delegate];
    // TeaLeafViewController *viewController = [appDelegate tealeafViewController];
    // [viewController showImagePickerForPhotoPicker];
    return 0;
}

int gallery_get_next_id() {
  // TeaLeafAppDelegate *appDelegate = (TeaLeafAppDelegate*)[[UIApplication sharedApplication] delegate];
  // TeaLeafViewController *viewController = [appDelegate tealeafViewController];
  // [viewController showImagePickerForCamera];
	return 0;
}

