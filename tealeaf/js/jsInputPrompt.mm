/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.	 If not, see <http://www.gnu.org/licenses/>.
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

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message value:(NSString*)value autoShowKeyboard:(BOOL)autoShowKeyboard {
	
	// TODO: autoShowKeyboard

	if (!title || [title length] <= 0) {
		title = @"	";
	}

	UITextField *textField = [[[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)] autorelease];
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:[NSString stringWithFormat:@"\n\n%@",message,nil] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];
	
	textField.delegate = self;
	textField.borderStyle = UITextBorderStyleLine;
	textField.font = [UIFont fontWithName:@"Helvetica" size:20];
	textField.placeholder = @"";
	textField.text = value;
	textField.textAlignment = UITextAlignmentCenter;
	textField.keyboardAppearance = UIKeyboardAppearanceAlert;
	
	[textField setBackgroundColor:[UIColor whiteColor]];
	
	[alert addSubview:textField];
	[alert show];
	
	[textField becomeFirstResponder];
	
	self.inputPromptTextField = textField;
	self.inputPromptAlertView = alert;}

@end


JSAG_MEMBER_BEGIN(show, 4)
{
	JSAG_ARG_NSTR(title);
	JSAG_ARG_NSTR(msg);
	JSAG_ARG_NSTR(value);
	JSAG_ARG_BOOL(autoShowKeyboard);

	++m_prompt_id;

	[[InputPromptView get] showAlertViewWithTitle:title message:msg value:value autoShowKeyboard:autoShowKeyboard];

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
