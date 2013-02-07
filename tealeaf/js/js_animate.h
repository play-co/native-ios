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

void def_animate_finish(void *js_anim);
void def_animate_cb(void *js_view, void *cb, double tt, double t);

#ifdef __cplusplus
}
#endif


#endif //JS_ANIMATE_H
