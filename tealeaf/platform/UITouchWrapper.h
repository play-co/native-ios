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
#import "jsapi.h"

@interface UITouchWrapper : NSObject {
	int uid;
	void *addr;
    int touchId;
}

-(id) initWithUITouch: (UITouch *) touch andView: (UIView *) view andId:(int) id;
-(bool) isForUITouch: (UITouch *) touch;
-(void) updateWithUITouch: (UITouch *) touch forView: (UIView *) view;
-(void) removeWithUITouch: (UITouch *) touch forView: (UIView *) view;
-(void) addEvent: (int) name withUITouch: (UITouch *) touch forView: (UIView *) view;
@property (nonatomic) int uid;

@end
