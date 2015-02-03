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

	JS::RootedValue el(cx);
	for (int i = 0; i < cbCount; ++i) {
		JS_GetElement(cx, cbs, i, &el);
		JS::ToInt32(cx, el, &callbacks[i]);
	}

	for (int i = 0; i < buttonCount; ++i) {
		JS_GetElement(cx, btns, i, &el);
		JS::RootedString str(cx, JS::ToString(cx, el));
		buttons[i] = JS_EncodeStringToUTF8(cx, str);
	}

	dialog_show_dialog(title, text, image, buttons, buttonCount, callbacks, cbCount);

	for (int i = 0; i != buttonCount; i++) {
		// Need to JS_free things returned from JS_EncodeString*
		JS_free(cx, buttons[i]);
	}

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
