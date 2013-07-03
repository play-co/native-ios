//
//  jsImageCache.h
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "js_core.h"


@interface jsImageCache : NSObject

+ (void) addToRuntime:(js_core *)js;
+ (void) onDestroyRuntime;


@end
