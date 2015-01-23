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

#ifndef JS_TIMESTEP_VIEW_TEMPLATE_H
#define JS_TIMESTEP_VIEW_TEMPLATE_H

#include "core/util/detect.h"
#include "js/js.h"

#ifdef __cplusplus
extern "C" {
#endif

// Defined in js_timestep_view_template.gen.cpp
JSObject *timestep_view_create_ctor_object(JSContext *cx, jsval *vp);
void timestep_view_add_to_object(JSObject *obj);

// Ctors: To be defined by manually-generated code:
bool def_timestep_view_class_constructor(JSContext *cx, unsigned argc, jsval *vp);
void def_timestep_view_class_finalize(JSFreeOp *fop, JSObject *obj);

// Methods: To be defined by manually-generated code:
bool def_timestep_view_addSubview(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_removeSubview(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_getSuperview(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_getSubviews(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_wrapRender(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_wrapTick(JSContext *cx, unsigned argc, jsval *vp);
bool def_timestep_view_localizePoint(JSContext *cx, unsigned argc, jsval *vp);



// Properties: Some will be defined by manually-generated code:

bool def_timestep_view_get_compositeOperation(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_compositeOperation(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_offsetX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_offsetX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_offsetY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_offsetY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_r(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_r(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_flipX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_flipX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_flipY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_flipY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_anchorX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_anchorX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_anchorY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_anchorY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_opacity(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_opacity(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_scale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_scale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_scaleX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_scaleX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_scaleY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_scaleY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_absScale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_absScale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_clip(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_clip(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_backgroundColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_backgroundColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_visible(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_visible(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_hasJSRender(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_hasJSRender(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_hasJSTick(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_hasJSTick(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_zIndex(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_zIndex(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_filterColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_filterColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_filterType(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_filterType(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get__width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set__width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);

bool def_timestep_view_get__height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp);
bool def_timestep_view_set__height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp);



#ifdef __cplusplus
}
#endif

#endif //JS_TIMESTEP_VIEW_TEMPLATE_H

