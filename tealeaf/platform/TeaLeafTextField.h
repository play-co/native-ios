//
//  TeaLeafTextField.h
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/26/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "js/js_core.h"

@interface TeaLeafTextField : UITextField
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, retain) UIColor *_placeholderColor;

@end
