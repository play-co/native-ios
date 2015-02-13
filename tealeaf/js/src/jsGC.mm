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

#import "js/jsGC.h"

static js_core *m_core = nil;


JSAG_MEMBER_BEGIN_NOARGS(runGC)
{
	[m_core performGC];
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(runMaybeGC)
{
	[m_core performMaybeGC];
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(gc)
JSAG_OBJECT_MEMBER(runGC)
JSAG_OBJECT_MEMBER(runMaybeGC)
JSAG_OBJECT_END


@implementation jsGC

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

  JSAG_OBJECT_ATTACH(js.cx, js.native, gc);
}

+ (void) onDestroyRuntime {
	m_core = nil;
}

@end
