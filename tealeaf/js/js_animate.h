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

#ifndef JS_ANIMATE_H
#define JS_ANIMATE_H

#include "core/types.h"
#include "core/timestep/timestep_animate.h"
#include "js/js_animate.h"
#include "js/js_timestep_view.h"
#include "core/tealeaf_context.h"
#include "gen/js_animate_template.gen.h"


#ifdef __cplusplus
extern "C" {
#endif

void def_animate_add_to_group(JS_OBJECT_WRAPPER js_anim);
void def_animate_remove_from_group(JS_OBJECT_WRAPPER js_anim);
void def_animate_cb(JS_OBJECT_WRAPPER js_view, JS_OBJECT_WRAPPER cb, double tt, double t);

#ifdef __cplusplus
}
#endif


#endif //JS_ANIMATE_H
