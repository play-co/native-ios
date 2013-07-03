//
//  jsImageCache.m
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "jsImageCache.h"
#import "platform/ImageCache.h"

JSAG_MEMBER_BEGIN(cacheImage, 1)
{
	JSAG_ARG_NSTR(url);
    [ImageCache cacheImageWithURL: url];
    
}
JSAG_MEMBER_END


JSAG_MEMBER_BEGIN(getImage, 1)
{
    JSAG_ARG_NSTR(url);
    [ImageCache imageFromURL:url];
     //TODO return something?
}
JSAG_MEMBER_END

JSAG_OBJECT_START(imageCache)
JSAG_OBJECT_MEMBER(cacheImage)
JSAG_OBJECT_MEMBER(getImage)
JSAG_OBJECT_END

@implementation jsImageCache

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, imageCache);
}
     
@end
