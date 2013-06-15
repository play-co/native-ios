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
 * along with the Game Closure SDK.	 If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import "UITouchWrapper.h"
#include "string.h"
#include "jsMacros.h"
#include "core/config.h"
#import "JS.h"
#import "timestep_events.h"

static uint tid = 0;

#define TOUCH_DOWN 1
#define TOUCH_MOVE 2
#define TOUCH_SELECT 3

@implementation UITouchWrapper

@synthesize uid;

-(id) initWithUITouch: (UITouch *) touch andView: (UIView *) view andId:(int) id {
	self = [super init];
	touchId = id;
	uid = ++tid;
	addr = (void *) touch;

	[self addEvent:TOUCH_DOWN withUITouch:touch forView: view];
	
	return self;
}

-(bool) isForUITouch: (UITouch *) touch {
	return addr == (void *) touch;
}

-(void) updateWithUITouch: (UITouch *) touch forView: (UIView *) view {
	[self addEvent:TOUCH_MOVE withUITouch:touch forView: view];
}

-(void) removeWithUITouch: (UITouch *) touch forView: (UIView *) view {
	[self addEvent:TOUCH_SELECT withUITouch:touch forView: view];
}

-(void) addEvent: (int) name withUITouch: (UITouch *) touch forView: canvasView {
	CGPoint loc = [touch locationInView: canvasView];
	CGFloat fx = loc.x;//
	CGFloat fy = loc.y;//frame.size.width - loc.x, fy = frame.size.height - loc.y;
	fx *= [[UIScreen mainScreen] scale];
	fy *= [[UIScreen mainScreen] scale];
	
	timestep_events_push(touchId, name, fx, fy);
	
}

@end
