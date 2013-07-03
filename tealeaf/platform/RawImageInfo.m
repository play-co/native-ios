//
//  RawImageInfo.m
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "RawImageInfo.h"

@implementation RawImageInfo
- (void) dealloc {
	self.url = nil;
    
	[super dealloc];
}

- (id) initWithData:(unsigned char*)raw_data andURL:(NSString *)url andW:(int)w andH:(int)h andOW:(int)ow andOH:(int)oh andScale:(int)scale andChannels:(int)channels {
	if ((self = [super init])) {
		self.url = url;
		self.raw_data = raw_data;
		self.w = w;
		self.h = h;
		self.ow = ow;
		self.oh = oh;
		self.scale = scale;
		self.channels = channels;
	}
	return self;
}
@end
