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
  JS::RootedValue value(cx);												\
  JS_GetProperty(cx, target, #prop, &value);					\
  double prop_val;											\
  JS::ToNumber(cx, value, &prop_val);						\
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

static inline void build_func_frame(anim_frame *frame, JS::HandleObject cb) {
  js_object_wrapper_root(&frame->cb, cb.get());
  frame->type = FUNC_FRAME;
}

typedef void
(* NextAnimationFrame)(view_animation*, anim_frame*, unsigned, unsigned);

static inline void build_frame(JSContext *cx, JS::HandleObject target, unsigned argc, jsval *vp, NextAnimationFrame next) {
  LOGFN("build_frame");

  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

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

  if (argc > 1) {
    if(!JS::ToInt32(cx, args[1], &duration)) {
      duration = 500;
    }
    if (argc > 2) {
      if(!JS::ToInt32(cx, args[2], &transition)) {
        transition = 0;
      }
    }
  }


  next(anim, frame, duration, transition);

  LOGFN("end build_frame");
}



CEXPORT bool def_animate_now(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  if (!JSVAL_IS_PRIMITIVE(args[0])) {
    JS::RootedObject target(cx, JSVAL_TO_OBJECT(args[0]));

    if (target) {
      build_frame(cx, target, argc, vp, view_animation_now);
    }
  }

  args.rval().set(OBJECT_TO_JSVAL(thiz));
  return true;
}

CEXPORT bool def_animate_then(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  if (!JSVAL_IS_PRIMITIVE(args[0])) {
    JS::RootedObject target(cx, JSVAL_TO_OBJECT(args[0]));
    if (target) {
      build_frame(cx, target, argc, vp, view_animation_then);
    }
  }

  args.rval().set(OBJECT_TO_JSVAL(thiz));
  return true;
}

CEXPORT bool def_animate_commit(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
  view_animation_commit(anim);

  args.rval().set(OBJECT_TO_JSVAL(thiz));
  return true;
}

CEXPORT bool def_animate_clear(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
  view_animation_clear(anim);

  args.rval().set(OBJECT_TO_JSVAL(thiz));
  return true;
}

CEXPORT bool def_animate_wait(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
  double dt;
  JS::ToNumber(cx, args[0], &dt);
  view_animation_wait(anim, dt);

  args.rval().set(args.thisv());
  return true;
}

CEXPORT bool def_animate_pause(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);
  view_animation_pause(anim);

  args.rval().set(args.thisv());
  return true;
}

CEXPORT bool def_animate_resume(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);

  view_animation_resume(anim);

  args.rval().set(args.thisv());
  return true;
}

CEXPORT bool def_animate_isPaused(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);

  args.rval().setBoolean(anim->is_paused);
  return true;
}

CEXPORT bool def_animate_hasFrames(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));
  view_animation *anim = (view_animation *)JS_GetPrivate(thiz);

  args.rval().setBoolean((bool)anim->frame_head);
  return true;
}


CEXPORT void def_animate_class_finalize(JSFreeOp *fop, JSObject *obj) {
  view_animation *anim = (view_animation *)JS_GetPrivate(obj);
  if (anim) {
    view_animation_release(anim);
    js_object_wrapper_delete(&anim->js_anim);
  }
}

CEXPORT bool def_animate_class_constructor(JSContext *cx, unsigned argc, jsval *vp) {
  JSAutoRequest areq(cx);
  JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

  JS::RootedObject thiz(cx, animate_create_ctor_object(cx, vp));
  if (!thiz) {
    return false;
  }


  if (unlikely(argc < 1 || JSVAL_IS_PRIMITIVE(args[0]))) {
    LOG("{animate} ERROR: Animate constructor arguments were invalid!");

    return false;
  } else {
    JS::RootedObject js_timestep_view(cx, JSVAL_TO_OBJECT(args[0]));
    JS::RootedValue __view(cx);

    JS_GetProperty(cx, js_timestep_view, "__view", &__view);
    timestep_view *view = (timestep_view *)JS_GetPrivate(JSVAL_TO_OBJECT(__view));

    if (view) {
      view_animation *anim = view_animation_init(view);
      JS_SetPrivate(thiz, (void*)anim);
      js_object_wrapper_root(&anim->js_anim, thiz.get());
    }

    args.rval().set(OBJECT_TO_JSVAL(thiz));

    return true;
  }
}

void def_animate_add_to_group(JS_OBJECT_WRAPPER a) {
  LOGFN("def_animate_add_to_group");
  JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
  JS::RootedObject js_anim(cx, a);
  JS::RootedValue finish_val(cx);
  JS_GetProperty(cx, js_anim, "_addToGroup", &finish_val);
  if (finish_val.isObject()) {
    JS::RootedObject finish(cx, finish_val.toObjectOrNull());
    JS::Value args[] = {OBJECT_TO_JSVAL(js_anim)};
    if (JS_ObjectIsFunction(cx, finish)) {
      JS::RootedValue ret(cx);
      JS_CallFunctionValue(cx, js_anim, finish_val, 1, args, ret.address());
    }
  }
  LOGFN("end def_animate_add_to_group");
}

void def_animate_remove_from_group(JS_OBJECT_WRAPPER a) {
  LOGFN("def_animate_remove_from_group");
  JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);
  JS::RootedObject js_anim(cx, a);
  JS::RootedValue finish_val(cx);
  JS_GetProperty(cx, js_anim, "_removeFromGroup", &finish_val);
  if (finish_val.isObject()) {
    JS::RootedObject finish(cx, finish_val.toObjectOrNull());
    JS::Value args[] = {OBJECT_TO_JSVAL(js_anim)};
    if (JS_ObjectIsFunction(cx, finish)) {
      JS::RootedValue ret(cx);
      JS_CallFunctionValue(cx, js_anim, finish_val, 1, args, ret.address());
    }
  }
  LOGFN("end def_animate_remove_from_group");
}

void def_animate_cb(JS_OBJECT_WRAPPER view, JS_OBJECT_WRAPPER cb, double tt, double t) {
  JSContext *cx = get_js_context();
  JSAutoRequest areq(cx);

  JS::RootedObject js_view(cx, view);
  JS::RootedObject js_cb(cx, cb);
  JS::Value args[] = {JS::NumberValue(tt),JS::NumberValue(t)};

  JS::RootedValue ret(cx);
  JS_CallFunctionValue(cx, js_view, OBJECT_TO_JSVAL(js_cb), 2, args, ret.address());
}
