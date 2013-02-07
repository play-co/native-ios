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

#include "log.h"
#include "core/util/detect.h"

#include "debug/DebugServer.h"
static DebugServer *m_debugger = nil;


CEXPORT void LoggerSetDebugger(void *debugger) {
	m_debugger = (DebugServer*)debugger;
}


CEXPORT void _LOG(const char *f, ...) {
	va_list args;
	va_start(args, f);
	if (m_debugger) {
		NSString *msg = [[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:f] arguments:args] autorelease];

		NSLog(@"%@", msg);

		[m_debugger onLogMessage:msg];
	} else {
		NSLogv([NSString stringWithUTF8String:f], args);
	}
	va_end(args);
}

CEXPORT void _NSLOG(NSString *f, ...) {
	va_list args;
	va_start(args, f);
	if (m_debugger) {
		NSString *msg = [[[NSString alloc] initWithFormat:f arguments:args] autorelease];
		
		NSLog(@"%@", msg);

		[m_debugger onLogMessage:msg];
	} else {
		NSLogv(f, args);
	}
	va_end(args);
}
