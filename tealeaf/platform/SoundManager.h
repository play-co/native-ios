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
 * along with the Game Closure SDK.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import "OALSourceInfo.h"

#define MAX_SIMULTANEOUS_SOUNDS 28

@class ResourceLoader;
@class CDSoundSource;
@class SoundSpec;

@interface SoundManager : NSObject {
	// sources keeps track of ObjectAL's ALSources and LRU timers
	NSMutableDictionary *sources;
	// quick look up by last URL played on a source for pausing and stopping sounds
	NSMutableDictionary *sourcesByURL;
	// preloaded keeps track of sounds that have been explicitly preloaded by the game dev
	NSMutableSet *preloaded;
	// bgUrl always points to the last played background music track
	NSString *bgUrl;
}

-(void) playBackgroundMusicWithURL:(NSString *)urlString andVolume: (float)volume andLoop:(BOOL)loop;
-(void) playSoundWithURL:(NSString *)url andVolume: (float)volume andLoop:(BOOL)loop;
-(void) stopSoundWithURL:(NSString *)url;
-(void) loadSoundWithURL: (NSString *)url;
-(void) loadBackgroundMusicWithURL: (NSString *) urlString;
-(void) pauseSoundWithURL: (NSString *) url;
-(void) destroySoundWithURL:(NSString *)urlString;
-(void) setVolume: (float) volume forSoundWithURL:(NSString*) urlString;
-(void) clearEffects;
-(void) stopBackgroundMusic;

// keep track of ObjectAL sources so we don't exceed MAX_SIMULTANEOUS_SOUNDS
-(OALSourceInfo*) getFreeSourceInfo;

+ (SoundManager *) get;

@end
