//
//  NativeCalls.h
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/25/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NativeCalls : NSObject {
    
}

+ (void) Register:(NSString*)name withCallback:(NSMutableDictionary* (^)(NSMutableDictionary*))callback;
+ (NSMutableDictionary*) Call:(NSString*)name withArgs:(NSMutableDictionary*)args;
@end