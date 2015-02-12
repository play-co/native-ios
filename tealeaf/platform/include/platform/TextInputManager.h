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
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import <Foundation/Foundation.h>
#import "TextInput.h"

@interface TextInputManager : NSObject

@property (nonatomic, retain) UIView *view;
@property (nonatomic, retain) NSMutableDictionary *inputs;
@property (nonatomic) float scale;
@property (nonatomic) float textScale;
@property (nonatomic) int idi;

- (int) addTextInputAtX:(int) x Y: (int) y width:(int) width height: (int) height text: (NSString*) text;
- (id) initWithSuperView: (UIView*) view;
- (TextInput *) getTextInputWithId:(int) id;
- (void) destroyTextInputWithId:(int) id;
- (void) dismissAll;
- (void) destroyAll;
+ (id) get;
+ (void) setSuperView: (UIView*) view;

@end
