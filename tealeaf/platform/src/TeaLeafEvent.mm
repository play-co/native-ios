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
    NSError* err;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:opts options:0 error:&err];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    core_dispatch_event([json UTF8String]);
}
@end
