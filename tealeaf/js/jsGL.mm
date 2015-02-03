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
 * along with the Game Closure SDK.	 If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import "jsGL.h"
#import "platform/Texture2D.h"
#include <math.h>
#import "core/geometry.h"
#import "core/draw_textures.h"
#include "core/platform/text_manager.h"
#include "core/tealeaf_context.h"
#include "core/texture_manager.h"
#include "core/rgba.h"
#include "core/log.h"

#define GET_CONTEXT_2D() ( (context_2d*)JS_GetPrivate(JS_THIS_OBJECT(cx, vp)) )

JSAG_MEMBER_BEGIN_NOARGS(save)
{
	context_2d_save(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(restore)
{
	context_2d_restore(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(setTransform, 6)
{
	JSAG_ARG_DOUBLE(m11);
	JSAG_ARG_DOUBLE(m12);
	JSAG_ARG_DOUBLE(m21);
	JSAG_ARG_DOUBLE(m22);
	JSAG_ARG_DOUBLE(dx);
	JSAG_ARG_DOUBLE(dy);

	context_2d_setTransform(GET_CONTEXT_2D(), m11, m12, m21, m22, dx, dy);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(resize, 2)
{
	JSAG_ARG_INT32(w)
	JSAG_ARG_INT32(h)

	context_2d *ctx = GET_CONTEXT_2D();
	context_2d_resize(ctx, w, h);
	texture_2d *tex = texture_manager_get_texture(texture_manager_get(), ctx->url);

	JS::RootedValue glname(cx, JS::NumberValue(tex->name));
	JS::RootedValue texurl(cx, CSTR_TO_JSVAL(cx, tex->url));

	JSObject *tex_data = JS_NewObject(cx, nullptr, nullptr, nullptr);
	JS_SetProperty(cx, tex_data, "__gl_name", glname);
	JS_SetProperty(cx, tex_data, "_src", texurl);

	JSAG_RETURN_OBJECT(tex_data);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(rotate, 1)
{
	JSAG_ARG_DOUBLE(angle);

	context_2d_rotate(GET_CONTEXT_2D(), angle);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(loadIdentity)
{
	context_2d_loadIdentity(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(translate, 2)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);

	context_2d_translate(GET_CONTEXT_2D(), x, y);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(clearRect, 4)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(w);
	JSAG_ARG_DOUBLE(h);

	rect_2d rect = {
		static_cast<float>(x),
    static_cast<float>(y),
    static_cast<float>(w),
    static_cast<float>(h)
	};

	context_2d_clearRect(GET_CONTEXT_2D(), &rect);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(fillRect, 5)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(w);
	JSAG_ARG_DOUBLE(h);
	JSAG_ARG_CSTR(scolor);

	rgba color;
	rgba_parse(&color, scolor);

	rect_2d rect = {
    static_cast<float>(x),
    static_cast<float>(y),
    static_cast<float>(w),
    static_cast<float>(h)
	};

	context_2d_fillRect(GET_CONTEXT_2D(), &rect, &color);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(strokeRect, 6)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(width);
	JSAG_ARG_DOUBLE(height);
	JSAG_ARG_CSTR(scolor);
	JSAG_ARG_DOUBLE(line_width1);

	rgba color;
	rgba_parse(&color, scolor);
	
	double line_width2 = line_width1 / 2;
	
	context_2d *ctx = GET_CONTEXT_2D();
	
	rect_2d left_rect = {
    static_cast<float>(x - line_width2),
    static_cast<float>(y - line_width2),
    static_cast<float>(line_width1),
    static_cast<float>(height + line_width1)
  };
	context_2d_fillRect(ctx, &left_rect, &color);
	
	rect_2d right_rect = {
    static_cast<float>(x + width - line_width2),
    static_cast<float>(y - line_width2),
    static_cast<float>(line_width1),
    static_cast<float>(height + line_width1)
  };
	context_2d_fillRect(ctx, &right_rect, &color);
	
	rect_2d top_rect = {
    static_cast<float>(x + line_width2),
    static_cast<float>(y - line_width2),
    static_cast<float>(width - line_width1),
    static_cast<float>(line_width1)
  };
	context_2d_fillRect(ctx, &top_rect, &color);
	
	rect_2d bottom_rect = {
    static_cast<float>(x + line_width2),
    static_cast<float>(y + height - line_width2),
    static_cast<float>(width - line_width1),
    static_cast<float>(line_width1)
  };
	context_2d_fillRect(ctx, &bottom_rect, &color);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(scale, 2)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);

	context_2d_scale(GET_CONTEXT_2D(), x, y);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(clear)
{
	context_2d_clear(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(setGlobalAlpha, 1)
{
	JSAG_ARG_DOUBLE(alpha);

	context_2d_setGlobalAlpha(GET_CONTEXT_2D(), alpha);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(getGlobalAlpha, 0)
{
	JSAG_RETURN_DOUBLE(context_2d_getGlobalAlpha(GET_CONTEXT_2D()));
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(setGlobalCompositeOperation, 1)
{
	JSAG_ARG_INT32(composite_op);

	context_2d_setGlobalCompositeOperation(GET_CONTEXT_2D(), (int)composite_op);
	return true;
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(getGlobalCompositeOperation, 0)
{
	JSAG_RETURN_INT32(context_2d_getGlobalCompositeOperation(GET_CONTEXT_2D()));
	return true;
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(loadImage, 1)
{
	JSAG_ARG_CSTR(url);

	texture_2d *tex = texture_manager_get_texture(texture_manager_get(), url);
	
	if (!tex) {
		tex = texture_manager_load_texture(texture_manager_get(), url);
	}
	
	if (!tex || !tex->loaded) {
		JS_SET_RVAL(cx, vp, JSVAL_FALSE);
	} else {
		JSObject *result = JS_NewObject(cx, NULL, NULL, NULL);
		
    JS::RootedValue width(cx, JS::NumberValue(tex->originalWidth));
    JS::RootedValue height(cx, JS::NumberValue(tex->originalHeight));
    JS::RootedValue name(cx, JS::NumberValue(tex->name));
		
		JS_SetProperty(cx, result, "width", width);
		JS_SetProperty(cx, result, "height", height);
		JS_SetProperty(cx, result, "name", name);

		JSAG_RETURN_OBJECT(result);
	}
}
JSAG_MEMBER_END

static double measureText(JSContext *cx, JSObject *font_info, const char *text) {
	double width = 0;

  JS::RootedValue _custom_font(cx), _dimensions(cx);
  JS::RootedObject  custom_font(cx), dimensions(cx);

	JS_GetProperty(cx, font_info, "customFont", &_custom_font);
  if(!_custom_font.isObject()) {
    return 0;
  }
  
  custom_font = _custom_font.toObjectOrNull();

	JS_GetProperty(cx, custom_font, "dimensions", &_dimensions);
  if(!_dimensions.isObject()) {
    return 0;
  }
  
  dimensions = _dimensions.toObjectOrNull();

  JS::RootedValue _horizontal(cx);
  JS::RootedObject horizontal(cx);

	JS_GetProperty(cx, custom_font, "horizontal", &_horizontal);
  if (!_horizontal.isObject()) { return 0; }
  horizontal = _horizontal.toObjectOrNull();

  JS::RootedValue _scale(cx), _space_width(cx), _tracking(cx), _outline(cx);
	double scale, space_width, tracking, outline;

	JS_GetProperty(cx, font_info, "scale", &_scale);
  JS::ToNumber(cx, _scale, &scale);

	JS_GetProperty(cx, horizontal, "width", &_space_width);
	JS::ToNumber(cx, _space_width, &space_width);
	space_width *= scale;

	JS_GetProperty(cx, horizontal, "tracking", &_tracking);
	JS::ToNumber(cx, _tracking, &tracking);
	tracking *= scale;

	JS_GetProperty(cx, horizontal, "outline", &_outline);
	JS::ToNumber(cx, _outline, &outline);
	outline *= scale;

	char c = 0;
	for (size_t i = 0; (c = text[i]) != 0; i++) {
		if (c == ' ') {
			width += space_width;
		} else {
      JS::RootedValue _dimension(cx);
      JS::RootedObject dimension(cx);
			JS_GetElement(cx, dimensions, (int)c, &_dimension);
      if (!_dimension.isObject()) {
        return -1;
      }
      dimension = _dimension.toObjectOrNull();
      JS::RootedValue _ow(cx);
      double dow;
      JS_GetProperty(cx, dimension, "ow", &_ow);
      JS::ToNumber(cx, _ow, &dow);
      int ow = (int)dow;
      // TODO why do we extract a double and cast to int?

      width += (ow - 2) * scale;
		}
		width += tracking - outline;
	}

	return width + 2 * scale;
}

JSAG_MEMBER_BEGIN_NOARGS(flushImages)
{
	draw_textures_flush();
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(measureText, 3)
{
	JSAG_ARG_CSTR(str);
	JSAG_ARG_DOUBLE(size);
	JSAG_ARG_CSTR(font);

	int width = text_manager_measure_text(font, size, str);
	
  JS::RootedObject metrics(cx, JS_NewObject(cx, nullptr, nullptr, nullptr));
  JS::RootedValue w(cx, JS::NumberValue(width));
	JS_SetProperty(cx, metrics, "width", w);

	JSAG_RETURN_OBJECT(metrics);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(measureTextBitmap, 2)
{
	JSAG_ARG_CSTR(str);
	JSAG_ARG_OBJECT(font_info);

	double width = measureText(cx, font_info, str);
	
  JS::RootedValue width_val(cx, JS::NumberValue(width));
  JS::RootedValue failed_val(cx, JS::BooleanValue(width < 0));
  JS::RootedObject metrics(cx, JS_NewObject(cx, nullptr, nullptr, nullptr));
	JS_DefineProperty(cx, metrics, "width", width_val, nullptr, nullptr, 0);
	JS_DefineProperty(cx, metrics, "failed", failed_val, nullptr, nullptr, 0);

	JSAG_RETURN_OBJECT(metrics);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(fillText, 9)
{
	JSAG_ARG_CSTR(str);
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(maxWidth);
	JSAG_ARG_CSTR(fillStyle);
	JSAG_ARG_DOUBLE(size);
	JSAG_ARG_CSTR(font);
	JSAG_ARG_CSTR_FIRST(align, 1);
	JSAG_ARG_CSTR_FIRST(baseline, 1);

	if (*str) {
		rgba color;
		rgba_parse(&color, fillStyle);
		
		texture_2d *tex = text_manager_get_filled_text(font, size, str, &color, maxWidth);
		
		if (tex) {
			int x_offset;
			switch (align[0]) {
				case 'c': // Center
				case 'C':
					x_offset = tex->originalWidth / 2;
					break;
				default:
				case 'l': // Left
				case 'L':
					x_offset = 0;
					break;
				case 'r': // Right
				case 'R':
					x_offset = tex->originalWidth;
			}

			int y_offset;
			switch (baseline[0]) {
				case 'b': // Bottom
				case 'B':
					y_offset = tex->originalHeight;
					break;
				default:
				case 't': // Top
				case 'T':
					y_offset = 0;
					break;
				case 'm': // Middle
				case 'M':
					y_offset = tex->originalHeight / 2;
			}

			y_offset *= 1.15;
			x -= x_offset;
			y -= y_offset;

			rect_2d src_rect = {
        static_cast<float>(0),
        static_cast<float>(0),
        static_cast<float>(tex->originalWidth),
        static_cast<float>(tex->originalHeight)
      };
      
			rect_2d dest_rect = {
        static_cast<float>(x),
        static_cast<float>(y),
        static_cast<float>(tex->originalWidth),
        static_cast<float>(tex->originalHeight)
      };

			context_2d_fillText(GET_CONTEXT_2D(), tex, &src_rect, &dest_rect, color.a);
		}
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(strokeText, 10)
{
	JSAG_ARG_CSTR(str);
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(maxWidth);
	JSAG_ARG_CSTR(fillStyle);
	JSAG_ARG_DOUBLE(size);
	JSAG_ARG_CSTR(font);
	JSAG_ARG_CSTR_FIRST(align, 1);
	JSAG_ARG_CSTR_FIRST(baseline, 1);
	JSAG_ARG_DOUBLE(line_width);

	if (*str) {
		rgba color;
		rgba_parse(&color, fillStyle);
		
		texture_2d *tex = text_manager_get_stroked_text(font, size, str, &color, maxWidth, line_width);
		
		if (tex) {
			int x_offset;
			switch (align[0]) {
				case 'c': // Center
				case 'C':
					x_offset = tex->originalWidth / 2;
					break;
				default:
				case 'l': // Left
				case 'L':
					x_offset = 0;
					break;
				case 'r': // Right
				case 'R':
					x_offset = tex->originalWidth;
			}
			
			int y_offset;
			switch (baseline[0]) {
				case 'b': // Bottom
				case 'B':
					y_offset = tex->originalHeight;
					break;
				default:
				case 't': // Top
				case 'T':
					y_offset = 0;
					break;
				case 'm': // Middle
				case 'M':
					y_offset = tex->originalHeight / 2;
			}

			y_offset *= 1.15;
			x -= x_offset + line_width;
			y -= y_offset + line_width;

			// HACK: Work around iOS font rendering bug.  When text is rendered with a
			// stroke style, the first character looks fine but the rest of the stroke
			// outline is offset by 1 pixel.  Shifting the stroke by half a pixel seems
			// to make it look visually centered.
			if (strlen(str) > 1) {
				x -= 0.5f;
				y += 0.5f;
			}

      rect_2d src_rect = {
        static_cast<float>(0),
        static_cast<float>(0),
        static_cast<float>(tex->originalWidth),
        static_cast<float>(tex->originalHeight)
      };
      
      rect_2d dest_rect = {
        static_cast<float>(x),
        static_cast<float>(y),
        static_cast<float>(tex->originalWidth),
        static_cast<float>(tex->originalHeight)
      };
      
			context_2d_fillText(GET_CONTEXT_2D(), tex, &src_rect, &dest_rect, color.a);
		}
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(drawImage, 10)
{
	JSAG_ARG_INT32(stex);
	JSAG_ARG_CSTR(url);
	JSAG_ARG_DOUBLE(sx);
	JSAG_ARG_DOUBLE(sy);
	JSAG_ARG_DOUBLE(sw);
	JSAG_ARG_DOUBLE(sh);
	JSAG_ARG_DOUBLE(dx);
	JSAG_ARG_DOUBLE(dy);
	JSAG_ARG_DOUBLE(dw);
	JSAG_ARG_DOUBLE(dh);

	rect_2d src_rect = {
    static_cast<float>(sx),
    static_cast<float>(sy),
    static_cast<float>(sw),
    static_cast<float>(sh)
  };
  
	rect_2d dest_rect = {
    static_cast<float>(dx),
    static_cast<float>(dy),
    static_cast<float>(dw),
    static_cast<float>(dh)
  };

	context_2d_drawImage(GET_CONTEXT_2D(), stex, url, &src_rect, &dest_rect);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(addFilter, 2)
{
	JSAG_ARG_CSTR(name);
	JSAG_ARG_OBJECT(filter);

  JS::RootedValue filter_type_val(cx);
	JS_GetProperty(cx, filter, "type", &filter_type_val);
	if (likely(JSVAL_IS_STRING(filter_type_val))) {
		char filter_ch[2] = {0};
    JS_EncodeStringToBuffer(cx, JS::ToString(cx, filter_type_val), filter_ch, 1);
		
		//if (0 == strcmp(filter_name, "LinearAdd") == 0) {
		if (filter_ch[0] == 'L') {
			context_2d_set_filter_type(GET_CONTEXT_2D(), FILTER_LINEAR_ADD);
			//} else if (0 == strcmp(filter_name, "Multiply") == 0) {
		} else if (filter_ch[0] == 'M') {
			context_2d_set_filter_type(GET_CONTEXT_2D(), FILTER_MULTIPLY);
		} else {
			LOG("{gl} USER ERROR: addFilter called without a filter operation");
		}
		
    JS::RootedValue _r(cx), _g(cx), _b(cx), _a(cx);
		JS_GetProperty(cx, filter, "r", &_r);
		JS_GetProperty(cx, filter, "g", &_g);
		JS_GetProperty(cx, filter, "b", &_b);
		JS_GetProperty(cx, filter, "a", &_a);
		
		double r, g, b, a;
    JS::ToNumber(cx, _r, &r);
		JS::ToNumber(cx, _g, &g);
		JS::ToNumber(cx, _b, &b);
		JS::ToNumber(cx, _a, &a);
		
		r /= 255.;
		g /= 255.;
		b /= 255.;
		
		rgba color = {
      static_cast<float>(r),
      static_cast<float>(g),
      static_cast<float>(b),
      static_cast<float>(a)
    };
		context_2d_add_filter(GET_CONTEXT_2D(), &color);
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(clearFilters)
{
	GET_CONTEXT_2D()->filter_type = FILTER_NONE;
	context_2d_clear_filters(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

static double textBaselineValue(JSContext *cx,
                                JSObject *ctx,
                                JSObject *custom_font,
                                double scale) {
  JS::RootedValue jtext_baseline(cx);
	JS_GetProperty(cx, ctx, "textBaseline", &jtext_baseline);
	if (JSVAL_IS_STRING(jtext_baseline)) {
		char baseline_ch[2] = {0};
    JS_EncodeStringToBuffer(cx, JS::ToString(cx, jtext_baseline), baseline_ch, 1);

    JS::RootedValue _b(cx), _vertical(cx);
		double b;
		JSObject *vertical;

		//if (0 == strcmp(baseline, "alphabetic")) {
		if (baseline_ch[0] == 'a') {
			JS_GetProperty(cx, custom_font, "vertical", &_vertical);
      vertical = _vertical.toObjectOrNull();
			JS_GetProperty(cx, vertical, "baseline", &_b);
      JS::ToNumber(cx, _b, &b);

			return -b * scale;
		//} else if (0 == strcmp(baseline, "middle")) {
		} else if (baseline_ch[0] == 'm') {
			JS_GetProperty(cx, custom_font, "vertical", &_vertical);
      vertical = _vertical.toObjectOrNull();
			JS_GetProperty(cx, vertical, "bottom", &_b);
      JS::ToNumber(cx, _b, &b);

			return -b / 2 * scale;
		//} else if (0 == strcmp(baseline, "bottom")) {
		} else if (baseline_ch[0] == 'b') {
			JS_GetProperty(cx, custom_font, "vertical", &_vertical);
      vertical = _vertical.toObjectOrNull();
			JS_GetProperty(cx, vertical, "bottom", &_b);
      JS::ToNumber(cx, _b, &b);

			return -b * scale;
		}
	}

	return 0;
}

double textAlignValue(JSContext *cx,
                      JSObject *ctx,
                      JSObject *font_info,
                      const char *text) {
  JS::RootedValue jalign(cx);
	JS_GetProperty(cx, ctx, "textAlign", &jalign);

	if (JSVAL_IS_STRING(jalign)) {
		char align_ch[2] = {0};
    JS_EncodeStringToBuffer(cx, JS::ToString(cx, jalign), align_ch, 1);

		//if (!strcmp(align, "center")) {
		if (align_ch[0] == 'c') {
			return measureText(cx, font_info, text) / -2.;
		//} else if (!strcmp(align, "right")) {
		} else if (align_ch[0] == 'r') {
			return -measureText(cx, font_info, text);
		}
	}

	//align left	
	return 0;
}

JSAG_MEMBER_BEGIN(fillTextBitmap, 7)
{
	JSAG_ARG_OBJECT(js_ctx);
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_CSTR(text);
	JSAG_ARG_SKIP;
	JSAG_ARG_OBJECT(font_info);
	JSAG_ARG_INT32(image_type);

	context_2d *context = GET_CONTEXT_2D();
	
	//get customfont and images from font_info
  JS::RootedValue v(cx);
  JS::RootedObject custom_font(cx), images1(cx),
    dimensions(cx), horizontal(cx), images2(cx);
	double scale, space_width, tracking, outline;
	JS_GetProperty(cx, font_info, "customFont", &v);
  custom_font = v.toObjectOrNull();
	JS_GetProperty(cx, custom_font, "images", &v);
  images1 = v.toObjectOrNull();
	JS_GetElement(cx, images1, image_type, &v);
  images2 = v.toObjectOrNull();
	JS_GetProperty(cx, custom_font, "dimensions", &v);
  dimensions = v.toObjectOrNull();

	char ch;
	bool use_bitmap_fonts = true;
	for (int i = 0; (ch = text[i]) != 0; i++) {
		if (ch != ' ') {
      JS::RootedValue jdimension(cx);
			JS_GetElement(cx, dimensions, (unsigned char)ch, &jdimension);
			if (!!JSVAL_IS_PRIMITIVE(jdimension)) {
				use_bitmap_fonts = false;
				break;
			}
		}
	}

	if (use_bitmap_fonts) {
		JS_GetProperty(cx, custom_font, "horizontal", &v);
    horizontal = v.toObjectOrNull();
		JS_GetProperty(cx, font_info, "scale", &v);
    JS::ToNumber(cx, v, &scale);
		JS_GetProperty(cx, horizontal, "width", &v);
    JS::ToNumber(cx, v, &space_width);
		space_width *= scale;
		JS_GetProperty(cx, horizontal, "tracking", &v);
    JS::ToNumber(cx, v, &tracking);
		tracking *= scale;
		JS_GetProperty(cx, horizontal, "outline", &v);
    JS::ToNumber(cx, v, &outline);
		outline *= scale;

		float dy = textBaselineValue(cx, js_ctx, custom_font, scale);
		y += dy;

		float dx = textAlignValue(cx, js_ctx, font_info, text);
		x += dx;

		int current_image_index = -1;
		char *url = 0, ch = '\0';

		while ((ch = *text++)) {
			if (ch != ' ') {
        JS::RootedValue jdimension(cx);
				JS_GetElement(cx, dimensions, (unsigned char)ch, &jdimension);

				if (likely(!JSVAL_IS_PRIMITIVE(jdimension))) {
					JSObject *dimension = JSVAL_TO_OBJECT(jdimension);

					int32_t image_index, sx, sy, sw, sh;
					double ow, oh;

					JS_GetProperty(cx, dimension, "i", &v);
          JS::ToInt32(cx, v, &image_index);
					JS_GetProperty(cx, dimension, "x", &v);
					JS::ToInt32(cx, v, &sx);
					JS_GetProperty(cx, dimension, "y", &v);
					JS::ToInt32(cx, v, &sy);
					JS_GetProperty(cx, dimension, "w", &v);
					JS::ToInt32(cx, v, &sw);
					JS_GetProperty(cx, dimension, "h", &v);
					JS::ToInt32(cx, v, &sh);
					JS_GetProperty(cx, dimension, "ow", &v);
          JS::ToNumber(cx, v, &ow);
					JS_GetProperty(cx, dimension, "oh", &v);
          JS::ToNumber(cx, v, &oh);

					rect_2d src_rect = {
            static_cast<float>(sx),
            static_cast<float>(sy),
            static_cast<float>(sw),
            static_cast<float>(sh)
          };
          
					rect_2d dest_rect = {
            static_cast<float>(x),
            static_cast<float>(y + (oh - 1) * scale),
            static_cast<float>(sw * scale),
            static_cast<float>((sh - 2) * scale)
          };

					if (current_image_index != image_index) {
						current_image_index = image_index;

            JS::RootedValue jimage(cx);
						JS_GetElement(cx, images2, image_index, &jimage);
						if (likely(!JSVAL_IS_PRIMITIVE(jimage))) {
							JSObject *image = jimage.toObjectOrNull();

              JS::RootedValue src_tex(cx);
							JS_GetProperty(cx, image, "_src", &src_tex);
							if (likely(JSVAL_IS_STRING(src_tex))) {
								JSVAL_TO_CSTR(cx, src_tex, curl);
								url = curl;
							}
						}
					}

					context_2d_drawImage(context, 0, url, &src_rect, &dest_rect);

					x += (ow - 2) * scale + tracking - outline;
				} else {
					LOG("{gl} ERROR: Character provided was not supported by bitmap font (out of range): %s", text);

					// Character not in array: Skip the character
					x += space_width + tracking - outline;
				}
			} else {
				// Space: Skip the character
				x += space_width + tracking - outline;
			}
		}
	}
	JSAG_RETURN_BOOL(use_bitmap_fonts);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(newTexture, 2)
{
	JSAG_ARG_DOUBLE(width);
	JSAG_ARG_DOUBLE(height);

	texture_2d *tex = texture_manager_new_texture(texture_manager_get(), width, height);
  
  JS::RootedValue glname(cx, JS::NumberValue(tex->name));
  JS::RootedValue texurl(cx, CSTR_TO_JSVAL(cx, tex->url));

	JSObject *result = JS_NewObject(cx, NULL, NULL, NULL);
	JS_SetProperty(cx, result, "__gl_name", glname);
	JS_SetProperty(cx, result, "_src", texurl);

	JSAG_RETURN_OBJECT(result);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(deleteAllTextures)
{
	texture_manager_clear_textures(texture_manager_get(), true);
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(enableScissor, 4)
{
	JSAG_ARG_DOUBLE(x);
	JSAG_ARG_DOUBLE(y);
	JSAG_ARG_DOUBLE(width);
	JSAG_ARG_DOUBLE(height);

	rect_2d bounds = {
		static_cast<float>(x),
    static_cast<float>(y),
    static_cast<float>(width),
    static_cast<float>(height)
	};

	LOG("{gl} Clipping enabled");

	context_2d_setClip(GET_CONTEXT_2D(), bounds);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(disableScissor)
{
	LOG("{gl} Clipping disabled");

	draw_textures_flush();
	
	GLTRACE(glDisable(GL_SCISSOR_TEST));
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(deleteTexture, 1)
{
    JSAG_ARG_CSTR(url);
    texture_2d *tex = texture_manager_get_texture(texture_manager_get(), url);
    if (tex && tex->loaded) {
        texture_manager_free_texture(texture_manager_get(), tex);
    }
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(touchTexture, 1)
{
	JSAG_ARG_CSTR(url);

	texture_manager_touch_texture(texture_manager_get(), url);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(toDataURL, 1)
{
	JSAG_ARG_OBJECT(js_ctx);
  JS::RootedValue ctx_val(cx);
  JSObject *_ctx;
  JS_GetProperty(cx, js_ctx, "_ctx", &ctx_val);
  _ctx = ctx_val.toObjectOrNull();
  context_2d* ctx = static_cast<context_2d*>(JSAG_GET_PRIVATE(_ctx));
  char * data = context_2d_save_buffer_to_base64(ctx, "PNG");

	if (data != NULL) {
		JSAG_RETURN_CSTR(data)
    free(data);
	} else {
    JSAG_RETURN_CSTR("")
	}
;

}
JSAG_MEMBER_END


JSAG_MEMBER_BEGIN_NOARGS(destroy)
{
	context_2d_delete(GET_CONTEXT_2D());
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(gl)
JSAG_OBJECT_MEMBER_NAMED(_loadImage, loadImage)
JSAG_OBJECT_MEMBER(flushImages)
JSAG_OBJECT_MEMBER(toDataURL)
JSAG_OBJECT_MEMBER(newTexture)
JSAG_OBJECT_MEMBER(deleteAllTextures)
JSAG_OBJECT_MEMBER(deleteTexture)
JSAG_OBJECT_MEMBER(touchTexture)
JSAG_OBJECT_END

JSAG_CLASS_FINALIZE(Context2D, obj)
{
	context_2d *ctx = (context_2d *)JSAG_GET_PRIVATE(obj);
	// classes get 1 more finalize call than they do construct calls without JSCLASS_CONSTRUCT_PROTOTYPE
	if(ctx) {
		free(ctx);
	}
}

JSAG_CLASS_IMPL(Context2D);

JSAG_MEMBER_BEGIN(Context2D, 3)
{
	JSAG_ARG_JSVAL(cx, canvas);
	JSAG_ARG_CSTR(url);
	JSAG_ARG_INT32(destTex);

	LOG("{gl} Created context '%d'", destTex);

	JSObject *_thiz = JSAG_CLASS_INSTANCE(Context2D);
  JS::RootedObject thiz(cx, _thiz);

	context_2d *ctx = context_2d_new(tealeaf_canvas_get(), url, destTex);

  JS_SetProperty(cx, thiz, "canvas", canvas);

	JSAG_SET_PRIVATE(thiz, ctx);

	JSAG_RETURN_OBJECT(thiz);
}
JSAG_MEMBER_END

JSAG_OBJECT_START(Context2D)
JSAG_OBJECT_MEMBER(loadIdentity)
JSAG_OBJECT_MEMBER(rotate)
JSAG_OBJECT_MEMBER(translate)
JSAG_OBJECT_MEMBER(scale)
JSAG_OBJECT_MEMBER(drawImage)
JSAG_OBJECT_MEMBER(save)
JSAG_OBJECT_MEMBER(resize)
JSAG_OBJECT_MEMBER(setTransform)
JSAG_OBJECT_MEMBER(restore)
JSAG_OBJECT_MEMBER(clear)
JSAG_OBJECT_MEMBER(setGlobalAlpha)
JSAG_OBJECT_MEMBER(getGlobalAlpha)
JSAG_OBJECT_MEMBER(setGlobalCompositeOperation)
JSAG_OBJECT_MEMBER(getGlobalCompositeOperation)
JSAG_OBJECT_MEMBER(loadImage)
JSAG_OBJECT_MEMBER(clearRect)
JSAG_OBJECT_MEMBER(fillRect)
JSAG_OBJECT_MEMBER(strokeRect)
JSAG_OBJECT_MEMBER(measureText)
JSAG_OBJECT_MEMBER(fillText)
JSAG_OBJECT_MEMBER(strokeText)
JSAG_OBJECT_MEMBER(enableScissor)
JSAG_OBJECT_MEMBER(disableScissor)
JSAG_OBJECT_MEMBER(destroy)
JSAG_OBJECT_MEMBER(clearFilters)
JSAG_OBJECT_MEMBER(addFilter)
JSAG_OBJECT_MEMBER(fillTextBitmap)
JSAG_OBJECT_MEMBER(measureTextBitmap)
JSAG_OBJECT_END


@implementation jsGL

+ (void) addToRuntime:(js_core *)js {
	JSContext *cx = js.cx;

	JSObject *gl = JS_NewObject(cx, NULL, NULL, NULL);
	JSAG_OBJECT_ATTACH_EXISTING(js.cx, js.native, gl, gl);
	JSAG_CREATE_CLASS(gl, Context2D);

	//retrieve available fonts
	JSObject *fontFamilies = JS_NewObject(cx, NULL, NULL, NULL);

	NSArray *families = [UIFont familyNames];

	for (NSString *family in families) {
		JSObject *fontArray = JS_NewArrayObject(cx, 0, NULL);
		int i = 0;
		NSArray *fontsForFamily = [UIFont fontNamesForFamilyName:family];

		for (NSString *font in fontsForFamily) {
      JS::RootedValue f(cx, NSTR_TO_JSVAL(cx, font));
			JS_SetElement(cx, fontArray, i++, &f);
		}

    JS::RootedValue fonts(cx, JS::ObjectValue(*fontArray));
		JS_SetProperty(cx, fontFamilies, [family UTF8String], fonts);
	}

  JS::RootedValue fontsval(cx, JS::ObjectValue(*fontFamilies));
	JS_SetProperty(cx, gl, "fonts", fontsval);
}

+ (void) onDestroyRuntime {
	
}

@end
