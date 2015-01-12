//
//  TeaLeafTextField.h
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/26/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "js/js_core.h"

@interface TeaLeafTextFieldDelegate : NSObject<UITextFieldDelegate>
@property (nonatomic) int maxLength;
@end

@interface TeaLeafTextField : UITextField
@property (nonatomic) int cursorPos;
@property (nonatomic) bool autoClose;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, retain) UIColor *_placeholderColor;
@property (nonatomic, retain) TeaLeafTextFieldDelegate *textFieldDelegate;
- (void) gotoNextTextfield;
- (void) hide;
- (void) show;
- (void) submit;
@end

