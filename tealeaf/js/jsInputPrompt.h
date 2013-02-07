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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "js/js_core.h"


@interface InputPromptView : NSObject <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, retain) UIAlertView *inputPromptAlertView;
@property (nonatomic, retain) UITextField *inputPromptTextField;

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message value:(NSString*)value autoShowKeyboard:(BOOL)autoShowKeyboard;

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+ (InputPromptView *) get;

@end


@interface jsInputPrompt : NSObject

+ (void) addToRuntime:(js_core *)js;
+ (void) onDestroyRuntime;

@end
