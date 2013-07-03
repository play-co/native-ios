//
//  ImageCache.m
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "ImageCache.h"
#import "core/texture_manager.h"

@implementation ImageCache

+ (int) imageFromURL: (NSString*) url {
    NSData *contents = [fileSystem readFile: url];
    
    if (!contents) {
       // contents = [NSData dataWithContentsOfURL: [NSURL urlWithString:url]];
        //save it in a block
    }
    
    texture_manager_new_texture_from_data(texture_manager_get(), 0, 0, [contents bytes]);
    
    
    return 0;
}

+ (void) cacheImageWithURL: (NSString*) url {
    const char *url_str = [url UTF8String];
    texture_2d* tex = texture_manager_get_texture(texture_manager_get(), url_str);
    if (tex) {
        texture_2d_save(tex);
        NSData *data = [NSData dataWithBytes:tex->saved_data length:tex->width*tex->height*4];
        //TODO async
        [fileSystem writeFile: url withContents: data];
    }
}

@end
