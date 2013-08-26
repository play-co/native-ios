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

#include "log.h"
#include "core/util/detect.h"

#ifndef DISABLE_DEBUG_SERVER

#include "debug/DebugServer.h"
static DebugServer *m_debugger = nil;

CEXPORT void LoggerSetDebugger(void *debugger) {
	m_debugger = (DebugServer*)debugger;
}

#endif


CEXPORT void _LOG(const char *f, ...) {
	va_list args;
	va_start(args, f);
#ifndef DISABLE_DEBUG_SERVER
	if (m_debugger) {
		NSString *msg = [[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:f] arguments:args] autorelease];

		NSLog(@"%@", msg);

		[m_debugger onLogMessage:msg];
	} else
#endif
	{
		NSLogv([NSString stringWithUTF8String:f], args);
	}
	va_end(args);
}

CEXPORT void _NSLOG(NSString *f, ...) {
	va_list args;
	va_start(args, f);
#ifndef DISABLE_DEBUG_SERVER
	if (m_debugger) {
		NSString *msg = [[[NSString alloc] initWithFormat:f arguments:args] autorelease];
		
		NSLog(@"%@", msg);

		[m_debugger onLogMessage:msg];
	} else
#endif
	{
		NSLogv(f, args);
	}
	va_end(args);
}
