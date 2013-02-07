/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.	 If not, see <http://www.gnu.org/licenses/>.
 */

#import "TextInputManager.h"
#import "core/log.h"

static id instance = nil;

@implementation TextInputManager

- (void) dealloc {
	self.view = nil;
	self.inputs = nil;
	
	[super dealloc];
}

- (id)initWithSuperView:(UIView *)view
{
	self = [super init];
	if (self) {
		self.inputs = [[[NSMutableDictionary alloc] init] autorelease];
		self.view = view;
		self.idi = 0;
	}

	return self;
}

-(int) addTextInputAtX:(int)x Y:(int)y width:(int)width height:(int)height text:(NSString *)text {
	CGRect frame;
	frame.origin.x = x / self.scale;
	frame.origin.y = y / self.scale;
	frame.size.width = width;
	frame.size.height = height;

	TextInput *input = [[TextInput alloc] initWithFrame:frame andScale:self.scale andTextScale:self.textScale];
	[input setText: text];

	[self.view addSubview:input];
	[self.inputs setObject:input forKey:[NSNumber numberWithInt:self.idi]];

	return self.idi++;
}

-(TextInput *) getTextInputWithId:(int)idi {
	return [self.inputs objectForKey: [NSNumber numberWithInt:idi]];
}

-(void) destroyTextInputWithId:(int)idi {
	TextInput *input = [[self.inputs objectForKey:[NSNumber numberWithInt:idi]] autorelease];
	if (input) {
		[self.inputs removeObjectForKey:[NSNumber numberWithInt:idi]];
		[input removeFromSuperview];
	}
}

-(void) dismissAll {
	for (TextInput *input in [self.inputs allValues]) {
		[input resignFirstResponder];
	}
}

- (void) destroyAll {
	[self dismissAll];

	for (TextInput *input in [self.inputs allValues]) {
		[input removeFromSuperview];
	}

	[self.inputs removeAllObjects];
}

+ (id) get {
	if (!instance) {
		instance = [[TextInputManager alloc] init];
	}

	return instance;
}

+ (void) setSuperView:(UIView *)view {
	instance = [[TextInputManager alloc] initWithSuperView:view];
	float scale = [[UIScreen mainScreen] scale];
	float textScale = scale;

	[instance setScale:scale];
	[instance setTextScale:textScale];
}

@end
