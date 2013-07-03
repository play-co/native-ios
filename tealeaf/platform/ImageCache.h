//
//  ImageCache.h
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "platform/FileSystem.h"

static FileSystem *fileSystem;


@interface ImageCache : NSObject

+ (int) imageFromURL: (NSString*) url;
+ (void) cacheImageWithURL: (NSString*) url;
@end
