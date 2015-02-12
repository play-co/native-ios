//
//  NativeCalls.m
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/25/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "NativeCalls.h"
#import "platform/log.h"

@implementation NativeCalls

static NSMutableDictionary *calls = nil;

void _init() {
    calls = [[NSMutableDictionary alloc] init];
}


+ (void) Register:(NSString*)name withCallback:(NSMutableDictionary* (^)(NSMutableDictionary*))callback {
    if (calls == nil) {
        _init();
    }
    if ([calls objectForKey:name] == nil) {
        [calls setObject:[callback copy] forKey:name];
    } else {
        NSLOG(@"NativeCalls: Key already exists %@", name);
    }
}

+ (NSMutableDictionary*) Call:(NSString*)name withArgs:(NSMutableDictionary*)args {
    if (calls == nil) {
        _init();
    }
    if ([calls objectForKey:name] != nil) {
        return ((NSMutableDictionary* (^)(NSMutableDictionary*))[calls objectForKey:name])(args);
    }
    return [[[NSMutableDictionary alloc] init] autorelease];
}

@end