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

#include "js_timestep_view_template.gen.h"
#include "js/js_timestep_view.h"


#include "core/timestep/timestep_view.h"

#include "core/rgba.h"


#include "js/js_core.h"



CEXPORT bool def_timestep_view_get_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->x);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->x = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->y);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->y = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_offsetX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->offset_x);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_offsetX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->offset_x = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_offsetY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->offset_y);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_offsetY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->offset_y = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_r(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->r);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_r(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->r = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_flipX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->flip_x);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_flipX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->flip_x = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_flipY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->flip_y);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_flipY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->flip_y = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_anchorX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->anchor_x);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_anchorX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->anchor_x = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_anchorY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->anchor_y);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_anchorY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->anchor_y = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_opacity(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->opacity);
		
	}
	JS_EndRequest(cx);
	return true;
}






CEXPORT bool def_timestep_view_get_scale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->scale);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_scale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->scale = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_scaleX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->scale_x);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_scaleX(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->scale_x = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_scaleY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->scale_y);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_scaleY(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->scale_y = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_absScale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->abs_scale);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_absScale(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->abs_scale = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_clip(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->clip);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_clip(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->clip = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_backgroundColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		rgba prop = thiz->background_color;

char buf[64];
int len = rgba_to_string(&prop, buf);

vp.setString(JS_NewStringCopyN(cx, buf, len));

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_backgroundColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		if (vp.isString()) {
	JSString *jstr = vp.toString();

	JSTR_TO_CSTR(cx, jstr, cstr);

	rgba color;
	rgba_parse(&color, cstr);
	thiz->background_color = color;
}

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_visible(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->visible);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_visible(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->visible = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_hasJSRender(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->has_jsrender);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_hasJSRender(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->has_jsrender = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_hasJSTick(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setBoolean(thiz->has_jstick);

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_hasJSTick(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->has_jstick = vp.toBoolean();

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_zIndex(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->z_index);
		
	}
	JS_EndRequest(cx);
	return true;
}






CEXPORT bool def_timestep_view_get_filterColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		rgba prop = thiz->filter_color;

char buf[64];
int len = rgba_to_string(&prop, buf);

vp.setString(JS_NewStringCopyN(cx, buf, len));

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_filterColor(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		if (vp.isString()) {
	JSString *jstr = vp.toString();

	JSTR_TO_CSTR(cx, jstr, cstr);

	rgba color;
	rgba_parse(&color, cstr);
	thiz->filter_color = color;
}

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_filterType(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->filter_type);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_filterType(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->filter_type = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_get_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->width);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->width = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}









CEXPORT bool def_timestep_view_get_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setNumber(thiz->height);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_view_set_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_view *thiz = (timestep_view*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->height = vp.toNumber();
		
	}
	JS_EndRequest(cx);
	return true;
}











static const JSFunctionSpec functions[] = {
	
		JS_FN("addSubview", def_timestep_view_addSubview, 1, FUNCTION_FLAGS),
	
		JS_FN("removeSubview", def_timestep_view_removeSubview, 1, FUNCTION_FLAGS),
	
		JS_FN("getSuperview", def_timestep_view_getSuperview, 0, FUNCTION_FLAGS),
	
		JS_FN("getSubviews", def_timestep_view_getSubviews, 0, FUNCTION_FLAGS),
	
		JS_FN("wrapRender", def_timestep_view_wrapRender, 2, FUNCTION_FLAGS),
	
		JS_FN("wrapTick", def_timestep_view_wrapTick, 1, FUNCTION_FLAGS),
	
		JS_FN("localizePoint", def_timestep_view_localizePoint, 1, FUNCTION_FLAGS),
	
		JS_FS_END
};



#define BAR_PROPERTY_FLAGS (JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_SHARED)

static const JSPropertySpec properties[] = {
	{ "compositeOperation", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_compositeOperation), JSOP_WRAPPER(def_timestep_view_set_compositeOperation) },
	{ "x", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_x), JSOP_WRAPPER(def_timestep_view_set_x) },
	{ "y", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_y), JSOP_WRAPPER(def_timestep_view_set_y) },
	{ "offsetX", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_offsetX), JSOP_WRAPPER(def_timestep_view_set_offsetX) },
	{ "offsetY", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_offsetY), JSOP_WRAPPER(def_timestep_view_set_offsetY) },
	{ "r", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_r), JSOP_WRAPPER(def_timestep_view_set_r) },
	{ "flipX", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_flipX), JSOP_WRAPPER(def_timestep_view_set_flipX) },
	{ "flipY", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_flipY), JSOP_WRAPPER(def_timestep_view_set_flipY) },
	{ "anchorX", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_anchorX), JSOP_WRAPPER(def_timestep_view_set_anchorX) },
	{ "anchorY", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_anchorY), JSOP_WRAPPER(def_timestep_view_set_anchorY) },
	{ "opacity", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_opacity), JSOP_WRAPPER(def_timestep_view_set_opacity) },
	{ "scale", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_scale), JSOP_WRAPPER(def_timestep_view_set_scale) },
	{ "scaleX", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_scaleX), JSOP_WRAPPER(def_timestep_view_set_scaleX) },
	{ "scaleY", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_scaleY), JSOP_WRAPPER(def_timestep_view_set_scaleY) },
	{ "absScale", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_absScale), JSOP_WRAPPER(def_timestep_view_set_absScale) },
	{ "clip", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_clip), JSOP_WRAPPER(def_timestep_view_set_clip) },
	{ "backgroundColor", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_backgroundColor), JSOP_WRAPPER(def_timestep_view_set_backgroundColor) },
	{ "visible", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_visible), JSOP_WRAPPER(def_timestep_view_set_visible) },
	{ "hasJSRender", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_hasJSRender), JSOP_WRAPPER(def_timestep_view_set_hasJSRender) },
	{ "hasJSTick", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_hasJSTick), JSOP_WRAPPER(def_timestep_view_set_hasJSTick) },
	{ "zIndex", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_zIndex), JSOP_WRAPPER(def_timestep_view_set_zIndex) },
	{ "filterColor", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_filterColor), JSOP_WRAPPER(def_timestep_view_set_filterColor) },
	{ "filterType", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_filterType), JSOP_WRAPPER(def_timestep_view_set_filterType) },
	{ "width", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_width), JSOP_WRAPPER(def_timestep_view_set_width) },
	{ "_width", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get__width), JSOP_WRAPPER(def_timestep_view_set__width) },
	{ "height", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get_height), JSOP_WRAPPER(def_timestep_view_set_height) },
	{ "_height", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_view_get__height), JSOP_WRAPPER(def_timestep_view_set__height) },
	
	{0}
};

#undef BAR_PROPERTY_FLAGS


static const JSClass timestep_view_class = {
	"View",
	JSCLASS_HAS_PRIVATE,
	JS_PropertyStub, JS_DeletePropertyStub, JS_PropertyStub, JS_StrictPropertyStub,
	JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, def_timestep_view_class_finalize,
	JSCLASS_NO_OPTIONAL_MEMBERS
};

CEXPORT JSObject *timestep_view_create_ctor_object(JSContext *cx, jsval *vp) {
	return JS_NewObjectForConstructor(cx, (JSClass*)&timestep_view_class, vp);
}

CEXPORT void timestep_view_add_to_object(JSObject *parent) {
	JSContext *cx = get_js_context();
	JS_InitClass(cx, parent, NULL, (JSClass*)&timestep_view_class, def_timestep_view_class_constructor,
		1, (JSPropertySpec *)properties, (JSFunctionSpec *)functions, NULL, NULL);
}
