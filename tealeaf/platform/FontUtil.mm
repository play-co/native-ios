//
//  FontUtil.m
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/26/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "FontUtil.h"
#import "platform/log.h"

@implementation FontUtil
static bool m_reported_font_error = false;
static NSDictionary *m_fonts;
static NSDictionary *m_literal_fonts;

+ (void) setM_fonts:(NSDictionary *) fonts {
    m_fonts = fonts;
}

+ (void) setM_literal_fonts:(NSDictionary *) literalFonts {
    m_literal_fonts = literalFonts;
}

+ (NSString*) fixFontName:(const char *)font {
    if (m_fonts == nil || m_literal_fonts == nil) {
		LOG("{text} ERROR: text_manager_measure_text called before init");
		return nil;
	}
    
	// Try for a literal name match to allow any font to be selected
	// Here we replace dashes and spaces with empty strings and convert to lower case
	// This is done to normalize the font names.  Users will specify "Gill Sans Bold"
	// for "Gill Sans Bold.tff", while the font contains "Gill Sans-Bold".	To normalize
	// both of these designations, the spaces and dashes are ignored for comparison.
	// This is done to fix the case where the "Bold" is in the title of the font name.
    
	NSString *tweakedFontName = [[[[[NSString stringWithUTF8String:font] lowercaseString]
                                   stringByReplacingOccurrencesOfString:@"normal " withString:@""]
                                  stringByReplacingOccurrencesOfString:@" " withString:@""]
                                 stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
	NSString *finalFontName = [m_literal_fonts objectForKey:tweakedFontName];
	if (finalFontName != nil) {
		return finalFontName;
	}
    
	// Parse given mixed-case font name into parts.
	// We are given strings like "bolditalic helvetica neue",
	// which needs to be parsed into "bolditalic" and "helvetica neue", so
	// first compare the first word to see if it is a keyword.	If it is not
	// a keyword then default to "normal" and use the whole string as a font
	// name.
    
	NSString *fontType = @"normal";
    
	// Based on the first character,
	switch (*font) {
		case 'b':
		case 'B':
			// Could be "bold" or "bolditalic"
			if (strncasecmp(font, "bold ", 5) == 0) {
				if (strncasecmp(font, "bolditalic ", 11) == 0) {
					fontType = @"bolditalic";
					font += 11;
				} else {
					fontType = @"bold";
					font += 5;
				}
			}
			break;
		case 'i':
		case 'I':
			// Could be "italic"
			if (strncasecmp(font, "italic ", 7) == 0) {
				fontType = @"italic";
				font += 7;
			}
			break;
		case 'n':
		case 'N':
			// Could be "normal"
			if (strncasecmp(font, "normal ", 7) == 0) {
				font += 7;
			}
			//break;
	}
    
	// If no subfont specified, whole font string is used as family name
	NSString *familyName = [[NSString stringWithUTF8String:font] lowercaseString];
    
	// Lookup font family
	NSDictionary *familyDict = [m_fonts objectForKey:familyName];
	if (familyDict == nil) {
		if (!m_reported_font_error) {
			LOG("{text} USER ERROR: Font family is not installed: '%s'. Switching to 'helvetica'.", font);
			m_reported_font_error = true;
		}
		familyName = @"helvetica";
		familyDict = [m_fonts objectForKey:familyName];
		if (familyDict == nil) {
			NSLOG(@"{text} ERROR: Unable to get fallback font family");
			return nil;
		}
	}
    
	// Lookup font name
	NSString *fontName = [familyDict objectForKey:fontType];
	if (fontName == nil) {
		if (!m_reported_font_error) {
			LOG("{text} USER ERROR: Font type is not installed for font family '%s': '%@'.	Switching to a default", font, fontType);
			m_reported_font_error = true;
		}
        
		// Try normal first
		fontType = @"normal";
		fontName = [familyDict objectForKey:fontType];
		if (fontName == nil) {
			NSArray *values = [familyDict allValues];
			if ([values count] == 0) {
				LOG("{text} ERROR: Unable to get fallback font type");
				return nil;
			}
            
			fontName = [values objectAtIndex:0];
		}
	}
    
	return fontName;

}
@end
