//
//  TeaLeafEvent.h
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/30/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeaLeafEvent : NSObject
+ (void) Send:(NSString*)name withOpts:(NSMutableDictionary*)opts;
@end
