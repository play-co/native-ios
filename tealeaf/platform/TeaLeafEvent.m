//
//  TeaLeafEvent.m
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/30/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "TeaLeafEvent.h"
#include "events.h"
#include "core/events.h"


@implementation TeaLeafEvent
+ (void) Send:(NSString*)name withOpts:(NSMutableDictionary*)opts {
    if (opts == nil) {
        opts = [NSMutableDictionary dictionary];
    }
    [opts setObject:name forKey:@"name"];

    NSData* data = [NSJSONSerialization dataWithJSONObject:opts options:0 error:nil];
    NSString *evt = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    core_dispatch_event([evt UTF8String]);
}
@end
