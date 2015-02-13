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

#import "js/jsTextInput.h"
#import "TextInputManager.h"


JSAG_MEMBER_BEGIN(destroy, 1)
{
	JSAG_ARG_INT32(idi);
	
	[[TextInputManager get] destroyTextInputWithId:idi];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(create, 5)
{
	JSAG_ARG_INT32(x);
	JSAG_ARG_INT32(y);
	JSAG_ARG_INT32(width);
	JSAG_ARG_INT32(height);
	JSAG_ARG_NSTR(text);

	int32_t idi = [[TextInputManager get] addTextInputAtX:x Y:y width:width height:height text:text];

	JSAG_RETURN_INT32(idi);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(show, 1)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		input.hidden = NO;
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(hide, 1)
{
	JSAG_ARG_INT32(idi);
	
	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		input.hidden = YES;
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setPosition, 3)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_INT32(x);
		JSAG_ARG_INT32(y);

		[input setX:x andY:y];
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setDimensions, 3)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_INT32(width);
		JSAG_ARG_INT32(height);

		[input setWidth:width andHeight:height];
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setValue, 2)
{
	JSAG_ARG_INT32(idi);
	
	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_NSTR(text);

		[input setText:text];
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setOpacity, 2)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_DOUBLE(opacity);

		input.alpha = opacity;
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setType, 2)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_NSTR(type);

		BOOL secureTextEntry = NO;
		UIKeyboardType keyboardType = UIKeyboardTypeDefault;

		switch ([type characterAtIndex:0]) {
			case 't': // tel, time
				if ([type length] == 4) {
					// Time
					keyboardType = UIKeyboardTypeNumbersAndPunctuation;
				} else {
					// Phone
					keyboardType = UIKeyboardTypePhonePad;
				}
				break;
			case 'u': // url
				// URI
				keyboardType = UIKeyboardTypeURL;
				break;
			case 'e': // email
				// Email
				keyboardType = UIKeyboardTypeEmailAddress;
				break;
			case 'p': // password
				// Password
				secureTextEntry = YES;
				break;
			case 'n': // number
				// Number
				keyboardType = UIKeyboardTypeNumberPad;
				break;
			case 'r': // range
				// Range
				keyboardType = UIKeyboardTypeNumbersAndPunctuation;
				break;
			default:;
				//case 's': // search
				// Auto Correct
				//	break;
				//case 'd': // date, datetime
				//	if (type_cstr_len == 4) {
				// Date
				// TODO: Use DatePicker?
				//	} else {
				// Datetime
				// TODO: Use DatePicker?
				//	}
				break;
		}

		// Set mode
		input.secureTextEntry = secureTextEntry;
		input.keyboardType = keyboardType;
		input.type = type;
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setVisible, 2)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (likely(!!input)) {
		JSAG_ARG_BOOL(visible);

		input.hidden = visible ? FALSE : TRUE;
	}
}
JSAG_MEMBER_END

#define TEXT_INPUT_DOUBLE_GETTER(name, default, field) \
JSAG_MEMBER_BEGIN(name, 1) \
{ \
	JSAG_ARG_INT32(idi); \
	double rval = default; \
	TextInput *input = [[TextInputManager get] getTextInputWithId:idi]; \
	if (likely(!!input)) { \
		rval = field; \
	} \
	JSAG_RETURN_DOUBLE(rval); \
} \
JSAG_MEMBER_END

TEXT_INPUT_DOUBLE_GETTER(getX, 0, input.frame.origin.x);
TEXT_INPUT_DOUBLE_GETTER(getY, 0, input.frame.origin.y);
TEXT_INPUT_DOUBLE_GETTER(getWidth, 0, input.frame.size.width);
TEXT_INPUT_DOUBLE_GETTER(getHeight, 0, input.frame.size.height);
TEXT_INPUT_DOUBLE_GETTER(getOpacity, 1, input.alpha);

JSAG_MEMBER_BEGIN(getValue, 1)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (unlikely(!input)) {
		JSAG_RETURN_NULL;
	} else {
		JSAG_RETURN_NSTR(input.text);
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(getType, 1)
{
	JSAG_ARG_INT32(idi);

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (unlikely(!input)) {
		JSAG_RETURN_CSTR("normal");
	} else {
		JSAG_RETURN_NSTR(input.type);
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(getVisible, 1)
{
	JSAG_ARG_INT32(idi);

	JSAG_BOOL visible = JSAG_FALSE;

	TextInput *input = [[TextInputManager get] getTextInputWithId:idi];
	if (unlikely(!!input)) {
		if (!input.hidden) {
			visible = JSAG_TRUE;
		}
	}

	JSAG_RETURN_BOOL(visible);
}
JSAG_MEMBER_END


JSAG_OBJECT_START(textbox)
JSAG_OBJECT_MEMBER(create)
JSAG_OBJECT_MEMBER(destroy)
JSAG_OBJECT_MEMBER(show)
JSAG_OBJECT_MEMBER(hide)
JSAG_OBJECT_MEMBER(setPosition)
JSAG_OBJECT_MEMBER(setDimensions)
JSAG_OBJECT_MEMBER(setValue)
JSAG_OBJECT_MEMBER(setOpacity)
JSAG_OBJECT_MEMBER(setType)
JSAG_OBJECT_MEMBER(setVisible)
JSAG_OBJECT_MEMBER(getX)
JSAG_OBJECT_MEMBER(getY)
JSAG_OBJECT_MEMBER(getWidth)
JSAG_OBJECT_MEMBER(getHeight)
JSAG_OBJECT_MEMBER(getValue)
JSAG_OBJECT_MEMBER(getOpacity)
JSAG_OBJECT_MEMBER(getType)
JSAG_OBJECT_MEMBER(getVisible)
JSAG_OBJECT_END


@implementation jsTextInput

+ (void) addToRuntime:(js_core *)js withSuperView:(UIView *)view {
	[TextInputManager setSuperView:view];

	JSAG_OBJECT_ATTACH(js.cx, js.native, textbox);
}

+ (void) onDestroyRuntime {
	[[TextInputManager get] destroyAll];
}

@end
