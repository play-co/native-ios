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

#ifndef JS_H
#define JS_H

#include "jsapi.h"
#include "jsMacros.h"
#include "core/util/detect.h"
#include <string.h>

#define JS_OBJECT_WRAPPER JSObject*
#define PERSISTENT_JS_OBJECT_WRAPPER JS_OBJECT_WRAPPER

#ifdef __cplusplus
extern "C" {
#endif
	
void js_object_wrapper_init(PERSISTENT_JS_OBJECT_WRAPPER *obj);
void js_object_wrapper_root(PERSISTENT_JS_OBJECT_WRAPPER *obj, JS_OBJECT_WRAPPER target);
void js_object_wrapper_delete(PERSISTENT_JS_OBJECT_WRAPPER *obj);

#ifdef __cplusplus
}
#endif

#endif //JS_H
