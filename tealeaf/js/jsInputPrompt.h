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
#import "js/js_core.h"


@interface InputPromptView : NSObject <UIAlertViewDelegate, UITextFieldDelegate> {
	UIView *inputAccView;
	UIButton *inputAccBtnDone;
	UIButton *inputAccBtnNext;
	UIButton *inputAccBtnPrev;
	UITextField *inputAccTextField;

	NSString *currVal;
	NSString *hint;
	bool hasBackward;
	bool hasForward;
	NSString *inputType;
	int maxLength;

	UITapGestureRecognizer *tapGestureRecognizer;

}

@property (nonatomic, retain) UIAlertView *inputPromptAlertView;
@property (nonatomic, retain) UITextField *inputPromptTextField;
@property (nonatomic, retain) UIView *inputAccView;
@property (nonatomic, retain) UIButton *inputAccBtnDone;
@property (nonatomic, retain) UIButton *inputAccBtnNext;
@property (nonatomic, retain) UIButton *inputAccBtnPrev;
@property (nonatomic, retain) UITextField *inputAccTextField;

@property (nonatomic, retain) NSString *currVal;
@property (nonatomic, retain) NSString *inputType;
@property (nonatomic, retain) NSString *hint;
@property (nonatomic) bool hasBackward;
@property (nonatomic) bool hasForward;
@property (nonatomic) int maxLength;

@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message value:(NSString*)value autoShowKeyboard:(BOOL)autoShowKeyboard isPassword:(BOOL)isPassword keyboardType: (int) keyboardType;

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+ (InputPromptView *) get;

@end


@interface jsInputPrompt : NSObject

+ (void) addToRuntime:(js_core *)js;
+ (void) onDestroyRuntime;

@end
