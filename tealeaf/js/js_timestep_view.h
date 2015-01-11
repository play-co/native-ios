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

#ifndef JS_TIMESTEP_VIEW_H
#define JS_TIMESTEP_VIEW_H

#include "gen/js_timestep_view_template.gen.h"


#ifdef __cplusplus
extern "C" {
#endif

void def_timestep_view_needs_reflow(void *js_view, bool force);
void def_timestep_view_tick(void *js_view, double dt);
void def_timestep_view_build_view(void *data);
void def_timestep_view_render(void *view, void *ctx, void *opts);

JSObject *def_get_viewport(JS::HandleObject js_opts);
  void def_restore_viewport(JS::HandleObject js_opts, JS::Heap<JSObject*> *js_viewport);

bool def_image_view_set_image(JSContext *cx, unsigned argc, jsval *vp);

#ifdef __cplusplus
}
#endif


#endif
