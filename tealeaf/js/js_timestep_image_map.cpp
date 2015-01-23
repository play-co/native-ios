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

#include "js/js.h"
#include "timestep_image_map.h"
#include "gen/js_timestep_image_map_template.gen.h"
#include "core/log.h"

CEXPORT void def_timestep_image_map_class_finalize(JSFreeOp *fop, JSObject *obj) {
	timestep_image_map *map = (timestep_image_map*)JS_GetPrivate(obj);
	if (map) {
		timestep_image_delete(map);
	}
}

CEXPORT bool def_timestep_image_map_class_constructor(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, timestep_image_map_create_ctor_object(cx, vp));
  
	if (!thiz) {
		return false;
	}

	timestep_image_map *map = timestep_image_map_init();
	JS_SetPrivate(thiz, map);

  JS::RootedObject parent(cx); // NOTE: Parent is currently not stored anywhere
  JS::RootedString url_jstr(cx);

	if (argc == 6) {
		if (JS_ConvertArguments(cx, argc, JS_ARGV(cx, vp), "oiiiiS", &parent, &map->x, &map->y, &map->width, &map->height, &url_jstr)) {
			map->margin_top = 0;
			map->margin_right = 0;
			map->margin_bottom = 0;
			map->margin_left = 0;
			JSTR_TO_CSTR_PERSIST(cx, url_jstr, url_cstr);
			map->url = url_cstr;

      args.rval().set(OBJECT_TO_JSVAL(thiz));
			return true;
		}
	} else if (argc == 10) {
		if (JS_ConvertArguments(cx, argc, JS_ARGV(cx, vp), "oiiiiiiiiS", &parent, &map->x, &map->y, &map->width, &map->height, &map->margin_top, &map->margin_right, &map->margin_bottom, &map->margin_left, &url_jstr)) {
			JSTR_TO_CSTR_PERSIST(cx, url_jstr, url_cstr);
			map->url = url_cstr;
			
      args.rval().set(OBJECT_TO_JSVAL(thiz));
			return true;
		}
	}

	LOG("{imagemap} ERROR: ImageMap constructor arguments were invalid!");

	// Unlikely
	timestep_image_delete(map);

	return false;
}
