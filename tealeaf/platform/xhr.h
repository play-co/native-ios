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

@interface XHR : NSObject

@property(nonatomic) int status;
@property(nonatomic) int state;
@property(nonatomic) int myID;
@property(nonatomic, retain) NSMutableData *data;
@property(nonatomic, retain) NSDictionary *headers;
@property(nonatomic, retain) NSURLConnection *connection;

+ (XHR *) httpRequestForURL:(NSURL *)url withMethod:(NSString *)method andBody:(NSString *)body andHeaders:(NSDictionary *)hdrs andID:(int)theId;

@end

