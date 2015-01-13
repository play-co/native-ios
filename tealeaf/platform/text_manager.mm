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

#include "texture_2d.h"
#include "texture_manager.h"
#include "core/rgba.h"
#include "core/platform/text_manager.h"
#include "core/log.h"
#include <stdio.h>
#include <stdlib.h>
#import "FontUtil.h"

#import <UIKit/UIKit.h>
#import <UIKit/UIStringDrawing.h>

;

#define INT_MAX_CHARS 11 /* say -4294967295 */

#define MAX_COLOR_DIGITS 3
#define NUM_COLOR_CHANNELS 4
#define FMT_STR "@TEXT%s|%i|%i|%i|%i|%i|%i|%i|%i|%s"
#define FMT_STR_LEN 36 /* strlen(FMT_STR) */

// Format: @TEXT<font>|<pt size>|<red>|<green>|<blue>|<alpha>|<max width>|<text style>|<stroke width>|<text>
// RGBA values are scaled up to 0..255 integers so they pack nicely into the string
// Stroke width float is scaled up by 4.0 to an integer also to avoid precision issues

texture_2d *text_manager_get_text(const char *raw_font_name, int size, const char *text, rgba *color, int max_width, int text_style, float stroke_width) {
	NSString *ns_font_name = [FontUtil fixFontName:raw_font_name];
	const char *font_name = [ns_font_name UTF8String];

	const size_t buf_len = (FMT_STR_LEN + MAX_COLOR_DIGITS * NUM_COLOR_CHANNELS + INT_MAX_CHARS*2 + strlen(font_name) + strlen(text) + 1);
	bool dynamic = false;
	char *buf = NULL;

	// Allocate on stack if possible
	if (buf_len > 512) {
		dynamic = true;
		buf = (char*)malloc(sizeof(char)*buf_len);
	} else {
		dynamic = false;
		buf = (char*)alloca(sizeof(char)*buf_len);
	}

	// Round RGBA values up
	int r = (int)(255 * color->r);
	int g = (int)(255 * color->g);
	int b = (int)(255 * color->b);
	int a = (int)(255 * color->a);

	// Clamp RGBA values
	if (r > 255) {
		r = 255;
	} else if (r < 0) {
		r = 0;
	}
	if (g > 255) {
		g = 255;
	} else if (g < 0) {
		g = 0;
	}
	if (b > 255) {
		b = 255;
	} else if (b < 0) {
		b = 0;
	}
	if (a > 255) {
		a = 255;
	} else if (a < 0) {
		a = 0;
	}

	// Scale stroke width up by 4, round, and store as an integer
	int isw = (int)(stroke_width * 4.f + .5f);

	int result = snprintf(buf, buf_len, FMT_STR, font_name, size, r, g, b, a, max_width, text_style, isw, text);

	texture_2d *tex = NULL;

	// If result fit in buffer,
	if (result > 0 && result < buf_len) {
		tex = texture_manager_get_texture(texture_manager_get(), buf);
		if (!tex) {
			tex = texture_manager_load_texture(texture_manager_get(), buf);
			tex->is_text = true;
		}
	}

	// If dynamically allocated,
	if (dynamic) {
		free(buf);
	}

	return tex;
}

texture_2d *text_manager_get_filled_text(const char *font_name, int size, const char *text, rgba *color, int max_width) {
	return text_manager_get_text(font_name, size, text, color, max_width, TEXT_STYLE_FILL, 0);
}

texture_2d *text_manager_get_stroked_text(const char *font_name, int size, const char *text, rgba *color, int max_width, float stroke_width) {
	return text_manager_get_text(font_name, size, text, color, max_width, TEXT_STYLE_STROKE, stroke_width);
}

#import <CoreText/CoreText.h>
#import <MobileCoreServices/MobileCoreServices.h>

int text_manager_init() {

	// Load any font resources from the resources.bundle file

    CTFontManagerRegisterFontsForURLs((CFArrayRef)((^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *resourceURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"resources.bundle/resources/fonts"];
        NSArray *resourceURLs = [fileManager contentsOfDirectoryAtURL:resourceURL includingPropertiesForKeys:nil options:0 error:nil];

		if (!resourceURLs || [resourceURLs count] <= 0) {
			return (NSArray *)[NSArray array];
		}
		
        return [resourceURLs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *url, NSDictionary *bindings) {
            CFStringRef pathExtension = (CFStringRef)[url pathExtension];
            NSArray *allIdentifiers = (NSArray *)UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, pathExtension, CFSTR("public.font"));
            if (![allIdentifiers count]) {
                return NO;
            }
            CFStringRef utType = (CFStringRef)[allIdentifiers lastObject];
			if ((!CFStringHasPrefix(utType, CFSTR("dyn.")) && UTTypeConformsTo(utType, CFSTR("public.font")))) {
				NSLOG(@"{text} Installing font: %@", url);
				return YES;
			} else {
				return NO;
			}
        }]];
    })()), kCTFontManagerScopeProcess, nil);

	NSError *error = NULL;
	NSRegularExpression *regexBold = [NSRegularExpression regularExpressionWithPattern:@"[-].*(bold|W6|wide)"
													options:NSRegularExpressionCaseInsensitive error:&error];
	if (error) {
		LOG("{text} ERROR: Unable to build regex for bold");
		return 0;
	}

	NSRegularExpression *regexItalic = [NSRegularExpression regularExpressionWithPattern:@"[-].*(italic|oblique)"
													options:NSRegularExpressionCaseInsensitive error:&error];
	if (error) {
		LOG("{text} ERROR: Unable to build regex for italic");
		return 0;
	}

	NSRegularExpression *regexMedium = [NSRegularExpression regularExpressionWithPattern:@"[-].*(medium|light)"
													options:NSRegularExpressionCaseInsensitive error:&error];
	if (error) {
		LOG("{text} ERROR: Unable to build regex for medium or light");
		return 0;
	}

	// Add built-in fonts first, so that we support iOS built-in fonts for iOS
	// specific games (a nice-to-have feature).

	int storedFontCount = 0;
	NSArray *familyNames = [UIFont familyNames];
	NSArray *fontNames;

	NSMutableDictionary *fonts = [NSMutableDictionary dictionary];
	NSMutableDictionary *literal_fonts = [NSMutableDictionary dictionary];

	// For each font family,
	for (int ii = 0, ii_len = (int)[familyNames count]; ii < ii_len; ++ii)
	{
		NSString *familyName = [familyNames objectAtIndex:ii];

		fontNames = [UIFont fontNamesForFamilyName:familyName];

		NSMutableDictionary *familyDict = [NSMutableDictionary dictionary];
		NSString *bestNormal = nil;

		// For each font,
		int fontNamesCount = (int)[fontNames count];
		for (int jj = 0; jj < fontNamesCount; ++jj)
		{
			NSString *fontName = [fontNames objectAtIndex:jj];

			// Insert literal font name
			NSString *tweakedFontName = [[[fontName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"-" withString:@""];
			[literal_fonts setObject:fontName forKey:tweakedFontName];

			// If it contains "bold", "W6" or "wide" (case-insensitive) after a dash, then it is "bold".
			NSTextCheckingResult *resultBold = [regexBold firstMatchInString:fontName options:0 range:NSMakeRange(0, [fontName length])];
			bool bold = resultBold && ([resultBold range].location != NSNotFound);

			// If it contains "italic" or "oblique" (case-insensitive) after a dash, then it is "italic".
			NSTextCheckingResult *resultItalic = [regexItalic firstMatchInString:fontName options:0 range:NSMakeRange(0, [fontName length])];
			bool italic = resultItalic && ([resultItalic range].location != NSNotFound);

			const NSString *key = nil;

			if (bold) {
				if (italic) {
					// If it is both "bold" and "italic" then it is stored under "bolditalic".
					key = @"bolditalic";
				} else {
					key = @"bold";
				}
			} else if (italic) {
				key = @"italic";
			} else {
				// If it contains "medium" (case-insensitive) after a dash, then it is "medium".
				// If it contains "light" (case-insensitive) after a dash, then it is "light".
				NSTextCheckingResult *resultMedium = [regexMedium firstMatchInString:fontName options:0 range:NSMakeRange(0, [fontName length])];

				if (resultMedium && [resultMedium rangeAtIndex:1].location != NSNotFound) {
					NSString *type = [fontName substringWithRange:[resultMedium rangeAtIndex:1]];

					if ([type caseInsensitiveCompare:@"light"] == NSOrderedSame) {
						key = @"light";
					} else {
						key = @"medium";
					}
				} else {
					// If not seen a normal font yet,
					if (bestNormal == nil) {
						// Use the first one
						bestNormal = fontName;
					} else {
						// Else: Store it as "normal" key, preferring fonts without a -.
						if ([bestNormal rangeOfString:@"-"].location != NSNotFound) {
							bestNormal = fontName;
						}
					}
				}
			}

			// If a key will be set,
			if (key != nil) {
				// If two exist, use the one with the shorter name length.
				NSString *previous = [familyDict objectForKey:key];
				if (!previous || previous.length >= fontName.length) {
					[familyDict setObject:fontName forKey:key];
				}
			}
		}

		// If no "normal" key was filled, then use the last one in the list.
		if (bestNormal == nil) {
			if (fontNamesCount > 0) {
				bestNormal = [fontNames objectAtIndex:(fontNamesCount-1)];
			}
		}
		if (bestNormal != nil) {
			[familyDict setObject:bestNormal forKey:@"normal"];
		}

		// If any fonts were added,
		if ([familyDict count] > 0) {
			// Store the font family details under the lower-case family name
			[fonts setObject:familyDict forKey:[familyName lowercaseString]];
			++storedFontCount;
		}
	}

	FontUtil.m_fonts = [fonts retain];
	FontUtil.m_literal_fonts = [literal_fonts retain];

	LOG("{text} Loaded %d fonts", storedFontCount);

	return 1; // Non-zero: Success!
}

int text_manager_measure_text(const char* font, int size, const char* text) {
	NSString *fontName = [FontUtil fixFontName:font];

	if (fontName != nil) {
		NSString *str = [NSString stringWithUTF8String:text];
		CGSize fontSize = [str sizeWithFont: [UIFont fontWithName:fontName size:size]];
		return fontSize.width;
	} else {
		return 0;
	}
}
