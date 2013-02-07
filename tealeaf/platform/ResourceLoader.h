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
#import "Texture2D.h"

@interface ResourceLoader : NSObject

@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *appBundle;
@property (nonatomic, retain) NSCondition *imageWaiter;
@property (nonatomic, retain) NSMutableArray *images;

- (NSString *) initStringWithContentsOfURL:(NSString *)url;
- (NSURL *) resolve:(NSString *)url;
- (NSURL *) resolveFile:(NSString *)url;
- (NSURL *) resolveFileUrl:(NSString *)url;
- (NSURL *) resolveUrl:(NSString *)url;

- (void) finishLoadingText:(NSString *)url;

- (void) imageThread;
- (void) loadImage:(NSString *)url;
+ (ResourceLoader *) get;
+ (void) release;
@end
