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

#import "OALSourceInfo.h"

@implementation OALSourceInfo

- (void) dealloc {
	self.source = nil;
	self.owningURL = nil;
	[super dealloc];
}

- (id) init
{
	self.source = nil;
	self.timer = 0.0;
	self.lastUpdate = CFAbsoluteTimeGetCurrent();
	self.owningURL = nil;
	return self;
}

- (id) initWithSource:(ALSource*)src andTime:(float)time {
	id ret = [self init];
	self.source = src;
	self.timer = time;
	return ret;
}

- (void) updateTimer:(CFTimeInterval) currTime {
	float dt = currTime - self.lastUpdate;
	self.timer -= dt;
	self.lastUpdate = currTime;
}

@end
