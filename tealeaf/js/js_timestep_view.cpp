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
#include "core/timestep/timestep_view.h"
#include "js/js_timestep_view.h"
#include "core/timestep/timestep_image_map.h"
#include <math.h>
#include "js/js_core.h"
#include "core/log.h"

// TODO: I am a little worried about not tracking the lifetime of the front-end
// View object here.  If the view backing is finalized in a different step,
// then it could be referencing the front-end View after it is destroyed.

// View backing finalizer
CEXPORT void def_timestep_view_class_finalize(JSFreeOp *fop, JSObject *obj) {
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);
	if (view) {
		timestep_view_delete(view);
	}
}

CEXPORT JSBool def_timestep_view_class_constructor(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = timestep_view_create_ctor_object(cx, vp);
	if (!thiz) {
		return JS_FALSE;
	}

	timestep_view *view = timestep_view_init();

	JS_SetPrivate(thiz, view);

	JSObject *js_view = NULL;
	jsval *argv = JS_ARGV(cx, vp);
	if (argc >= 1 && JSVAL_IS_OBJECT(argv[0])) {
		js_view = JSVAL_TO_OBJECT(argv[0]);
	}
	view->js_view = js_view;

	bool has_jsrender = false;
	jsval render_val;
	JS_GetProperty(cx, js_view, "render", &render_val);
	if (JSVAL_IS_OBJECT(render_val)) {
		JSObject *render = JSVAL_TO_OBJECT(render_val);
		if (render && JS_ObjectIsFunction(cx, render)) {
			jsval has_native_render_val;
			JS_GetProperty(cx, render, "HAS_NATIVE_IMPL", &has_native_render_val);
			if (JSVAL_IS_BOOLEAN(has_native_render_val) && JSVAL_TO_BOOLEAN(has_native_render_val)) {
				has_jsrender = false;
			} else {
				has_jsrender = true;
			}
		}
	}
	view->has_jsrender = has_jsrender;

	jsval tick_val;
	JS_GetProperty(cx, js_view, "tick", &tick_val);
	if (JSVAL_IS_OBJECT(tick_val)) {
		JSObject *tick = JSVAL_TO_OBJECT(tick_val);
		if (tick && JS_ObjectIsFunction(cx, tick)) {
			view->has_jstick = true;
		} else {
			view->has_jstick = false;
		}
	}

	jsval type_val;
	JS_GetProperty(cx, js_view, "__type", &type_val);
	timestep_view_set_type(view, JSVAL_TO_INT(type_val));

	JS_SET_RVAL(cx, vp, OBJECT_TO_JSVAL(thiz));

	JS_EndRequest(cx);
	return JS_TRUE;
}


CEXPORT JSBool def_image_view_set_image(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *argv = JS_ARGV(cx, vp);

	if (argc < 2 || !JSVAL_IS_OBJECT(argv[0]) || !JSVAL_IS_OBJECT(argv[1])) {
		JS_ReportError(cx, "Invalid arguments to setImageOnImageView");

		JS_EndRequest(cx);
		return JS_FALSE;
	} else {
		JSObject *view_obj = JSVAL_TO_OBJECT(argv[0]), *map_obj = JSVAL_TO_OBJECT(argv[1]);
		timestep_view *view = (timestep_view *)JS_GetPrivate(view_obj);
		timestep_image_map *map = (timestep_image_map *)JS_GetPrivate(map_obj);

		js_object_wrapper_root(&view->map_ref, map_obj);
		view->view_data = map;
		
		JS_EndRequest(cx);
		return JS_TRUE;
	}
}


#define DIM_SET(cx, obj, vp, field) \
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj); \
	if (view) { \
		double field = view->field; \
		view->field = vp.isNumber() ? vp.toNumber() : UNDEFINED_DIMENSION; \
		if (field != view->field) { \
			def_timestep_view_needs_reflow(view->js_view, true); \
		} \
	}

#define DIM_GET(cx, obj, vp, field) \
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj.get()); \
	vp.set((!view || view->field == UNDEFINED_DIMENSION) ? JSVAL_VOID : DOUBLE_TO_JSVAL(view->field));


CEXPORT JSBool def_timestep_view_set_width(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_SET(cx, obj, vp, width);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_get_width(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_GET(cx, obj, vp, width);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_set_height(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	DIM_SET(cx, obj, vp, height);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_get_height(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_GET(cx, obj, vp, height);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_set_widthPercent(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_SET(cx, obj, vp, width_percent);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_get_widthPercent(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	DIM_GET(cx, obj, vp, width_percent);
	
	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_set_heightPercent(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_SET(cx, obj, vp, height_percent);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_get_heightPercent(JSContext *cx, JSHandleObject obj, JSHandleId id, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);

	DIM_GET(cx, obj, vp, height_percent);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_set_opacity(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);

	view->opacity = vp.isNumber() ? vp.toNumber() : 1.0;

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_set_zIndex(JSContext *cx, JSHandleObject obj, JSHandleId id, JSBool strict, JSMutableHandleValue vp) {
	JS_BeginRequest(cx);
	
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);

	if (vp.isNumber()) {
		view->z_index = vp.toNumber();

		timestep_view *superview = timestep_view_get_superview(view);
		if (superview) {
			superview->dirty_z_index = true;
		}
	}

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT void def_timestep_view_build_view(void *data) {
	JSObject *js_view = (JSObject*)data;
	jsval fn;
	static const char *name = "buildView";
	JSContext *cx = get_js_context();
	JSBool success = JS_GetProperty(cx, js_view, name, &fn);
	JSObject *fn_obj = JSVAL_TO_OBJECT(fn);
	if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
		jsval rval;
		JS_CallFunctionName(cx, js_view, name, 0, NULL, &rval);
	}
}

CEXPORT void def_timestep_view_render(void *view, void *ctx, void *opts) {
	JSObject *js_view = (JSObject*)view;
	JSObject *js_ctx = (JSObject*)ctx;
	JSObject *js_opts = (JSObject*)opts;
	jsval fn;
	static const char *name = "render";
	JSContext *cx = get_js_context();
	JSBool success = JS_GetProperty(cx, js_view, name, &fn);
	JSObject *fn_obj = JSVAL_TO_OBJECT(fn);
	if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
		jsval rval;
		jsval args[] = {OBJECT_TO_JSVAL(js_ctx), OBJECT_TO_JSVAL(js_opts)};
		JS_CallFunctionName(cx, js_view, name, 2, args, &rval);
		
	}
}

CEXPORT JSObject *def_get_viewport(JSObject *js_opts) {
	JSContext *cx = get_js_context();
	jsval val;

	JS_GetProperty(cx, js_opts, "viewport", &val);

	if (JSVAL_IS_OBJECT(val)) {
		return JSVAL_TO_OBJECT(val);
	} else {
		return NULL;
	}
}

CEXPORT void def_restore_viewport(JSObject *js_opts, JSObject *js_viewport) {
	if (js_viewport) {
		JSContext *cx = get_js_context();
		jsval val = OBJECT_TO_JSVAL(js_viewport);

		JS_SetProperty(cx, js_opts, "viewport", &val);
	}
}

CEXPORT void def_timestep_view_tick(void *data, double dt) {
	JSObject *js_view = (JSObject*)data;
	jsval fn;
	static const char *name = "tick";
	JSContext *cx = get_js_context();

	JS_BeginRequest(cx);
	
	JSBool success = JS_GetProperty(cx, js_view, name, &fn);
	JSObject *fn_obj = JSVAL_TO_OBJECT(fn);
	if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
		jsval rval;
		jsval dt_val = DOUBLE_TO_JSVAL(dt);
		jsval args[] = {dt_val};
		JS_CallFunctionName(cx, js_view, name, 1, args, &rval);
	}

	JS_EndRequest(cx);
}

CEXPORT void def_timestep_view_needs_reflow(void *data, bool force) {
	JSObject *js_view = (JSObject*)data;

	// If js_view is valid,
	if (js_view) {
		jsval fn;
		static const char *name = "needsReflow";

		JSContext *cx = get_js_context();
		
		JS_BeginRequest(cx);

		JSBool success = JS_GetProperty(cx, js_view, name, &fn);
		JSObject *fn_obj = JSVAL_TO_OBJECT(fn);

		if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
			jsval force_val = BOOLEAN_TO_JSVAL(force);
			jsval rval;
			jsval args[] = {force_val};
			JS_CallFunctionName(cx, js_view, name, 1, args, &rval);
		}

		JS_EndRequest(cx);
	}
}

CEXPORT JSBool def_timestep_view_addSubview(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	JSObject *subview_obj = JSVAL_TO_OBJECT(*vals);
	jsval _view;
	JS_GetProperty(cx, subview_obj, "__view", &_view);
	if (JSVAL_IS_OBJECT(_view)) {
		timestep_view *subview = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(_view));
		bool result = timestep_view_add_subview(view, subview);

		// Set result based on add_subview return value
		JS_SET_RVAL(cx, vp, BOOLEAN_TO_JSVAL(result ? JS_TRUE : JS_FALSE));
	}

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_removeSubview(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	JSObject *subview_obj = JSVAL_TO_OBJECT(*vals);
	jsval _view;
	JS_GetProperty(cx, subview_obj, "__view", &_view);
	bool result;
	if (JSVAL_IS_OBJECT(_view)) {
		timestep_view *subview = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(_view));
		result = timestep_view_remove_subview(view, subview);
	} else {
		result = false;
	}
	jsval rval = BOOLEAN_TO_JSVAL(result);

	JS_SET_RVAL(cx, vp, rval);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_getSuperview(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	timestep_view *superview = timestep_view_get_superview(view);
	jsval rval;
	if (!view) {
		rval = JSVAL_NULL;
	} else {
		if (superview) {
			JSObject *js_view = (JSObject*)superview->js_view;
			rval = OBJECT_TO_JSVAL(js_view);
		} else {
			rval = JSVAL_NULL;
		}
	}
	
	JS_SET_RVAL(cx, vp, rval);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_wrapRender(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	jsval thiz_val = JS_THIS(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(thiz_val);
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	jsval ctx_val = *vals++;
	JSObject *js_ctx = JSVAL_TO_OBJECT(ctx_val);
	jsval _ctx_val;
	JS_GetProperty(cx, js_ctx, "_ctx", &_ctx_val);
	JSObject *_ctx = JSVAL_TO_OBJECT(_ctx_val);
	jsval opts_val = *vals;
	JSObject *js_opts = JSVAL_TO_OBJECT(opts_val);
	context_2d *ctx = (context_2d*)JS_GetPrivate(_ctx);
	timestep_view_wrap_render(view, ctx, js_ctx, js_opts);

	JS_EndRequest(cx);
	return JS_TRUE;
}


CEXPORT JSBool def_timestep_view_wrapTick(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	jsval thiz_val = JS_THIS(cx, vp);
	double dt;
	JS_ValueToNumber(cx, *vals, (double*)&dt);
	JSObject *thiz = JSVAL_TO_OBJECT(thiz_val);
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	timestep_view_wrap_tick(view, dt);

	JS_EndRequest(cx);
	return JS_TRUE;
}


CEXPORT JSBool def_timestep_view_getSubviews(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval thiz_val = JS_THIS(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(thiz_val);
	timestep_view *v = (timestep_view *)JS_GetPrivate(thiz);
	JSObject *subviews = JS_NewArrayObject(cx, v->subview_count, 0);
	for (int i = 0; i < v->subview_count; i++) {
		timestep_view *subview = v->subviews[i];
		
		jsval value = OBJECT_TO_JSVAL((JSObject*)subview->js_view);
		JS_SetElement(cx, subviews, i, &value);
	}
	jsval ret = OBJECT_TO_JSVAL(subviews);
	JS_SET_RVAL(cx, vp, ret);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_timestep_view_localizePoint(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	jsval thiz_val = JS_THIS(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(thiz_val);
	timestep_view *v = (timestep_view *)JS_GetPrivate(thiz);
	JSObject *pt = JSVAL_TO_OBJECT(*vals);
	jsval x_val, y_val;
	JS_GetProperty(cx, pt, "x", &x_val);
	JS_GetProperty(cx, pt, "y", &y_val);
	double x;
	JS_ValueToNumber(cx, x_val, (double*)&x);
	double y;
	JS_ValueToNumber(cx, y_val, (double*)&y);


	x -= v->x + v->anchor_x + v->offset_x;
	y -= v->y + v->anchor_y + v->offset_y;

	if (v->r) {
		double cosr = cos(v->r);
		double sinr = sin(v->r);
		double x2 = x;
		double y2 = y;
		x = x2 * cosr - y2 * sinr;
		y = x2 * sinr + y2 * cosr;
	}

	if (v->scale != 1) {
		double s = 1 / v->scale;
		x *= s;
		y *= s;
	}

	x += v->anchor_x;
	y += v->anchor_y;

	jsval new_x = DOUBLE_TO_JSVAL(x);
	jsval new_y = DOUBLE_TO_JSVAL(y);

	JSObject *localizedPt = JS_NewObject(cx, NULL, NULL, NULL);

	JS_SetProperty(cx, localizedPt, "x", &new_x);
	JS_SetProperty(cx, localizedPt, "y", &new_y);

	jsval ret = OBJECT_TO_JSVAL(localizedPt);
	JS_SET_RVAL(cx, vp, ret);

	JS_EndRequest(cx);
	return JS_TRUE;
}
