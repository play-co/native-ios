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

#include "js_timestep_image_map_template.gen.h"
#include "js/js_timestep_image_map.h"


#include "core/timestep/timestep_image_map.h"


#include "js/js_core.h"



CEXPORT bool def_timestep_image_map_get_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->x);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_x(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->x = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->y);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_y(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->y = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->width);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_width(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->width = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->height);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_height(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->height = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_marginTop(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->margin_top);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_marginTop(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->margin_top = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_marginRight(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->margin_right);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_marginRight(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->margin_right = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_marginBottom(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->margin_bottom);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_marginBottom(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->margin_bottom = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_marginLeft(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setInt32(thiz->margin_left);
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_marginLeft(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		thiz->margin_left = vp.toInt32();
		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_get_url(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		vp.setString(JS_NewStringCopyZ(cx, thiz->url));

		
	}
	JS_EndRequest(cx);
	return true;
}



CEXPORT bool def_timestep_image_map_set_url(JSContext *cx, JS::HandleObject obj, JS::HandleId id, bool strict, JS::MutableHandleValue vp) {
	JS_BeginRequest(cx);
	timestep_image_map *thiz = (timestep_image_map*)JS_GetPrivate(obj.get());
	if (thiz) {
		
		if (vp.isString()) {
	JSString *jstr = vp.toString();

	JSTR_TO_CSTR_PERSIST(cx, jstr, cstr);

	if (thiz->url) {
		free(thiz->url);
	}

	thiz->url = cstr;
}

		
	}
	JS_EndRequest(cx);
	return true;
}





static const JSFunctionSpec functions[] = {
	
		JS_FS_END
};



#define BAR_PROPERTY_FLAGS (JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_SHARED)

static const JSPropertySpec properties[] = {
	{ "x", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_x), JSOP_WRAPPER(def_timestep_image_map_set_x) },
	{ "y", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_y), JSOP_WRAPPER(def_timestep_image_map_set_y) },
	{ "width", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_width), JSOP_WRAPPER(def_timestep_image_map_set_width) },
	{ "height", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_height), JSOP_WRAPPER(def_timestep_image_map_set_height) },
	{ "marginTop", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_marginTop), JSOP_WRAPPER(def_timestep_image_map_set_marginTop) },
	{ "marginRight", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_marginRight), JSOP_WRAPPER(def_timestep_image_map_set_marginRight) },
	{ "marginBottom", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_marginBottom), JSOP_WRAPPER(def_timestep_image_map_set_marginBottom) },
	{ "marginLeft", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_marginLeft), JSOP_WRAPPER(def_timestep_image_map_set_marginLeft) },
	{ "url", 0, BAR_PROPERTY_FLAGS,
		JSOP_WRAPPER(def_timestep_image_map_get_url), JSOP_WRAPPER(def_timestep_image_map_set_url) },
	
	{0}
};

#undef BAR_PROPERTY_FLAGS


static const JSClass timestep_image_map_class = {
	"ImageMap",
	JSCLASS_HAS_PRIVATE,
	JS_PropertyStub, JS_DeletePropertyStub, JS_PropertyStub, JS_StrictPropertyStub,
	JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, def_timestep_image_map_class_finalize,
	JSCLASS_NO_OPTIONAL_MEMBERS
};

CEXPORT JSObject *timestep_image_map_create_ctor_object(JSContext *cx, jsval *vp) {
	return JS_NewObjectForConstructor(cx, (JSClass*)&timestep_image_map_class, vp);
}

CEXPORT void timestep_image_map_add_to_object(JSObject *parent) {
	JSContext *cx = get_js_context();
	JS_InitClass(cx, parent, NULL, (JSClass*)&timestep_image_map_class, def_timestep_image_map_class_constructor,
		12, (JSPropertySpec *)properties, (JSFunctionSpec *)functions, NULL, NULL);
}
