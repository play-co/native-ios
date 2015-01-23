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

CEXPORT bool def_timestep_view_class_constructor(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);

  JS::RootedObject thiz(cx, timestep_view_create_ctor_object(cx, vp));
	if (!thiz) {
		return false;
	}

	timestep_view *view = timestep_view_init();

	JS_SetPrivate(thiz, view);
  
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

  JSObject* js_view = nullptr;
	if (argc >= 1 && !JSVAL_IS_PRIMITIVE(args[0])) {
		js_view = JSVAL_TO_OBJECT(args[0]);
  }
  view->js_view = js_view;
  
	bool has_jsrender = false;
  JS::RootedValue render_val(cx);
	JS_GetProperty(cx, js_view, "render", &render_val);
	if (!JSVAL_IS_PRIMITIVE(render_val)) {
		JSObject *render = JSVAL_TO_OBJECT(render_val);
		if (render && JS_ObjectIsFunction(cx, render)) {
      JS::RootedValue has_native_render_val(cx);
			JS_GetProperty(cx, render, "HAS_NATIVE_IMPL", &has_native_render_val);
			if (JSVAL_IS_BOOLEAN(has_native_render_val) && JSVAL_TO_BOOLEAN(has_native_render_val)) {
				has_jsrender = false;
			} else {
				has_jsrender = true;
			}
		}
	}
	view->has_jsrender = has_jsrender;

  JS::RootedValue tick_val(cx);
	JS_GetProperty(cx, js_view, "tick", &tick_val);
	if (!JSVAL_IS_PRIMITIVE(tick_val)) {
		JSObject *tick = JSVAL_TO_OBJECT(tick_val);
		if (tick && JS_ObjectIsFunction(cx, tick)) {
			view->has_jstick = true;
		} else {
			view->has_jstick = false;
		}
	}

  JS::RootedValue type_val(cx);
	JS_GetProperty(cx, js_view, "__type", &type_val);
  int view_type;
  JS::ToInt32(cx, type_val, &view_type);
	timestep_view_set_type(view, view_type);
  
  args.rval().set(OBJECT_TO_JSVAL(thiz));
  
	return true;
}


CEXPORT bool def_image_view_set_image(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);

	jsval *argv = JS_ARGV(cx, vp);

	if (argc < 2 || JSVAL_IS_PRIMITIVE(argv[0]) || JSVAL_IS_PRIMITIVE(argv[1])) {
		JS_ReportError(cx, "Invalid arguments to setImageOnImageView");

		return false;
	} else {
    JS::RootedObject view_obj(cx, JSVAL_TO_OBJECT(argv[0]));
    JS::RootedObject map_obj(cx, JSVAL_TO_OBJECT(argv[1]));
    
		timestep_view *view = (timestep_view *)JS_GetPrivate(view_obj);
		timestep_image_map *map = (timestep_image_map *)JS_GetPrivate(map_obj);

		js_object_wrapper_root(&view->map_ref, map_obj.get());
		view->view_data = map;

		return true;
	}
}

static const char *NAME_ARRAY[11] = {
	"source-atop",
	"source-in",
	"source-out",
	"source-over",
	"destination-atop",
	"destination-in",
	"destination-out",
	"destination-over",
	"lighter",
	"xor",
	"copy"
};

CEXPORT bool def_timestep_view_get_compositeOperation(JSContext *cx, JS::HandleObject obj, JS::HandleId id, JS::MutableHandleValue vp) {
	JSAutoRequest areq(cx);

	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);
	if (view) {
		const char *name = 0;
		int op = view->composite_operation;

		if (op >= 1337 && op <= 1347) {
			name = NAME_ARRAY[op - 1337];
		}

		if (!name) {
			vp.setUndefined();
		} else {
			vp.setString(JS_NewStringCopyN(cx, name, strlen(name)));
		}
	}

	return true;
}

static __attribute__((always_inline)) void print_invalid_composite_op_warning(const char * code) {
  LOG("{view} WARNING: View given invalid composite operation %s", code);
}

CEXPORT bool def_timestep_view_set_compositeOperation(JSContext *cx,
                                                      JS::HandleObject obj,
                                                      JS::HandleId id,
                                                      bool strict,
                                                      JS::MutableHandleValue vp) {
  JSAutoRequest areq(cx);
	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);
  
	if (view) {
		int op = 0;

		if (vp.isString()) {
      JS::RootedString jstr(cx, JSVAL_TO_STRING(vp));
			JSTR_TO_CSTR(cx, jstr, code);
      switch (code[0]) {
        case 'l':
          op = 1345;
          break;
        case 'x':
          op = 1346;
          break;
        case 'c':
          op = 1347;
          break;
        case 's':
          if (0 == strcmp(code, "source-atop")) {
            op = 1337;
          } else if (0 == strcmp(code, "source-in")) {
            op = 1338;
          } else if (0 == strcmp(code, "source-out")) {
            op = 1339;
          } else if (0 == strcmp(code, "source-over")) {
            op = 1340;
          } else {
            print_invalid_composite_op_warning(code);
          }
          break;
        case 'd':
          if (0 == strcmp(code, "destination-atop")) {
            op = 1341;
          } else if (0 == strcmp(code, "destination-in")) {
            op = 1342;
          } else if (0 == strcmp(code, "destination-out")) {
            op = 1343;
          } else if (0 == strcmp(code, "destination-over")) {
            op = 1344;
          } else {
            print_invalid_composite_op_warning(code);
          }
          break;
        case '\0':
          // Clear composite op on empty string
          break;
        default:
          // If code is not empty, it must be an invalid operation.
          print_invalid_composite_op_warning(code);
          break;
      }
		}

		view->composite_operation = op;
	}

	return true;
}

CEXPORT bool def_timestep_view_set_opacity(JSContext *cx,
                                           JS::HandleObject obj,
                                           JS::HandleId id,
                                           bool strict,
                                           JS::MutableHandleValue vp) {
	JSAutoRequest areq(cx);

	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);
	view->opacity = vp.isNumber() ? vp.toNumber() : 1.0;

	return true;
}

CEXPORT bool def_timestep_view_set_zIndex(JSContext *cx,
                                          JS::HandleObject obj,
                                          JS::HandleId id,
                                          bool strict,
                                          JS::MutableHandleValue vp) {
	JSAutoRequest areq(cx);

	timestep_view *view = (timestep_view *)JS_GetPrivate(obj);

	if (vp.isNumber()) {
		view->z_index = vp.toNumber();
    
		timestep_view *superview = timestep_view_get_superview(view);
		if (superview) {
			superview->dirty_z_index = true;
		}
	}

	return true;
}

CEXPORT void def_timestep_view_render(JSObject* view,
                                      JSObject* ctx,
                                      JSObject* opts) {

	static const char *renderFunctionName = "render";
	JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
  JS::RootedValue fn(cx);
	bool success = JS_GetProperty(cx, view, renderFunctionName, &fn);
  JS::RootedObject fn_obj(cx, JSVAL_TO_OBJECT(fn));
	if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
    JS::RootedValue rval(cx);
    JS::Value args[] = {
      JS::ObjectValue(*ctx),
      JS::ObjectValue(*opts)
    };
		JS_CallFunctionName(cx, view, renderFunctionName, 2, args, rval.address());
	}
}

CEXPORT JSObject* def_get_viewport(JSObject* js_opts) {
	JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
	JS::RootedValue val(cx);
	JS_GetProperty(cx, js_opts, "viewport", &val);
  
  return JSVAL_TO_OBJECT(val);
}

CEXPORT void def_restore_viewport(JSObject* js_opts, JSObject* js_viewport) {
	JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
  JS::RootedValue val(cx, OBJECT_TO_JSVAL(js_viewport));
	JS_SetProperty(cx, js_opts, "viewport", val);
}

CEXPORT void def_timestep_view_tick(JSObject* js_view, double dt) {
	static const char *name = "tick";
	JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
  JS::RootedValue fn(cx);

	bool success = JS_GetProperty(cx, js_view, name, &fn);
  JS::RootedObject fn_obj(cx, JSVAL_TO_OBJECT(fn));
	if (success && fn_obj && JS_ObjectIsFunction(cx, fn_obj)) {
    JS::RootedValue rval(cx);
    JS::Value args[] = {JS::NumberValue(dt)};
		JS_CallFunctionName(cx, js_view, name, 1, args, rval.address());
	}

}

CEXPORT bool def_timestep_view_addSubview(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
  
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
  
  JS::RootedObject subview_obj(cx, args[0].toObjectOrNull());
	JS::RootedValue _view(cx);
	JS_GetProperty(cx, subview_obj, "__view", &_view);
	if (!JSVAL_IS_PRIMITIVE(_view)) {
		timestep_view *subview = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(_view));
		bool result = timestep_view_add_subview(view, subview);

		// Set result based on add_subview return value
    args.rval().setBoolean(!!result);
	}

	return true;
}

CEXPORT bool def_timestep_view_removeSubview(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
  JS::RootedObject subview_obj(cx, JSVAL_TO_OBJECT(args[0]));
	JS::RootedValue _view(cx);
	JS_GetProperty(cx, subview_obj, "__view", &_view);
  
	bool result = false;
	if (!JSVAL_IS_PRIMITIVE(_view)) {
		timestep_view *subview = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(_view));
		result = timestep_view_remove_subview(view, subview);
	}

  args.rval().setBoolean(result);
	return true;
}

CEXPORT bool def_timestep_view_getSuperview(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
  
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	timestep_view *superview = timestep_view_get_superview(view);
  JS::RootedValue rval(cx, JS::NullValue());
  if (view && superview) {
    JS::RootedObject js_view(cx, (JSObject*)superview->js_view);
    rval = JS::ObjectValue(*js_view);
  }
  
  args.rval().set(rval);

	return true;
}

// we only call wrapRender from JS once on the root view
// to start the render
CEXPORT bool def_timestep_view_wrapRender(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest ar(cx);
  JS::CallArgs args = CallArgsFromVp(argc, vp);

	JS::RootedObject thiz_val(cx, JSVAL_TO_OBJECT(JS_THIS(cx, vp)));
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz_val);
  
  // JS::HandleValue ctx_val = args[0];
  JS::RootedObject js_ctx(cx, args[0].toObjectOrNull());
  
	JS::RootedValue _ctx_val(cx);
	JS_GetProperty(cx, js_ctx, "_ctx", &_ctx_val);
  JS::RootedObject _ctx(cx, _ctx_val.toObjectOrNull());
  JS::RootedObject js_opts(cx, args[1].toObjectOrNull());
  
	context_2d *ctx = (context_2d*)JS_GetPrivate(_ctx);

	// reset the render properties (e.g. absScale)
	timestep_view_start_render();

	// recursively render all views/subviews
	timestep_view_wrap_render(view, ctx, js_ctx, js_opts);

	return true;
}


CEXPORT bool def_timestep_view_wrapTick(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);

	double dt;
  
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedValue in(cx, args[0]);
  JS::ToNumber(cx, in, &dt);
  JS::RootedObject thiz(cx, args.thisv().toObjectOrNull());
  
	timestep_view *view = (timestep_view *)JS_GetPrivate(thiz);
	timestep_view_wrap_tick(view, dt);
	return true;
}


CEXPORT bool def_timestep_view_getSubviews(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);

  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, args.thisv().toObjectOrNull());
	timestep_view *v = (timestep_view *)JS_GetPrivate(thiz);
  JS::RootedObject subviews(cx, JS_NewArrayObject(cx, v->subview_count, 0));
  
	for (int i = 0; i < v->subview_count; i++) {
		timestep_view *subview = v->subviews[i];

    JS::RootedValue value(cx, OBJECT_TO_JSVAL((JSObject*)subview->js_view));
		JS_SetElement(cx, subviews, i, &value);
	}
  
  args.rval().setObject(*subviews);

	return true;
}

CEXPORT bool def_timestep_view_localizePoint(JSContext *cx, unsigned argc, jsval *vp) {
	JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
	timestep_view *v = (timestep_view *)JS_GetPrivate(thiz);
  
  JS::RootedObject pt(cx, JSVAL_TO_OBJECT(args[0]));
	JS::RootedValue x_val(cx), y_val(cx);
	JS_GetProperty(cx, pt, "x", &x_val);
	JS_GetProperty(cx, pt, "y", &y_val);
	double x;
  JS::ToNumber(cx, x_val, &x);
	double y;
  JS::ToNumber(cx, y_val, &y);


	x -= v->x + v->anchor_x + v->offset_x;
	y -= v->y + v->anchor_y + v->offset_y;

	if (v->r) {
		double cosr = cos(-(v->r));
		double sinr = sin(-(v->r));
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

  JS::RootedValue new_x(cx, JS::NumberValue(x));
  JS::RootedValue new_y(cx, JS::NumberValue(y));
  
	JS_SetProperty(cx, pt, "x", new_x);
	JS_SetProperty(cx, pt, "y", new_y);
  
  args.rval().setObject(*pt);

	return true;
}

CEXPORT bool def_timestep_view_get__width(JSContext *cx,
                                          JS::HandleObject obj,
                                          JS::HandleId id,
                                          JS::MutableHandleValue vp) {
	return def_timestep_view_get_width(cx, obj, id, vp);
}

CEXPORT bool def_timestep_view_set__width(JSContext *cx,
                                          JS::HandleObject obj,
                                          JS::HandleId id,
                                          bool strict,
                                          JS::MutableHandleValue vp) {
	return def_timestep_view_set_width(cx, obj, id, strict, vp);
}

CEXPORT bool def_timestep_view_get__height(JSContext *cx,
                                           JS::HandleObject obj,
                                           JS::HandleId id,
                                           JS::MutableHandleValue vp) {
	return def_timestep_view_get_height(cx, obj, id, vp);
}

CEXPORT bool def_timestep_view_set__height(JSContext *cx,
                                           JS::HandleObject obj,
                                           JS::HandleId id,
                                           bool strict,
                                           JS::MutableHandleValue vp) {
	return def_timestep_view_set_height(cx, obj, id, strict, vp);
}


