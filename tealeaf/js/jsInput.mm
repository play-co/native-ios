//
//  jsInput.mm
//  TeaLeafIOS
//
//  Created by Martin Hunt on 8/13/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "jsInput.h"
#import "jsMacros.h"

#import "platform/InputAccessory.h"
#import "platform/InputPrompt.h"
#include "platform/log.h"

static js_core *m_js;

JSAG_MEMBER_BEGIN(openPrompt, 8)
{
  JSAG_ARG_NSTR(title);
  JSAG_ARG_NSTR(msg);
  JSAG_ARG_NSTR(okText);
  JSAG_ARG_NSTR(cancelText);
  JSAG_ARG_NSTR(value);
  JSAG_ARG_BOOL(autoShowKeyboard);
  JSAG_ARG_BOOL(isPassword);
  JSAG_ARG_INT32(keyboardType);

  int32_t id = [[InputPrompt get] showAlertViewWithTitle:title
                                                 message:msg
                                                  okText:okText
                                              cancelText:cancelText
                                                   value:value
                                        autoShowKeyboard:autoShowKeyboard
                                              isPassword:isPassword
                                            keyboardType:keyboardType
                                            returnButton:@""];

  JSAG_RETURN_INT32(id);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(showKeyboard, 6)
{
  JSAG_ARG_NSTR(currVal);
  JSAG_ARG_NSTR(hint);
  JSAG_ARG_BOOL(hasBackward);
  JSAG_ARG_BOOL(hasForward);
  JSAG_ARG_NSTR(inputType);
  JSAG_ARG_NSTR(inputReturnButton);
  JSAG_ARG_INT32(maxLength);
  JSAG_ARG_INT32(cursorPos);

  InputAccessory *ip = [InputAccessory get];
  ip.hint = hint;
  ip.currVal = currVal;
  ip.inputType = inputType;
  ip.inputReturnButton = inputReturnButton;
  ip.hasForward = hasForward;
  ip.hasBackward = hasBackward;
  ip.maxLength = maxLength;
  ip.cursorPos = cursorPos;

  [ip show];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(hideKeyboard)
{
	[[InputAccessory get] hide];
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(input)
JSAG_OBJECT_MEMBER(openPrompt)
JSAG_OBJECT_MEMBER(showKeyboard)
JSAG_OBJECT_MEMBER(hideKeyboard)
JSAG_OBJECT_END

@implementation jsInput

+ (void) addToRuntime:(js_core *)js {
    m_js = js;

    JSAG_OBJECT_ATTACH(js.cx, js.native, input);
}

+ (void) onDestroyRuntime {
  if (m_js) {
//    InputPrompt *instance = [InputPrompt get];

    // TODO should this dismiss the view controller on the root controller?
//    if (instance) {
//      [instance.inputPromptAlertController dismissWithClickedButtonIndex:0 animated:FALSE];
//    }
  }

  m_js = nil;
}

@end
