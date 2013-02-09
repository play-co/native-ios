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

#import <platform/PluginManager.h>
#import "js/jsPluginManager.h"

static js_core *m_core = nil;


JSAG_MEMBER_BEGIN(sendEvent, 3)
{
	JSAG_ARG_NSTR(pluginName);
	JSAG_ARG_NSTR(eventName);
	JSAG_ARG_NSTR(str);

	[m_core.pluginManager sendEvent:str isJS:NO];
}
JSAG_MEMBER_END


JSAG_OBJECT_START(plugins)
JSAG_OBJECT_MEMBER(sendEvent)
JSAG_OBJECT_END


@implementation jsPluginManager

+ (void) addToRuntime:(js_core *)js {
	m_core = js;

	JSAG_OBJECT_ATTACH(js.cx, js.native, plugins);
}

+ (void) onDestroyRuntime {
	
}

@end
