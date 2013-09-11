//
//  RawImageInfo.h
//  TeaLeafIOS
//
//  Created by Tom Fairfield on 7/2/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RawImageInfo : NSObject

@property(nonatomic,retain) NSString *url;
@property(nonatomic, assign) unsigned char *raw_data;
@property(nonatomic) int w;
@property(nonatomic) int h;
@property(nonatomic) int ow;
@property(nonatomic) int oh;
@property(nonatomic) int scale;
@property(nonatomic) int channels;

- (id) initWithData:(unsigned char*)raw_data andURL:(NSString *)url andW:(int)w andH:(int)h andOW:(int)ow andOH:(int)oh andScale:(int)scale andChannels:(int)channels;

@end

