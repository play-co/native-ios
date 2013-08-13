//
//  jsInput.h
//  TeaLeafIOS
//
//  Created by Martin Hunt on 8/13/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "js/js_core.h"

@interface jsInput : NSObject

+ (void) addToRuntime:(js_core *)js;
+ (void) onDestroyRuntime;

@end
