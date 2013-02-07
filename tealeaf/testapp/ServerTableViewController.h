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

#import <UIKit/UIKit.h>

//helper info class
@interface ServerInfo : NSObject

@property (nonatomic, retain) NSString *ip;
@property (nonatomic) NSInteger port;

@end

//actual controller
@interface ServerTableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *listData;
}

@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) NSMutableArray *listData;
@property(nonatomic, retain) UITextField *ipInputView;
@property(nonatomic, retain) UITextField *portInputView;
@property(nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (ServerInfo *)addServerInfoFromAddressData:(NSData *)dataIn; // may return nil

@end


