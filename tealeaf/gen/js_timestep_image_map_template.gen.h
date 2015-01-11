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

#ifndef JS_TIMESTEP_IMAGE_MAP_TEMPLATE_H
#define JS_TIMESTEP_IMAGE_MAP_TEMPLATE_H

#include "core/util/detect.h"
#include "js/js.h"

#ifdef __cplusplus
extern "C" {
#endif

// Defined in js_timestep_image_map_template.gen.cpp
JSObject *timestep_image_map_create_ctor_object(JSContext *cx, jsval *vp);
void timestep_image_map_add_to_object(JSObject *obj);

// Ctors: To be defined by manually-generated code:
bool def_timestep_image_map_class_constructor(JSContext *cx, unsigned argc, jsval *vp);
void def_timestep_image_map_class_finalize(JSFreeOp *fop, JSObject *obj);

// Methods: To be defined by manually-generated code:



// Properties: Some will be defined by manually-generated code:

bool def_timestep_image_map_get_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_marginTop(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_marginTop(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_marginRight(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_marginRight(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_marginBottom(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_marginBottom(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_marginLeft(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_marginLeft(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_image_map_get_url(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_image_map_set_url(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);



#ifdef __cplusplus
}
#endif

#endif //JS_TIMESTEP_IMAGE_MAP_TEMPLATE_H

