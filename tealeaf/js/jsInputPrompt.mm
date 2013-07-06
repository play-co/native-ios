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

#import "jsInputPrompt.h"
#import "jsMacros.h"
#include "platform/log.h"
#include "core/events.h"

// Reference to js_core object
static js_core *m_js = nil;

// Instance of the prompt view
static InputPromptView *m_view = nil;
static int32_t m_prompt_id = 0;


@implementation InputPromptView

+ (InputPromptView *) get {
	if (m_view == nil) {
		m_view = [InputPromptView alloc];
	}

	return m_view;
}

- (void) dealloc {
	self.inputPromptAlertView = nil;
	self.inputPromptTextField = nil;
	
	[super dealloc];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	// OK?
	if (buttonIndex == 1) {
		NSString *detailString = self.inputPromptTextField.text;
		NSString *evt = [NSString stringWithFormat: @"{\"name\":\"inputPromptSubmit\",\"id\":%d,\"text\":\"%@\"}", m_prompt_id, detailString];
		core_dispatch_event([evt UTF8String]);
		// NOTE: If JS engine is shutdown at this point core_dispatch_event will just drop the event, which is OK.

		NSLOG(@"{prompt} Alert text input entered: %@", detailString);
	} else {
		NSString *evt = [NSString stringWithFormat: @"{\"name\":\"inputPromptCancel\",\"id\":%d}", m_prompt_id];
		core_dispatch_event([evt UTF8String]);

		NSLOG(@"{prompt} Alert text input cancelled");
	}
}

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message value:(NSString*)value autoShowKeyboard:(BOOL)autoShowKeyboard isPassword:(BOOL)isPassword {
	
	// TODO: autoShowKeyboard

	if (!title || [title length] <= 0) {
		title = @"	";
	}

	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message: message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *textField = [alert textFieldAtIndex:0];
	textField.delegate = self;
	textField.placeholder = @"";
	textField.text = value;
	textField.textAlignment = UITextAlignmentCenter;
	textField.keyboardAppearance = UIKeyboardAppearanceAlert;
	
	if (isPassword) {
		textField.secureTextEntry = YES;
	}
		
	[alert addSubview:textField];
	[alert show];
	
	[textField becomeFirstResponder];
	
	self.inputPromptTextField = textField;
	self.inputPromptAlertView = alert;}

@end


JSAG_MEMBER_BEGIN(show, 5)
{
	JSAG_ARG_NSTR(title);
	JSAG_ARG_NSTR(msg);
	JSAG_ARG_NSTR(value);
	JSAG_ARG_BOOL(autoShowKeyboard);
	JSAG_ARG_BOOL(isPassword);

	++m_prompt_id;

	[[InputPromptView get] showAlertViewWithTitle:title message:msg value:value autoShowKeyboard:autoShowKeyboard isPassword:isPassword];

	JSAG_RETURN_INT32(m_prompt_id);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(inputPrompt)
JSAG_OBJECT_MEMBER(show)
JSAG_OBJECT_END


@implementation jsInputPrompt

+ (void) addToRuntime:(js_core *)js {
	m_js = js;

	JSAG_OBJECT_ATTACH(js.cx, js.native, inputPrompt);
}

+ (void) onDestroyRuntime {
	if (m_js) {
		InputPromptView *instance = [InputPromptView get];

		if (instance) {
			[instance.inputPromptAlertView dismissWithClickedButtonIndex:0 animated:FALSE];
		}
	}
	
	m_js = nil;
}

@end
