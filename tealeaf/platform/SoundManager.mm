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

	sources = [[NSMutableDictionary alloc] init];
	sourcesByURL = [[NSMutableDictionary alloc] init];
	preloaded = [[NSMutableSet alloc] init];
	bgUrl = nil;

	if (!globalSoundManager) {
		globalSoundManager = self;
	}
	[OALSimpleAudio sharedInstance].allowIpod = NO;
	[OALSimpleAudio sharedInstance].honorSilentSwitch = YES;
	[OALSimpleAudio sharedInstance].preloadCacheEnabled = YES;
	[OALSimpleAudio sharedInstance].channel.interruptible = YES;
	self.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);
	return self; 
}

-(NSString*) resolvePath:(NSString*) path {
	NSString *filePath = nil;
	NSURL *url = [[ResourceLoader get] resolve:path];
	bool isRemoteLoading = [[self.appDelegate.config objectForKey:@"remote_loading"] boolValue];
	if (!isRemoteLoading) {
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
	} else {
		return [[url absoluteString] substringFromIndex:7];
	}
	return filePath;
}

- (void) playBackgroundMusicWithURL:(NSString *)urlString andVolume: (float)volume andLoop:(BOOL)loop {
	NSString *resolvedUrl = [self resolvePath:urlString];
	[[OALSimpleAudio sharedInstance] playBg:resolvedUrl volume:volume pan:0 loop:loop];
	if (bgUrl) {
		[bgUrl release];
	}
	bgUrl = [urlString retain];
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
