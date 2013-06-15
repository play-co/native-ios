/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import <Foundation/Foundation.h>
#import "jsapi.h"

@interface UITouchWrapper : NSObject {
	int uid;
	void *addr;
    int touchId;
}

-(id) initWithUITouch: (UITouch *) touch andView: (UIView *) view andId:(int) id;
-(bool) isForUITouch: (UITouch *) touch;
-(void) updateWithUITouch: (UITouch *) touch forView: (UIView *) view;
-(void) removeWithUITouch: (UITouch *) touch forView: (UIView *) view;
-(void) addEvent: (int) name withUITouch: (UITouch *) touch forView: (UIView *) view;
@property (nonatomic) int uid;

@end
