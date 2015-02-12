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

#import "TextInput.h"

@implementation TextInput

- (void) dealloc {
	self.type = nil;
	
	[super dealloc];
}

-(id) initWithFrame:(CGRect)frame andScale:(float)scale andTextScale:(float)textScale {
	frame.size.width /= scale;
	frame.size.height /= scale;
	frame.origin.x /= scale;
	frame.origin.y /= scale;

	self = [super initWithFrame:frame];
	self.scale = scale;
	self.textScale = textScale;

	float height = frame.size.height;
	[self setOpaque:false];
	[self setFont:[UIFont fontWithName:@"Helvetica" size:(height / self.textScale * 0.7)]];
	[self setReturnKeyType:UIReturnKeyDone];

	return self;
}

-(void) setWidth:(float)width andHeight:(float)height {
	CGRect frame;
	frame.origin.x = self.frame.origin.x;
	frame.origin.y = self.frame.origin.y;
	frame.size.width = width / self.scale;
	frame.size.height = height / self.scale;
	self.frame = frame;

	[self setFont:[UIFont fontWithName:@"Helvetica" size:(height / self.textScale * 0.7)]];
}

-(void) setX:(float)x andY:(float)y {
	CGRect frame;
	frame.origin.x = x / self.scale;
	frame.origin.y = y / self.scale;
	frame.size.width = self.frame.size.width;
	frame.size.height = self.frame.size.height;
	self.frame = frame;
}

- (void) drawRect:(CGRect)rect {
	UIGraphicsBeginImageContext(self.frame.size);

	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(currentContext, 3.0); //or whatever width you want
	CGContextSetRGBStrokeColor(currentContext, 1.0, 1.0, 1.0, 0.7); 

	CGRect myRect = CGContextGetClipBoundingBox(currentContext);

	CGContextStrokeRect(currentContext, myRect);
	UIImage *backgroundImage = (UIImage *)UIGraphicsGetImageFromCurrentImageContext();
	UIImageView *myImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)] autorelease];
	[myImageView setImage:backgroundImage];
	[self addSubview:myImageView];
	
	UIGraphicsEndImageContext();
}

@end
