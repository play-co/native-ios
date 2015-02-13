//
//  FontUtil.h
//  TeaLeafIOS
//
//  Created by Jared Petker on 9/26/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FontUtil : NSObject
//+ (NSDictionary *) m_fonts;
+ (void) setM_fonts:(NSDictionary *) fonts;
//+ (NSDictionary *) m_literal_fonts;
+ (void) setM_literal_fonts:(NSDictionary *) literalFonts;
+ (NSString*) fixFontName:(const char *)font;
@end
