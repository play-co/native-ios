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

#include "js/js_animate.h"
CEXPORT {
#include "core/log.h"
}
#include "js/js_core.h"
#include "core/timestep/timestep_image_map.h"
#include <math.h>

static inline void build_style_frame(anim_frame *frame, JSObject *target) {

	#define ADD_PROP(const_name, prop)								\
		_ADD_PROP(const_name, prop, false);							\
		_ADD_PROP(const_name, d ## prop, true);

	#define _ADD_PROP(const_name, prop, _is_delta) do {				\
		jsval value;												\
		JS_GetProperty(cx, target, #prop, &value);					\
		double prop_val;											\
		JS_ValueToNumber(cx, value, &prop_val);						\
		if (!isnan(prop_val)) {										\
			style_prop *p = anim_frame_add_style_prop(frame);		\
			p->name = const_name;									\
			p->is_delta = _is_delta;								\
			p->target = prop_val;									\
		}															\
	} while(0)
	JSContext *cx = get_js_context();
	ADD_PROP(X, x);
	ADD_PROP(Y, y);
	ADD_PROP(WIDTH, width);
	ADD_PROP(HEIGHT, height);
	ADD_PROP(R, r);
	ADD_PROP(ANCHOR_X, anchorX);
	ADD_PROP(ANCHOR_Y, anchorY);
	ADD_PROP(OPACITY, opacity);
	ADD_PROP(SCALE, scale);
	ADD_PROP(SCALE_X, scaleX);
	ADD_PROP(SCALE_Y, scaleY);

	frame->type = STYLE_FRAME;
}

static inline void build_func_frame(anim_frame *frame, JSObject *cb) {
	js_object_wrapper_root(&frame->cb, cb);
	frame->type = FUNC_FRAME;
}

static inline void build_frame(JSContext *cx, JSObject *target, unsigned argc, jsval *vp, void (*next)(view_animation *, anim_frame *, unsigned int, unsigned int)) {
	LOGFN("build_frame");
	
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation*)JS_GetPrivate(thiz);
	anim_frame *frame = anim_frame_get();

	// TODO: what if these defaults change? it probably won't...
	int32_t duration = 500;
	int32_t transition = 0;
	if (JS_ObjectIsFunction(cx, target)) {
		duration = 0;
		build_func_frame(frame, target);
	} else {
		build_style_frame(frame, target);
	}

	jsval *vals = JS_ARGV(cx, vp);
	if (argc > 1) {
		duration = JSValToInt32(cx, vals[1], duration);
		if (argc > 2) {
			transition = JSValToInt32(cx, vals[2], transition);
		}
	}

	next(anim, frame, duration, transition);

	LOGFN("end build_frame");
}



CEXPORT JSBool def_animate_now(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);
	
	jsval *vals = JS_ARGV(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));

	if (JSVAL_IS_OBJECT(*vals)) {
		JSObject *target = JSVAL_TO_OBJECT(*vals);
		if (target) {
			build_frame(cx, target, argc, vp, view_animation_now);
		}
	}
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_then(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	jsval *vals = JS_ARGV(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));

	if (JSVAL_IS_OBJECT(*vals)) {
		JSObject *target = JSVAL_TO_OBJECT(*vals);
		if (target) {
			build_frame(cx, target, argc, vp, view_animation_then);
		}
	}
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_commit(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	view_animation_commit(anim);
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_clear(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	view_animation_clear(anim);
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_wait(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	jsval *vals = JS_ARGV(cx, vp);
	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	double dt;
	JS_ValueToNumber(cx, *vals, &dt);
	view_animation_wait(anim, dt);
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_pause(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	view_animation_pause(anim);
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_resume(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	view_animation_resume(anim);
	jsval thiz_val = OBJECT_TO_JSVAL(thiz);
	JS_SET_RVAL(cx, vp, thiz_val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_isPaused(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	
	jsval val = BOOLEAN_TO_JSVAL(anim->is_paused);
	JS_SET_RVAL(cx, vp, val);

	JS_EndRequest(cx);
	return JS_TRUE;
}

CEXPORT JSBool def_animate_hasFrames(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = JSVAL_TO_OBJECT(JS_THIS(cx, vp));
	view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
	jsval val = BOOLEAN_TO_JSVAL((bool)anim->frame_head);
	JS_SET_RVAL(cx, vp, val);

	JS_EndRequest(cx);
	return JS_TRUE;
}


CEXPORT void def_animate_class_finalize(JSFreeOp *fop, JSObject *obj) {
	view_animation *anim = (view_animation *)JS_GetPrivate(obj);
	if (anim) {
		view_animation_release(anim);
	}
}

CEXPORT JSBool def_animate_class_constructor(JSContext *cx, unsigned argc, jsval *vp) {
	JS_BeginRequest(cx);

	JSObject *thiz = animate_create_ctor_object(cx, vp);
	if (!thiz) {
		return JS_FALSE;
	}

	jsval *argv = JS_ARGV(cx, vp);

	if (unlikely(argc < 2 || !JSVAL_IS_OBJECT(argv[0]) || !JSVAL_IS_OBJECT(argv[1]))) {
		LOG("{animate} ERROR: Animate constructor arguments were invalid!");

		JS_EndRequest(cx);
		return JS_FALSE;
	} else {
		JSObject *js_timestep_view = JSVAL_TO_OBJECT(argv[0]), *js_group = JSVAL_TO_OBJECT(argv[1]);

		jsval __view;
		JS_GetProperty(cx, js_timestep_view, "__view", &__view);
		timestep_view *view = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(__view));
		if (view) {
			view_animation *anim = view_animation_init(view);
			
			JS_SetPrivate(thiz, (void*)anim);
			anim->js_anim = thiz;
			
			js_object_wrapper_root(&anim->js_group, js_group);
		}
		
		JS_SET_RVAL(cx, vp, OBJECT_TO_JSVAL(thiz));

		JS_EndRequest(cx);
		return JS_TRUE;
	}
}

void def_animate_finish(void *a) {
	JSObject *js_anim = (JSObject*)a;
	LOGFN("js_animate_finish");
	JSContext *cx = get_js_context();

	JS_BeginRequest(cx);

	view_animation *anim = (view_animation *)JS_GetPrivate(js_anim);
	JSObject *js_group = (JSObject*)anim->js_group;
	jsval finish_val;
	JS_GetProperty(cx, js_group, "onAnimationFinish", &finish_val);
	if (JSVAL_IS_OBJECT(finish_val)) {
		JSObject *finish = JSVAL_TO_OBJECT(finish_val);
		jsval args[] = {OBJECT_TO_JSVAL(js_anim)};
		if (JS_ObjectIsFunction(cx, finish)) {
			jsval ret;
			JS_CallFunctionValue(cx, js_group, finish_val, 1, args, &ret);
		}
	}

	JS_EndRequest(cx);

	LOGFN("end def_animate_finish");
}

void def_animate_cb(void *view, void *cb, double tt, double t) {
	JSObject *js_view = (JSObject*)view;
	JSObject *js_cb = (JSObject*)cb;
	jsval args[2] = {DOUBLE_TO_JSVAL(tt),DOUBLE_TO_JSVAL(t)};
	JSContext *cx = get_js_context();

	JS_BeginRequest(cx);
	
	jsval ret;
	JS_CallFunctionValue(cx, js_view, OBJECT_TO_JSVAL(js_cb), 2, args, &ret);

	JS_EndRequest(cx);
}
