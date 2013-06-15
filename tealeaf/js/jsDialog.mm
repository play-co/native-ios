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

#import "js/jsDialog.h"
#include "dialog.h"

JSAG_MEMBER_BEGIN(_showDialog, 5)
{
	JSAG_ARG_CSTR(title);
	JSAG_ARG_CSTR(text);
	JSAG_ARG_CSTR(image);
	JSAG_ARG_OBJECT(btns);
	JSAG_ARG_OBJECT(cbs);

	uint32_t buttonCount, cbCount;
	JS_GetArrayLength(cx, btns, &buttonCount);
	JS_GetArrayLength(cx, cbs, &cbCount);
	
	char **buttons = (char**)malloc(buttonCount * sizeof(char*));
	int *callbacks = (int*)malloc(cbCount * sizeof(int));
	
	for (int i = 0; i < cbCount; ++i) {
		jsval el;
		JS_GetElement(cx, cbs, i, &el);
		callbacks[i] = JSVAL_TO_INT(el);
	}
	
	for (int i = 0; i < buttonCount; ++i) {
		jsval el;
		JS_GetElement(cx, btns, i, &el);
		buttons[i] = JS_EncodeString(cx, JSVAL_TO_STRING(el));
	}
	
	dialog_show_dialog(title, text, image, buttons, buttonCount, callbacks, cbCount);
	
	free(buttons);
	free(callbacks);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(dialogs)
JSAG_OBJECT_MEMBER(_showDialog)
JSAG_OBJECT_END


@implementation jsDialog

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, dialogs);
}

+ (void) onDestroyRuntime {
	
}

@end
