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

#import "js/jsSound.h"
#import "SoundManager.h"
#import "core/events.h"

JSAG_MEMBER_BEGIN(playBackgroundMusic, 3)
{
	JSAG_ARG_NSTR(url);
	JSAG_ARG_DOUBLE(volume);
	JSAG_ARG_BOOL(loop);

	[[SoundManager get] playBackgroundMusicWithURL:url andVolume:(float)volume andLoop:(BOOL)loop];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(playSound, 3)
{
	JSAG_ARG_NSTR(url);
	JSAG_ARG_DOUBLE(volume);
	JSAG_ARG_BOOL(loop);

	[[SoundManager get] playSoundWithURL:url andVolume:(float)volume andLoop:(BOOL)loop];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(stopSound, 1)
{
	JSAG_ARG_NSTR(url);

	[[SoundManager get] stopSoundWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(pauseSound, 1)
{
	JSAG_ARG_NSTR(url);
	
	[[SoundManager get] pauseSoundWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(loadSound, 1)
{
	JSAG_ARG_NSTR(url);
	
	[[SoundManager get] loadSoundWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(loadBackgroundMusic, 1)
{
	JSAG_ARG_NSTR(url);
	
	[[SoundManager get] loadBackgroundMusicWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(destroySound, 1)
{
	JSAG_ARG_NSTR(url);
	
	[[SoundManager get] destroySoundWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setVolume, 2)
{
	JSAG_ARG_NSTR(url);
	JSAG_ARG_DOUBLE(volume);

	[[SoundManager get] setVolume:volume forSoundWithURL:url];
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(seekTo, 2)
{
	JSAG_ARG_NSTR(url);
	JSAG_ARG_DOUBLE(position);
	
	[[SoundManager get] seekTo:position forSoundWithURL:url];
}
JSAG_MEMBER_END


JSAG_OBJECT_START(sound)
JSAG_OBJECT_MEMBER(playBackgroundMusic)
JSAG_OBJECT_MEMBER(playSound)
JSAG_OBJECT_MEMBER(loadSound)
JSAG_OBJECT_MEMBER(loadBackgroundMusic)
JSAG_OBJECT_MEMBER(stopSound)
JSAG_OBJECT_MEMBER(pauseSound)
JSAG_OBJECT_MEMBER(destroySound)
JSAG_OBJECT_MEMBER(setVolume)
JSAG_OBJECT_MEMBER(seekTo)
JSAG_OBJECT_END


@implementation jsSound

+ (void) addToRuntime:(js_core *)js {
	JSAG_OBJECT_ATTACH(js.cx, js.native, sound);
}

+ (void) onDestroyRuntime {
	
}

@end
