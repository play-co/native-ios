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
#import "TeaLeafEvent.h"
#import "InputUtils.h"

@implementation TeaLeafTextFieldDelegate
@synthesize maxLength;

//This delegate is called everytime a character is inserted in an UITextfield.
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  
  //if we are greater than maxlength allows for this textfield, return and
  //do not process
  NSUInteger newLength = [textField.text length] + [string length] - range.length;
  if (maxLength > 0 && newLength > maxLength) {
    return NO;
  }
  
  [TeaLeafEvent Send:@"InputKeyboardKeyUp" withOpts:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     [textField.text stringByReplacingCharactersInRange:range withString:string], @"text", nil]];
  //Returning yes allows the entered chars to be processed
  return YES;
}

- (BOOL)textFieldShouldReturn:(TeaLeafTextField *)textField
{
  if (textField.returnKeyType == UIReturnKeyNext) {
    [textField gotoNextTextfield];
    return NO;
  } else {
    [textField submit];
    return YES;
  }
}

@end

@implementation TeaLeafTextField
@synthesize tapGestureRecognizer;
@synthesize _placeholderColor;
@synthesize textFieldDelegate;
@synthesize cursorPos;

- (id)init
{
  self = [super init];
  if (self) {
    // Initialization code
    [self setFrame:CGRectMake(0, 0, 0, 0)];
    tapGestureRecognizer = nil;
    self.textFieldDelegate = [[[TeaLeafTextFieldDelegate alloc] init] autorelease];
    
    self.autoClose = true;
    self.delegate = self.textFieldDelegate;
    
    [NativeCalls Register:@"editText.setText" withCallback:^NSMutableDictionary *(NSMutableDictionary *dict) {
      NSLOG(@"{textfield} got JS editText.setText");
      [self setText:[dict objectForKey:@"text"]];
      return nil;
    }];
    
    [NativeCalls Register:@"softKeyboard.setAutoClose" withCallback:^NSMutableDictionary *(NSMutableDictionary *dict) {
      NSLOG(@"{textfield} got JS softKeyboard.setAutoClose");
      self.autoClose = [[dict objectForKey:@"autoClose"] boolValue];
      return nil;
    }];
    
    [NativeCalls Register:@"editText.focus" withCallback:^NSMutableDictionary *(NSMutableDictionary *dict) {
      NSLOG(@"{textfield} got JS editText.focus");
      
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
      
      [self setText:[dict objectForKey:@"text"]];
      
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
      UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[dict objectForKey:@"paddingLeft"] floatValue] * scale, 0)];
      self.leftView = paddingView;
      self.leftViewMode = UITextFieldViewModeAlways;
      
      paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[dict objectForKey:@"paddingRight"] floatValue] * scale, 0)];
      self.rightView = paddingView;
      self.rightViewMode = UITextFieldViewModeAlways;
      
      if (tapGestureRecognizer == nil) {
        NSLOG(@"tap gesture recognizer is nil");
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(finishEditing)];
      }
      TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
      [controller.view addGestureRecognizer:tapGestureRecognizer];
      
      [InputUtils setKeyboardType:[dict objectForKey:@"inputType"] forTextField:self];
      [InputUtils setKeyboardReturnType:[dict objectForKey:@"inputReturnType"] forTextField:self];
      
      bool hasForward = [[dict objectForKey:@"hasForward"] boolValue];
      if (self.returnKeyType == UIReturnKeyDefault && hasForward) {
        self.returnKeyType = UIReturnKeyNext;
      }
      
      textFieldDelegate.maxLength = [[dict objectForKey:@"maxLength"] intValue];
      cursorPos = [[dict objectForKey:@"cursorPos"] intValue];
      
      [self setHidden:false];
      [self becomeFirstResponder];
      return nil;
    }];
    
    [NativeCalls Register:@"editText.clearFocus" withCallback:^NSMutableDictionary *(NSMutableDictionary *dict) {
      NSLOG(@"{textfield} got JS clearFocus");
      [self clearFocus];
      [self setHidden:true];
      return nil;
    }];
    
    //defaults
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self._placeholderColor = [UIColor blackColor];
    [self setHidden:true];
    NSLOG(@"{textfield} set defaults");
  }
  return self;
}

- (void) next {
  NSLOG(@"{textfield} next");
  switch (self.returnKeyType) {
    case UIReturnKeyNext:
      [self gotoNextTextfield];
      break;
    case UIReturnKeyDefault: case UIReturnKeyDone: default:
      [self hide];
      break;
  }
}

-(void)gotoPrevTextfield {
  [TeaLeafEvent Send:@"InputKeyboardFocusNext"
            withOpts: [NSMutableDictionary dictionaryWithObjectsAndKeys:@false, @"next", nil]];
}

-(void)gotoNextTextfield {
  [TeaLeafEvent Send:@"InputKeyboardFocusNext"
            withOpts: [NSMutableDictionary dictionaryWithObjectsAndKeys:@true, @"next", nil]];
}

- (void) setPlaceholderColor:(UIColor*) color {
  self._placeholderColor = color;
}

- (CGRect) placeholderRectForBounds:(CGRect)bounds {
  NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
  if ([[vComp objectAtIndex:0] intValue] >= 7) {
    CGRect b = [self editingRectForBounds:bounds];
    b.origin.y += b.size.height / 4;
    return b;
  } else {
    return [super placeholderRectForBounds:bounds];
  }
}

/*
 - (void) drawTextInRect:(CGRect)rect {
 
 self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
 int height = getTextHeight(self.font.familyName, self.font.pointSize, self.text);
 rect.origin.x = rect.origin.x + (self.bounds.size.height - height) / 2;
 
 [[self text] drawInRect:rect withFont:self.font];
 }*/

int getTextHeight(NSString *font, int size, NSString * text) {
  
  if (font != nil) {
    CGSize fontSize = [text sizeWithFont: [UIFont fontWithName:font size:size]];
    return fontSize.height;
  } else {
    return 0;
  }
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

- (void) submit {
  NSLOG(@"{textfield} submit");
  if (self.autoClose) {
    [self clearFocus];
    [TeaLeafEvent Send:@"InputKeyboardSubmit" withOpts:[NSMutableDictionary dictionaryWithObjectsAndKeys:@0, @"id", [self text], @"text", @YES, @"close", nil]];
  } else {
    [TeaLeafEvent Send:@"InputKeyboardSubmit" withOpts:[NSMutableDictionary dictionaryWithObjectsAndKeys:@0, @"id", [self text], @"text", @NO, @"close", nil]];
  }
}

- (void) finishEditing {
  NSLOG(@"{textfield} finishEditing");
  if (self.autoClose) {
    [self clearFocus];
    [TeaLeafEvent Send:@"editText.onFinishEditing" withOpts:nil];
  }
}

- (void) hide {
  NSLOG(@"{textfield} hide");
  [self clearFocus];
}

- (void) show {
}

- (void) clearFocus {
  NSLOG(@"{textfield} clearFocus");
  [self setHidden:true];
  TeaLeafViewController* controller = (TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
  [controller.view removeGestureRecognizer:tapGestureRecognizer];
  tapGestureRecognizer = nil;
  [self endEditing:true];
}

@end

