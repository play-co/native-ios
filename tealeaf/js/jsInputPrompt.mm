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
#include "TeaLeafViewController.h"
#import <QuartzCore/QuartzCore.h>

// Reference to js_core object
static js_core *m_js = nil;

// Instance of the prompt view
static InputPromptView *m_view = nil;
static int32_t m_prompt_id = 0;
static UITextField *textField;

static NSString *INPUTTYPE_DEFAULT = @"DEFAULT";
static NSString *INPUTTYPE_NUMBER = @"NUMBER";
static NSString *INPUTTYPE_PHONE = @"PHONE";
static NSString *INPUTTYPE_PASSWORD = @"PASSWORD";
static NSString *INPUTTYPE_CAPITAL = @"CAPITAL";


@implementation InputPromptView

@synthesize inputAccView;
@synthesize inputAccBtnPrev;
@synthesize inputAccBtnNext;
@synthesize inputAccBtnDone;
@synthesize inputAccTextField;

@synthesize currVal;
@synthesize inputType;
@synthesize hint;
@synthesize hasForward;
@synthesize hasBackward;
@synthesize maxLength;

@synthesize tapGestureRecognizer;

+ (InputPromptView *) get {
	if (m_view == nil) {
		m_view = [InputPromptView alloc];
		m_view.inputAccTextField = NULL;
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

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message value:(NSString*)value autoShowKeyboard:(BOOL)autoShowKeyboard isPassword:(BOOL)isPassword keyboardType: (int) keyboardType {

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
	textField.keyboardType = keyboardType;


	if (isPassword) {
		textField.secureTextEntry = YES;
	}

	[alert addSubview:textField];
	[alert show];

	[textField becomeFirstResponder];

	self.inputPromptTextField = textField;
	self.inputPromptAlertView = alert;
}

-(void)createInputAccessoryView {
	if (inputAccTextField == NULL) {
		TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
		float width = controller.view.bounds.size.width;
		float height = 50;
		inputAccView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];

		[inputAccView setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1.0]];

		//add a top border
		CALayer *topBorder = [CALayer layer];
		topBorder.frame = CGRectMake(0.0f, 0.0f, inputAccView.frame.size.width, 1.0f);
		topBorder.backgroundColor = [UIColor grayColor].CGColor;
		[inputAccView.layer addSublayer:topBorder];

		inputAccTextField = [[UITextField alloc] initWithFrame:CGRectMake(5, 5, width - 80, height - 10)];

		[inputAccTextField setBorderStyle:UITextBorderStyleRoundedRect];
		UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, height - 10)];
		inputAccTextField.leftView = paddingView;
		inputAccTextField.leftViewMode = UITextFieldViewModeAlways;
		[inputAccTextField.font fontWithSize:height - 10];
		inputAccTextField.delegate = self;
		inputAccTextField.backgroundColor = [UIColor whiteColor];
		inputAccTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

		if (!hasBackward && !hasForward) {
			inputAccBtnDone = [UIButton buttonWithType:UIButtonTypeCustom];
			[inputAccBtnDone setFrame:CGRectMake(width - 70, 10.0f, 60, 30.0f)];
			[inputAccBtnDone setTitle:@"Done" forState:UIControlStateNormal];
			[inputAccBtnDone setBackgroundColor:[UIColor greenColor]];
			[inputAccBtnDone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
			[inputAccBtnDone addTarget:self action:@selector(doneTyping) forControlEvents:UIControlEventTouchUpInside];
			[inputAccView addSubview:inputAccBtnDone];
		} else {
			if (hasForward) {
				inputAccTextField.returnKeyType = UIReturnKeyNext;
			}
			inputAccBtnPrev = [UIButton buttonWithType: UIButtonTypeCustom];
			[inputAccBtnPrev setFrame: CGRectMake(width - 70, 10.0, 30, 30.0)];
			[inputAccBtnPrev addTarget: self action: @selector(gotoPrevTextfield) forControlEvents: UIControlEventTouchUpInside];

			inputAccBtnNext = [UIButton buttonWithType:UIButtonTypeCustom];
			[inputAccBtnNext setFrame:CGRectMake(width - 40, 10.0f, 30, 30.0f)];
			[inputAccBtnNext setTitle:@"Next" forState:UIControlStateNormal];

			[inputAccBtnNext addTarget:self action:@selector(gotoNextTextfield) forControlEvents:UIControlEventTouchUpInside];


			[inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_handler"] forState:UIControlStateNormal];
			[inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_pressed"] forState:UIControlStateSelected];
			[inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_disabled"] forState:UIControlStateDisabled];


			[inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_handler"] forState:UIControlStateNormal];
			[inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_pressed"] forState:UIControlStateSelected];
			[inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_disabled"] forState:UIControlStateDisabled ];


			[inputAccView addSubview:inputAccBtnPrev];
			[inputAccView addSubview:inputAccBtnNext];

		}

		[inputAccView addSubview:inputAccTextField];
	}
	[inputAccBtnPrev setEnabled:hasBackward];
	[inputAccBtnNext setEnabled:hasForward];

	inputAccTextField.text = currVal;
	inputAccTextField.placeholder = hint;
	//Set keyboard and input type
	NSString *inputTypeUpper = [inputType uppercaseString];


	if ([inputTypeUpper isEqualToString:INPUTTYPE_NUMBER]) {
		inputAccTextField.keyboardType = UIKeyboardTypeNumberPad;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_PHONE]) {
		inputAccTextField.keyboardType = UIKeyboardTypePhonePad;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_PASSWORD]) {
		inputAccTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		inputAccTextField.keyboardType = UIKeyboardTypeDefault;
		inputAccTextField.secureTextEntry = YES;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_CAPITAL]) {
		inputAccTextField.keyboardType = UIKeyboardTypeDefault;
		inputAccTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	} else {
		inputAccTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		inputAccTextField.keyboardType = UIKeyboardTypeDefault;
	}
	[inputAccTextField reloadInputViews];

}


//This delegate is called everytime a character is inserted in an UITextfield.
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{

	//if we are greater than maxlength allows for this textfield, return and
	//do not process
	NSUInteger newLength = [textField.text length] + [string length] - range.length;
	if (newLength > self.maxLength) {
		return NO;
	}

	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"inputPromptKeyUp\",\"text\":\"%@\"}", [textField.text stringByReplacingCharactersInRange:range withString:string]];
	core_dispatch_event([evt UTF8String]);

	//Returning yes allows the entered chars to be processed
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.returnKeyType == UIReturnKeyNext) {
		[self gotoNextTextfield];
		return NO;
	} else {
		[self hideSoftKeyboard];
		return YES;
	}
}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
	[textField setInputAccessoryView:inputAccView];

}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == inputAccTextField) {
		[inputAccTextField resignFirstResponder];
		inputAccTextField = NULL;
	}
}


-(void)gotoPrevTextfield{
	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"inputPromptMove\",\"next\":%@}", @"false"];
	core_dispatch_event([evt UTF8String]);
}

-(void)gotoNextTextfield{
	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"inputPromptMove\",\"next\":%@}", @"true"];
	core_dispatch_event([evt UTF8String]);
}

-(void)doneTyping{
	// When the "done" button is tapped, the keyboard should go away.
	// That simply means that we just have to resign our first responder.

	[self hideSoftKeyboard];
}


- (void) showSoftKeyboard {

	TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
	[self createInputAccessoryView];
	controller.inputAccTextField.delegate = self;
	[controller.inputAccTextField becomeFirstResponder];

	if (tapGestureRecognizer == nil) {
		tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
			action:@selector(hideSoftKeyboard)];
	}
	[controller.view addGestureRecognizer:tapGestureRecognizer];

	//switch first responder to the view on the input accessory view
	[inputAccTextField becomeFirstResponder];

}

- (void) hideSoftKeyboard {
	TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
	[controller.view removeGestureRecognizer:tapGestureRecognizer];
	[inputAccTextField endEditing:YES];
}

@end


JSAG_MEMBER_BEGIN(show, 5)
{
	JSAG_ARG_NSTR(title);
	JSAG_ARG_NSTR(msg);
	JSAG_ARG_NSTR(value);
	JSAG_ARG_BOOL(autoShowKeyboard);
	JSAG_ARG_BOOL(isPassword);
	JSAG_ARG_BOOL(keyboardType);

	++m_prompt_id;

	[[InputPromptView get] showAlertViewWithTitle:title message:msg value:value autoShowKeyboard:autoShowKeyboard isPassword:isPassword keyboardType: keyboardType];

	JSAG_RETURN_INT32(m_prompt_id);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(showSoftKeyboard, 6)
{
	JSAG_ARG_NSTR(currVal);
	JSAG_ARG_NSTR(hint);
	JSAG_ARG_BOOL(hasBackward);
	JSAG_ARG_BOOL(hasForward);
	JSAG_ARG_NSTR(inputType);
	JSAG_ARG_INT32(maxLength);

	InputPromptView *ip = [InputPromptView get];
	ip.hint = hint;
	ip.currVal = currVal;
	ip.inputType = inputType;
	ip.hasForward = hasForward;
	ip.hasBackward = hasBackward;
	ip.maxLength = maxLength;


	[[InputPromptView get] showSoftKeyboard];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(hideSoftKeyboard, 0)
{
	[[InputPromptView get] hideSoftKeyboard];
}
JSAG_MEMBER_END

	JSAG_OBJECT_START(inputPrompt)
	JSAG_OBJECT_MEMBER(show)
	JSAG_OBJECT_MEMBER(showSoftKeyboard)
JSAG_OBJECT_MEMBER(hideSoftKeyboard)
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
