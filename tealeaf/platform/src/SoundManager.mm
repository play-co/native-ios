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

#import "SoundManager.h"
#import "ResourceLoader.h"
#import "ObjectAL.h"
#include "core/events.h"
#include "platform/log.h"
#include "TeaLeafAppDelegate.h"
#include "limits.h"

SoundManager *globalSoundManager = NULL;

@interface SoundManager ()
@property (nonatomic, assign) TeaLeafAppDelegate *appDelegate;
@end

@implementation SoundManager

- (id) init {
	self = [super init];

	pauses = [[NSMutableDictionary alloc] init];
	sources = [[NSMutableDictionary alloc] init];
	sourcesByURL = [[NSMutableDictionary alloc] init];
	preloaded = [[NSMutableSet alloc] init];
	bgUrl = nil;

	if (!globalSoundManager) {
		globalSoundManager = self;
	}

	// This appears to be broken in practice so keep it off
	[OALSimpleAudio sharedInstance].useHardwareIfAvailable = NO;

	[OALSimpleAudio sharedInstance].allowIpod = YES;
	[OALSimpleAudio sharedInstance].honorSilentSwitch = YES;
	[OALSimpleAudio sharedInstance].preloadCacheEnabled = YES;
	[OALSimpleAudio sharedInstance].channel.interruptible = YES;
	self.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);
	return self; 
}

-(NSString*) resolvePath:(NSString*) path {
	NSString *filePath = nil;
	NSURL *url = [[ResourceLoader get] resolve:path];
	if (self.appDelegate.isTestApp) {
		return [[url absoluteString] substringFromIndex:7];
	} else {
		if ([url.scheme compare: @"http"] != NSOrderedSame) {
			filePath = [NSString stringWithFormat:@"resources.bundle/%@", path];
		} else {
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];
			filePath = [documentsDirectory stringByAppendingFormat:@"/%@", [[url pathComponents] objectAtIndex:[[url pathComponents] count] - 1]];
			if(![[NSFileManager defaultManager] fileExistsAtPath: filePath]) {
				NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
				NSURLResponse *response = [[NSURLResponse alloc] init];
				NSError *error = nil;
				
				NSData *soundData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
				
				[soundData writeToFile:filePath atomically:true];
			}
		}
	}
	return filePath;
}

- (void) playBackgroundMusicWithURL:(NSString *)urlString andVolume: (float)volume andLoop:(BOOL)loop {
	NSString *resolvedUrl = [self resolvePath:urlString];
	[[OALSimpleAudio sharedInstance] playBg:resolvedUrl volume:volume pan:0 loop:loop];
	ResumeInfo *resumeInfo = [pauses objectForKey:urlString];
	if (resumeInfo != nil) {
		[OALSimpleAudio sharedInstance].backgroundTrack.currentTime = resumeInfo.pauseTime;
		[pauses removeObjectForKey:urlString];
	}
	if (bgUrl) {
		[bgUrl release];
	}
	bgUrl = [urlString retain];
	
	NSString* evt = [NSString stringWithFormat:@"{\"name\":\"soundDuration\",\"url\":\"%@\",\"duration\":%f}",
					 urlString, [OALSimpleAudio sharedInstance].backgroundTrack.duration];
	core_dispatch_event([evt UTF8String]);
}

- (void) playSoundWithURL:(NSString *)urlString andVolume:(float)volume andLoop:(BOOL)loop {
	if (![preloaded containsObject:urlString]) {
		NSLOG(@"{sound} GAME DEV WARNING: Playing sound without preloading: %@", urlString);
	}

	NSString *path = [self resolvePath:urlString];

	[[OALSimpleAudio sharedInstance] preloadEffect:path reduceToMono:false completionBlock:^(ALBuffer *newBuffer) {
		if (newBuffer) {
			OALSourceInfo *sourceInfoToUse = [self getFreeSourceInfo];
			ALSource *sourceToUse;

			if (sourceInfoToUse != nil) {
				sourceToUse = sourceInfoToUse.source;
				[sourceToUse stop];
				[sourceToUse play:newBuffer gain:volume pitch:1.0f pan:0.0f loop:loop];
				sourceInfoToUse.timer = newBuffer.duration;
				sourceInfoToUse.owningURL = urlString;
			} else {
				sourceToUse = (ALSource*)[[OALSimpleAudio sharedInstance] playBuffer:newBuffer volume:volume pitch:1.0f pan:0.0f loop:loop];

				if (sourceToUse) {
					NSNumber *key = [[[NSNumber alloc] initWithInt:sourceToUse.sourceId] autorelease];
					OALSourceInfo *oldInfo = [sources objectForKey:key];

					if (oldInfo != nil) {
						oldInfo.timer = newBuffer.duration;
						oldInfo.owningURL = urlString;
					} else {
						OALSourceInfo *srcInfo = [[[OALSourceInfo alloc] initWithSource:sourceToUse andTime:newBuffer.duration] autorelease];
						srcInfo.owningURL = urlString;
						[sources setObject:srcInfo forKey:key];
					}
				} else {
					NSLOG(@"{sound} WARNING: Failed to load buffer: %@", urlString);
				}
			}

			if (sourceToUse) {
				[sourcesByURL setObject:sourceToUse forKey:urlString];
			}
		} else {
			NSLOG(@"{sound} GAME DEV WARNING: Unable to load: %@", urlString);
		}
	}];
}

-(OALSourceInfo*) getFreeSourceInfo {
	CFTimeInterval currTime = CFAbsoluteTimeGetCurrent();
	OALSourceInfo *retSourceInfo = nil;
	OALSourceInfo *srcInfoLRU = nil;
	float timerLRU = FLT_MAX;
	int srcCount = 0;
	for (NSNumber *key in sources) {
		OALSourceInfo *srcInfo = [sources objectForKey:key];
		[srcInfo updateTimer:currTime];
		srcCount++;

		// look for a free source
		if (retSourceInfo == nil) {
			if (srcInfo.timer <= 0.0) {
				retSourceInfo = srcInfo;
				continue;
			}

			// update LRU
			if (timerLRU >= srcInfo.timer) {
				timerLRU = srcInfo.timer;
				srcInfoLRU = srcInfo;
			}
		}
	}

	if (retSourceInfo == nil && srcInfoLRU != nil && srcCount == MAX_SIMULTANEOUS_SOUNDS) {
		retSourceInfo = srcInfoLRU;
	}

	return retSourceInfo;
}

-(void) stopSoundWithURL: (NSString *)urlString {
	if ([bgUrl isEqualToString:urlString]) {
		[[OALSimpleAudio sharedInstance] stopBg];
	} else {
		ALSource *sound = [sourcesByURL objectForKey:urlString];

		if (sound) {
			NSNumber *key = [[[NSNumber alloc] initWithInt:sound.sourceId] autorelease];
			OALSourceInfo *oldInfo = [sources objectForKey:key];

			if(oldInfo == nil || [urlString isEqualToString:oldInfo.owningURL])
			{
				[sound stop];
			}
		}
	}
}

-(void) pauseSoundWithURL: (NSString *) urlString {
	if ([bgUrl isEqualToString:urlString]) {
		float curTime = [OALSimpleAudio sharedInstance].backgroundTrack.currentTime;
		ResumeInfo *resumeInfo = [[ResumeInfo alloc] initWithTime:curTime];
		[pauses setObject:resumeInfo forKey:urlString];
		[[OALSimpleAudio sharedInstance] stopBg];
	} else {
		ALSource *sound = [sourcesByURL objectForKey:urlString];
		if (sound) {
			NSNumber *key = [[[NSNumber alloc] initWithInt:sound.sourceId] autorelease];
			OALSourceInfo *oldInfo = [sources objectForKey:key];

			if(oldInfo == nil || [urlString isEqualToString:oldInfo.owningURL])
			{
				sound.paused = true;
			}
		}
	}
}

-(void) loadBackgroundMusicWithURL: (NSString *) urlString {
	NSString *resolvedUrl = [self resolvePath:urlString];
	[[OALSimpleAudio sharedInstance] preloadBg:resolvedUrl];
}

//TODO Make this work and not throw an exception
-(void) loadSoundWithURL:(NSString *)urlString {
	NSString *savedUrl = [NSString stringWithString:urlString];
	NSString *resolvedUrl = [self resolvePath:savedUrl];

	[[OALSimpleAudio sharedInstance] preloadEffect:resolvedUrl reduceToMono:false completionBlock:^(ALBuffer *buffer) {
		[preloaded addObject:savedUrl];
		NSString* evt = [NSString stringWithFormat:@"{\"name\":\"soundLoaded\",\"url\":\"%@\"}", savedUrl];
		core_dispatch_event([evt UTF8String]);
	}];
}

-(void) destroySoundWithURL:(NSString *)urlString {
	if([sourcesByURL objectForKey: urlString] != nil) {
		[[OALSimpleAudio sharedInstance] unloadEffect: urlString];
		[sourcesByURL removeObjectForKey: urlString];
	}
}

-(void) setVolume:(float)volume forSoundWithURL:(NSString *)urlString {
	ALSource *sound = [sourcesByURL objectForKey:urlString];
	if (sound) {
		NSNumber *key = [[[NSNumber alloc] initWithInt:sound.sourceId] autorelease];
		OALSourceInfo *oldInfo = [sources objectForKey:key];

		if(oldInfo == nil || [urlString isEqualToString:oldInfo.owningURL])
		{
			sound.volume = volume;
		}
	}
}

-(void) seekTo: (float) position forSoundWithURL:(NSString*) urlString {
	if ([bgUrl isEqualToString:urlString]) {
		[OALSimpleAudio sharedInstance].backgroundTrack.currentTime = position;
	}
}

-(void) clearEffects {
	[[OALSimpleAudio sharedInstance] unloadAllEffects];
}

-(void) stopBackgroundMusic {
	[[OALSimpleAudio sharedInstance] stopBg];
}


+ (SoundManager *) get {
	if (globalSoundManager){
		return globalSoundManager;		  
	} else {
		return [[SoundManager alloc] init];
	}
}

@end

extern "C" {

void sound_manager_halt() {
	SoundManager *mgr = [SoundManager get];

	[mgr clearEffects];
	[mgr stopBackgroundMusic];
}

} // extern C
