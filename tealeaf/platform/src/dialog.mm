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

#include "platform.h"
#include "dialog.h"
#import "TeaLeafViewController.h"

void dialog_show_dialog(const char* title, const char* text, const char* image, char** buttons, int buttonLen, int* cbs, int cbLen) {
	// TODO subclass UIActionSheet
	TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
	UIAlertViewEx* dialog = [[[UIAlertViewEx alloc] initWithTitle: [NSString stringWithUTF8String:title] message: [NSString stringWithUTF8String: text] delegate:controller cancelButtonTitle: nil otherButtonTitles:nil] autorelease];
	[dialog registerCallbacks: cbs length: cbLen];
	for(int i = 0; i < buttonLen; i++) {
		[dialog addButtonWithTitle: [NSString stringWithUTF8String: buttons[i]]];
	}
	[dialog show];
}
