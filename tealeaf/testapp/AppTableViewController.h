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

#import <UIKit/UIKit.h>

@interface AppTableViewController : UIViewController
<UITableViewDelegate,UITableViewDataSource>{
    NSMutableArray *listData;
    UIProgressView *progressBar;
    UIView *progressviewBacking;
    UITextView *loadingTextView ;
}
@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) NSMutableArray *listData;
@property (nonatomic, retain) UIView *progressviewBacking;
@property (nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic, retain) UITextView *loadingTextView;
- (void) appLoadListThread;
- (void) loadAppThread;
@end
