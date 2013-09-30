//
//  TeaLeafTextField.m
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/26/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "TeaLeafTextField.h"
#import "TeaLeafViewController.h"
#import "NativeCalls.h"
#import "FontUtil.h"
#import <QuartzCore/QuartzCore.h>

@implementation TeaLeafTextField
@synthesize tapGestureRecognizer;
@synthesize _placeholderColor;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self setFrame:CGRectMake(0, 0, 0, 0)];
        tapGestureRecognizer = nil;
        
        [NativeCalls Register:@"editText.focus" withCallback:^NSMutableDictionary *(NSMutableDictionary *dict) {
            float scale = 1.f;
            if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
                && [[UIScreen mainScreen] scale] == 2.0) {
                scale = .5f;
            }
            //position and size
            [self setFrame:CGRectMake(scale * [[dict objectForKey:@"x"] floatValue],
                                      scale * [[dict objectForKey:@"y"] floatValue],
                                      scale * [[dict objectForKey:@"width"] floatValue],
                                      scale * [[dict objectForKey:@"height"] floatValue])];
            

            
            //font properties
            NSString * font = [dict objectForKey:@"font"];
            NSString *fontName = [FontUtil fixFontName: [font UTF8String]];
            float fontSize = [[dict objectForKey:@"fontSize"] floatValue] * scale;
            UIColor *fontColor = [self colorFromHexString:[dict objectForKey:@"fontColor"]];
            
            [self setFont:[UIFont fontWithName:fontName size:fontSize]];
            [self setTextColor:fontColor];
            
            //hint
            [self setPlaceholder:[dict objectForKey:@"hint"]];
            [self setPlaceholderColor:[self colorFromHexString:[dict objectForKey:@"hintColor"]]];
            
        
            //left and right padding
            UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[dict objectForKey:@"paddingLeft"] floatValue], 0)];
            self.leftView = paddingView;
            self.leftViewMode = UITextFieldViewModeAlways;
            
            paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[dict objectForKey:@"paddingRight"] floatValue], 0)];
            self.rightView = paddingView;
            self.rightViewMode = UITextFieldViewModeAlways;

            
            [self setHidden:false];
            [self becomeFirstResponder];
            return nil;
        }];
        
        //defaults
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self._placeholderColor = [UIColor blackColor];
        [self setHidden:true];
    }
    return self;
}


- (void) setPlaceholderColor:(UIColor*) color {
    self._placeholderColor = color;
}

- (void) drawPlaceholderInRect:(CGRect)rect {
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [[self _placeholderColor] setFill];
    [[self placeholder] drawInRect:rect withFont:self.font];
}

// Assumes input like "#00FF00" (#RRGGBB).
-  (UIColor *) colorFromHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.f];
}

- (void) hide {

}


- (void) show {
    
}

- (void) clearFocus {
    TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller.view removeGestureRecognizer:tapGestureRecognizer];
    tapGestureRecognizer = nil;
    [self endEditing:true];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
