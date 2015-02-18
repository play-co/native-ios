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

#import "InputPrompt.h"
#import "InputUtils.h"

#include "platform/log.h"
#include "core/events.h"
#include "TeaLeafViewController.h"
#import <QuartzCore/QuartzCore.h>

// Instance of the prompt view
static InputPrompt *m_view = nil;
static int32_t m_prompt_id = 0;

@implementation InputPrompt

@synthesize currVal;
@synthesize inputType;
@synthesize inputReturnButton;
@synthesize hint;
@synthesize maxLength;
@synthesize cursorPos;

@synthesize tapGestureRecognizer;

+ (InputPrompt *) get {
	if (m_view == nil) {
		m_view = [[InputPrompt alloc] init];
	}

	return m_view;
}

- (void) dealloc {
	self.inputPromptAlertView = nil;
	self.inputPromptTextField = nil;

	[super dealloc];
}

- (id) init {
    if ((self = [super init])) {
        maxLength = -1;
    }
    return self;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	// OK?
	if (buttonIndex == 0) {
        [self submit];
	} else {
		NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputKeyboardCancel\",\"id\":%d}", m_prompt_id];
		core_dispatch_event([evt UTF8String]);

		NSLOG(@"{prompt} Alert text input cancelled");
	}
}

- (void) submit {
    NSString *detailString = self.inputPromptTextField.text;
    NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputPromptSubmit\",\"id\":%d,\"text\":\"%@\"}", m_prompt_id, detailString];
    core_dispatch_event([evt UTF8String]);
    // NOTE: If JS engine is shutdown at this point core_dispatch_event will just drop the event, which is OK.

    NSLOG(@"{prompt} Alert text input entered: %@", detailString);
}

- (int32_t) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
                         okText:(NSString*)okText
                     cancelText:(NSString*)cancelText
                          value:(NSString*)value
               autoShowKeyboard:(BOOL)autoShowKeyboard
                     isPassword:(BOOL)isPassword
                   keyboardType:(int)keyboardType
                   returnButton:(NSString*)returnButton
{
  if (!title || [title length] <= 0) {
    title = @"	";
  }

  ++m_prompt_id;

  if (NSClassFromString(@"UIAlertController")) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:cancelText
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction* action) {
                                                           // TODO alert cancellation
                                                         }];

    UIAlertAction* acceptAction = [UIAlertAction actionWithTitle:okText
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction* action) {
                                                           [self submit];
                                                         }];
    [alert addAction:cancelAction];
    [alert addAction:acceptAction];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.delegate = self;
      textField.placeholder = @"";
      textField.keyboardType = (UIKeyboardType)keyboardType;
      textField.text = value;
      textField.textAlignment = (NSTextAlignment)UITextAlignmentCenter;
      [InputUtils setKeyboardReturnType:returnButton forTextField:textField];

      if (isPassword) {
        textField.secureTextEntry = YES;
      }
      [textField becomeFirstResponder];

      self.inputPromptTextField = textField;

    }];

    UIViewController* controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [controller presentViewController:alert animated:YES completion:^{
      // Do something when input prompt shows up?
    }];
  } else {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message: message delegate:self cancelButtonTitle:okText otherButtonTitles:cancelText, nil] autorelease];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.delegate = self;
    textField.placeholder = @"";
    textField.text = value;
    textField.textAlignment = (NSTextAlignment)UITextAlignmentCenter;
    textField.keyboardType = (UIKeyboardType)keyboardType;
      [InputUtils setKeyboardReturnType:returnButton forTextField:textField];

    if (isPassword) {
      textField.secureTextEntry = YES;
    }

    [alert addSubview:textField];
    [alert show];

    [textField becomeFirstResponder];

    self.inputPromptTextField = textField;
    self.inputPromptAlertView = alert;
  }


  return m_prompt_id;
}

//This delegate is called everytime a character is inserted in an UITextfield.
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  //if we are greater than maxlength allows for this textfield, return and
  //do not process
  NSUInteger newLength = [textField.text length] + [string length] - range.length;
  if (self.maxLength >= 0 && newLength > self.maxLength) {
    return NO;
  }

  NSString *evt = [NSString stringWithFormat:@"{\"name\":\"InputKeyboardKeyUp\",\"text\":\"%@\"}", [textField.text stringByReplacingCharactersInRange:range withString:string]];
  core_dispatch_event([evt UTF8String]);

  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self submit];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
}

@end

