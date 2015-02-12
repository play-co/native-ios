//
//  TeaLeafEvent.m
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/30/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "TeaLeafEvent.h"
#import <JSONKit.h>
#include "events.h"
#include "core/events.h"


@implementation TeaLeafEvent
+ (void) Send:(NSString*)name withOpts:(NSMutableDictionary*)opts {
    if (opts == nil) {
        opts = [NSMutableDictionary dictionary];
    }
    [opts setObject:name forKey:@"name"];
    core_dispatch_event([[opts JSONString] UTF8String]);
}
@end
