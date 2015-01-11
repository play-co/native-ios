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

#ifndef JS_ANIMATE_TEMPLATE_H
#define JS_ANIMATE_TEMPLATE_H

#include "core/util/detect.h"
#include "js/js.h"

#ifdef __cplusplus
extern "C" {
#endif

// Defined in js_animate_template.gen.cpp
JSObject *animate_create_ctor_object(JSContext *cx, jsval *vp);
void animate_add_to_object(JSObject *obj);

// Ctors: To be defined by manually-generated code:
bool def_animate_class_constructor(JSContext *cx, unsigned argc, jsval *vp);
void def_animate_class_finalize(JSFreeOp *fop, JSObject *obj);

// Methods: To be defined by manually-generated code:
bool def_animate_now(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_then(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_commit(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_clear(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_wait(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_pause(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_resume(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_isPaused(JSContext *cx, unsigned argc, jsval *vp);
bool def_animate_hasFrames(JSContext *cx, unsigned argc, jsval *vp);



// Properties: Some will be defined by manually-generated code:



#ifdef __cplusplus
}
#endif

#endif //JS_ANIMATE_TEMPLATE_H

