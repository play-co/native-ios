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
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
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
namespace JS {
  typedef JSAutoRequest AutoRequest;
}

#ifdef __cplusplus
}
#endif

#endif //JS_H
