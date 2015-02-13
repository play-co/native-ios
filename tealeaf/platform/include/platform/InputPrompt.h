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
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface InputPrompt : NSObject <UIAlertViewDelegate, UITextFieldDelegate> {
	NSString *currVal;
	NSString *hint;
	NSString *inputType;
    NSString *inputReturnButton;
	int maxLength;

	UITapGestureRecognizer *tapGestureRecognizer;

}

@property (nonatomic, retain) UIAlertView *inputPromptAlertView;
@property (nonatomic, retain) UITextField *inputPromptTextField;

@property (nonatomic, retain) NSString *currVal;
@property (nonatomic, retain) NSString *inputType;
@property (nonatomic, retain) NSString *inputReturnButton;
@property (nonatomic, retain) NSString *hint;
@property (nonatomic) int maxLength;
@property (nonatomic) int cursorPos;

@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (int32_t) showAlertViewWithTitle:(NSString*)title
                           message:(NSString*)message
                            okText:(NSString*)okText
                        cancelText:(NSString*)cancelText
                             value:(NSString*)value
                  autoShowKeyboard:(BOOL)autoShowKeyboard
                        isPassword:(BOOL)isPassword
                      keyboardType:(int)keyboardType
                      returnButton:(NSString*)returnButton;

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+ (InputPrompt *) get;

@end
