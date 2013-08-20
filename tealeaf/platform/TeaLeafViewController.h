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

#import "js_core.h"

#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>

@interface TeaLeafViewController : UIViewController <MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate> {
@private
int callback;
UITextField *inputAccTextField;
}

//input accessory view
@property (nonatomic, retain) UITextField *inputAccTextField;
@property (nonatomic, retain) UIImageView *loading_image_view;
@property (nonatomic, retain) UIAlertView *backAlertView;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) NSString *photoURL;
@property int photoWidth;
@property int photoHeight;
- (TeaLeafViewController*) init;

- (TeaLeafViewController *) init;

- (void) sendSMSTo:(NSString *)number withMessage:(NSString *)message andCallback:(int)callback;
- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result;
- (void) alertView:(UIAlertView *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void) restartJS;

- (void) assignCallback:(int)cb;
- (void) runCallback:(char *)arg;

- (void)showImagePickerForCamera: (NSString *) url;
- (void)showImagePickerForPhotoPicker: (NSString *) url;

@end


@interface UIAlertViewEx : UIAlertView {

@private
    int *callbacks;
	int length;
}
- (void) dispatch:(int)callback;
- (void) registerCallbacks:(int *)callbacks length:(int)length;
- (void) dealloc;

@end
