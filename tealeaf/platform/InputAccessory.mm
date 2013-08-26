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

//
//  jsInputAccessory.m
//  TeaLeafIOS
//
//  Created by Martin Hunt on 8/13/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "InputAccessory.h"
#import "InputUtils.h"
#include "platform/log.h"
#include "core/events.h"
#include "TeaLeafViewController.h"
#import <QuartzCore/QuartzCore.h>

// Instance of the prompt view
static InputAccessory *m_view = nil;

@implementation InputAccessory

@synthesize inputAccView;
@synthesize inputAccBtnPrev;
@synthesize inputAccBtnNext;
@synthesize inputAccBtnDone;
@synthesize inputAccTextField;

@synthesize currVal;
@synthesize inputType;
@synthesize inputReturnButton;
@synthesize hint;
@synthesize hasForward;
@synthesize hasBackward;
@synthesize maxLength;
@synthesize cursorPos;

@synthesize tapGestureRecognizer;

+ (InputAccessory *) get {
	if (m_view == nil) {
		m_view = [InputAccessory alloc];
		m_view.inputAccTextField = NULL;
	}
    
	return m_view;
}

- (void) dealloc {
	self.inputPromptAlertView = nil;
	self.inputPromptTextField = nil;
    
	[super dealloc];
}

- (void) createInputAccessoryView {
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
    
    inputAccBtnDone = [UIButton buttonWithType:UIButtonTypeCustom];
    [inputAccBtnDone setFrame:CGRectMake(width - 70, 10.0f, 60, 30.0f)];
    [inputAccBtnDone setBackgroundImage:[UIImage imageNamed:@"done_button"] forState:UIControlStateNormal];
    [inputAccBtnDone setBackgroundImage:[UIImage imageNamed:@"done_button_pressed"] forState:UIControlStateHighlighted];
    [inputAccBtnDone addTarget:self action:@selector(doneTyping) forControlEvents:UIControlEventTouchUpInside];
    [inputAccView addSubview:inputAccBtnDone];
    
    inputAccBtnPrev = [UIButton buttonWithType: UIButtonTypeCustom];
    [inputAccBtnPrev setFrame: CGRectMake(width - 70, 10.0, 30, 30.0)];
    [inputAccBtnPrev addTarget: self action: @selector(gotoPrevTextfield) forControlEvents: UIControlEventTouchUpInside];
    
    inputAccBtnNext = [UIButton buttonWithType:UIButtonTypeCustom];
    [inputAccBtnNext setFrame:CGRectMake(width - 40, 10.0f, 30, 30.0f)];
    [inputAccBtnNext addTarget:self action:@selector(gotoNextTextfield) forControlEvents:UIControlEventTouchUpInside];
    
    
    [inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_handler"] forState:UIControlStateNormal];
    [inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_handler_pressed"] forState:UIControlStateHighlighted];
    [inputAccBtnPrev setBackgroundImage:[UIImage imageNamed:@"left_text_handler_disabled"] forState:UIControlStateDisabled];
    
    
    [inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_handler"] forState:UIControlStateNormal];
    [inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_handler_pressed"] forState:UIControlStateHighlighted];
    [inputAccBtnNext setBackgroundImage:[UIImage imageNamed:@"right_text_handler_disabled"] forState:UIControlStateDisabled ];
    
    [inputAccView addSubview:inputAccBtnPrev];
    [inputAccView addSubview:inputAccBtnNext];
    [inputAccView addSubview:inputAccTextField];
}

- (void) updateInputAccessoryView {
	if (inputAccTextField == NULL) {
        [self createInputAccessoryView];
	}
	
    if (!hasBackward && !hasForward) {
        [inputAccBtnDone setHidden:NO];
        [inputAccBtnNext setHidden:YES];
        [inputAccBtnPrev setHidden:YES];
    } else {
        [inputAccBtnDone setHidden:YES];
        [inputAccBtnNext setHidden:NO];
        [inputAccBtnPrev setHidden:NO];
        [inputAccBtnPrev setEnabled:hasBackward];
        [inputAccBtnNext setEnabled:hasForward];
    }
    
	inputAccTextField.text = currVal;
	inputAccTextField.placeholder = hint;
    
    [InputUtils setKeyboardType:inputType forTextField:inputAccTextField];
    [InputUtils setKeyboardReturnType:inputReturnButton forTextField:inputAccTextField];
    if (inputAccTextField.returnKeyType == UIReturnKeyDefault && hasForward) {
        inputAccTextField.returnKeyType = UIReturnKeyNext;
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
    
	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputKeyboardKeyUp\",\"text\":\"%@\"}", [textField.text stringByReplacingCharactersInRange:range withString:string]];
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
        [self submit];
        return YES;
    }
}


-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField != inputAccTextField) {
        [textField setInputAccessoryView:inputAccView];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
}

-(void)gotoPrevTextfield {
    NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputKeyboardFocusNext\",\"next\":%@}", @"false"];
    core_dispatch_event([evt UTF8String]);
}

-(void)gotoNextTextfield {
    NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputKeyboardFocusNext\",\"next\":%@}", @"true"];
    core_dispatch_event([evt UTF8String]);
}

// called when the done button is pressed
-(void)doneTyping {
    [self submit];
}

-(void)submit {
    NSString *evt = [NSString stringWithFormat: @"{\"name\":\"InputKeyboardSubmit\"}"];
    core_dispatch_event([evt UTF8String]);
    [self hide];
}

- (void) show {
    
	TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
	[self updateInputAccessoryView];
	controller.inputAccTextField.delegate = self;
	[controller.inputAccTextField becomeFirstResponder];
    
    if (tapGestureRecognizer == nil) {
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(hide)];
    }
    [controller.view addGestureRecognizer:tapGestureRecognizer];
    
	//switch first responder to the view on the input accessory view
	[inputAccTextField becomeFirstResponder];
    
}

- (void) hide {
    TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller.view removeGestureRecognizer:tapGestureRecognizer];
    
    [controller.inputAccTextField endEditing:YES];
    [inputAccTextField endEditing:YES];
    [controller.inputAccTextField endEditing:YES];
    [inputAccTextField endEditing:YES];
}

@end
