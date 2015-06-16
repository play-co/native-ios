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
 * along with the Game Closure SDK.	 If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import "TeaLeafViewController.h"
#import "RawImageInfo.h"
#import "Base64.h"

#import "jsMacros.h"
#import "js_core.h"
#import "core/log.h"
#import "TeaLeafAppDelegate.h"
#import "ResourceLoader.h"
#import "NativeCalls.h"
#import "core/core.h"
#import "core/tealeaf_canvas.h"
#import "jansson.h"
#import "jsonUtil.h"
#import "allExtensions.h"
#include "platform.h"
#import "iosVersioning.h"
#include "core/core_js.h"
#include "core/texture_manager.h"
#include "core/config.h"
#include "core/events.h"

#include "TeaLeafTextField.h"


static volatile BOOL m_showing_splash = NO; // Maybe showing splash screen?

CEXPORT void device_hide_splash() {
	// If showing the splash screen,
	if (m_showing_splash) {
		// Give the game another 1 second to finish loading textures
		[((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]).tealeafViewController.loading_image_view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
		[UIView setAnimationsEnabled:YES];
        
		m_showing_splash = NO;
	}
}


@interface TeaLeafViewController ()
@property (nonatomic, assign) TeaLeafAppDelegate *appDelegate;
@end


@implementation TeaLeafViewController

@synthesize inputAccTextField;


- (TeaLeafViewController*) init {
	self = [super init];
	
	self.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);
    
	[self.appDelegate selectOrientation];
    
	self.popover = nil;
    
	return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void) dealloc {
	self.popover = nil;
    
	[super dealloc];
}

- (void) restartJS {
	UIViewController *controller = nil;
    
#ifndef DISABLE_TESTAPP
	if (!self.appDelegate.isTestApp) {
#endif
		controller = self.appDelegate.tealeafViewController;
#ifndef DISABLE_TESTAPP
	} else {
		controller = self.appDelegate.appTableViewController;
	}
#endif
    
	if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		[self.view removeFromSuperview];
        
		[self.appDelegate.window addSubview:controller.view];
	} else {
		[self.appDelegate.window setRootViewController:controller];
	}
	self.appDelegate.tealeafShowing = NO;
    
	if (js_ready) {
		dispatch_async(dispatch_get_main_queue(), ^{
			core_reset();
		});
	}
}

- (void) alertView:(UIAlertView *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
		[(UIAlertViewEx*)sheet dispatch:(int)buttonIndex];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	if (m_showing_splash) {
		[UIView setAnimationsEnabled:NO];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[UIView setAnimationsEnabled:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (m_showing_splash) {
		[UIView setAnimationsEnabled:NO];
	}
    
	if (!self.appDelegate.gameSupportsPortrait) {
		return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
	}
	
	if (!self.appDelegate.gameSupportsLandscape) {
		return (toInterfaceOrientation == UIInterfaceOrientationPortrait) ||
        (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	}
    
	return YES;
}

-(BOOL)shouldAutorotate {
	if (m_showing_splash) {
		[UIView setAnimationsEnabled:NO];
	}
    
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	NSUInteger mask = 0;
	
	if (self.appDelegate.gameSupportsPortrait) {
		mask |= UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
	}
    
	if (self.appDelegate.gameSupportsLandscape) {
		mask |= UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
	}
    
	return mask;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)onJSReady {
	//This needs to be run on the main thread - it does some opengl stuff
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.appDelegate.pluginManager initializeWithManifest:self.appDelegate.appManifest appDelegate:self.appDelegate];
		
		self.appDelegate.launchNotification = nil;
		
		// Initialize reachability notifications
		[self.appDelegate initializeOnlineState];
		
		core_run();
		
		[self.appDelegate postPauseEvent:self.appDelegate.wasPaused];
		
		// Start listening for changes to online state
		[self.appDelegate hookOnlineState];
        
        // subscribe to orientation change events
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:)
                                                     name:@"UIDeviceOrientationDidChangeNotification"
                                                   object:nil];
	});
    
}

- (void) didRotate: (NSNotification *) notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    const char *orientationName;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            orientationName = "portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientationName = "portraitUpsideDown";
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientationName = "landscapeLeft";
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationName = "landscapeRight";
            break;
        case UIDeviceOrientationFaceUp:
            orientationName = "faceUp";
            break;
        case UIDeviceOrientationFaceDown:
            orientationName = "faceDown";
            break;
        case UIDeviceOrientationUnknown:
        default:
            orientationName = "unknown";
            break;
    }
	NSString *evt = [NSString stringWithFormat: @"{\"name\":\"rotate\",\"orientation\":\"%s\"}", orientationName];
	core_dispatch_event([evt UTF8String]);
}

- (void) destroyGLView {
	OpenGLView *glView = self.appDelegate.canvas;
    
	[glView destroyDisplayLink];
    
	[glView removeFromSuperview];
    
	self.view = nil;
	self.appDelegate.canvas = nil;
}

- (void) createGLView {
	//create our openglview and size it correctly
	OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.appDelegate.initFrame];
    
	self.view = glView;
	self.appDelegate.canvas = glView;
    
	core_init_gl(1);
    
	int w = self.appDelegate.screenWidthPixels;
	int h = self.appDelegate.screenHeightPixels;
	tealeaf_canvas_resize(w, h);
    
	NSLOG(@"{tealeaf} Created GLView (%d, %d)", w, h);
}

- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7 hide status bar
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
	/*
	 * based on reported width and height, calculate the width and
	 * height we care about with respect to scale (retina displays)
	 * and orientation (swapping width and height)
	 */
	
	[self.appDelegate updateScreenProperties];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onKeyboardChange:) name: UIKeyboardWillShowNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onKeyboardChange:) name: UIKeyboardWillHideNotification object: nil];
    
	NSString *appBundle = [ResourceLoader get].appBundle;
	const char *source_path = 0;
    
	if (!appBundle) {
		NSLOG(@"{core} FATAL: Unable to load app bundle!");
	} else {
		source_path = [[ResourceLoader get].appBundle UTF8String];
	}
    
	if (!source_path || *source_path == '\0') {
		source_path = [[self.appDelegate.config objectForKey:@"source_dir"] UTF8String];
	}
	
	core_init([[self.appDelegate.config objectForKey:@"entry_point"] UTF8String],
			  [[self.appDelegate.config	objectForKey:@"tcp_host"] UTF8String],
			  [[self.appDelegate.config	objectForKey:@"code_host"] UTF8String],
			  [[self.appDelegate.config	objectForKey:@"tcp_port"] intValue],
			  [[self.appDelegate.config	objectForKey:@"code_port"] intValue],
			  source_path, self.appDelegate.screenWidthPixels, self.appDelegate.screenHeightPixels,
			  self.appDelegate.isTestApp,
			  NULL, // Disable OpenGL splash
			  "");
	
	// Lower texture memory based on device model
    NSLOG(@"{core} iOS device model '%@'", get_platform());
    
	long mem_limit = get_platform_memory_limit();
	
	if (self.appDelegate.ignoreMemoryWarnings) {
		mem_limit = 28000000; // Impose lower memory limit for this work-around case
	}
    
	texture_manager_set_max_memory(texture_manager_get(), mem_limit);
    
	[self createGLView];
    
	/*
	 * add a temporary imageview with the loading image.
	 * This smooths the transition between the launch image
	 * and our opengl loading image so there's no gap
	 */
    
	NSURL *loading_path = [[ResourceLoader get] resolve:self.appDelegate.screenBestSplash];
	NSData *data = [NSData dataWithContentsOfURL:loading_path];
	UIImage *loading_image_raw = [UIImage imageWithData: data];
    
	UIImageOrientation splashOrientation = UIImageOrientationUp;
	int frameWidth = (int)self.appDelegate.window.frame.size.width;
	int frameHeight = (int)self.appDelegate.window.frame.size.height;
    
	int w = self.appDelegate.screenWidthPixels;
	int h = self.appDelegate.screenHeightPixels;
    
	bool needsFrameRotate = w > h;
	needsFrameRotate ^= frameWidth > frameHeight;
	if (needsFrameRotate) {
		// This happens on the iPhone when orientated on its side
		int temp = frameWidth;
		frameWidth = frameHeight;
		frameHeight = temp;
	}
    
	bool needsOrientRotate = w > h;
	needsOrientRotate ^= loading_image_raw.size.width > loading_image_raw.size.height;
	if (needsOrientRotate) {
		splashOrientation = UIImageOrientationRight;
	}
    
	UIImage *loading_image = [UIImage imageWithCGImage:loading_image_raw.CGImage scale:1.f orientation:splashOrientation];
	self.loading_image_view = [[UIImageView alloc] initWithImage:loading_image];
	self.loading_image_view.frame = CGRectMake(0, 0, frameWidth, frameHeight);
    
	//add the openglview to our window
    
	[self.appDelegate.window addSubview:self.view];
	self.appDelegate.window.rootViewController = self;
	[self.appDelegate.window.rootViewController.view addSubview:self.loading_image_view];
    
    self.inputAccTextField = [[[UITextField alloc] init] autorelease];
    self.inputAccTextField.hidden = true;
    [self.appDelegate.window.rootViewController.view addSubview:self.inputAccTextField];
	m_showing_splash = YES;
    
	// Initialize text manager
	if (!text_manager_init()) {
		NSLOG(@"{tealeaf} ERROR: Unable to initialize text manager.");
	}
	
	// Setup the JS runtime in the main thread
	if (!setup_js_runtime()) {
		NSLOG(@"{tealeaf} ERROR: Unable to setup javascript runtime.");
	}
    
	// PluginManager gets initialized after createJS() so that events are generated after core js is loaded
	self.appDelegate.pluginManager = [[[PluginManager alloc] init] autorelease];
	
	// Run JS initialization in another thread
  NSString *baseURL = [NSString stringWithFormat:@"http://%@:%d/", [self.appDelegate.config objectForKey:@"code_host"], [[self.appDelegate.config objectForKey:@"code_port"] intValue]];
  
  
  if (!core_init_js([baseURL UTF8String], [(NSString*)[self.appDelegate.config objectForKey:@"native_hash"] UTF8String])) {
    NSLOG(@"{tealeaf} ERROR: Unable to initialize javascript.");
  } else {
    [self onJSReady];
  }
	
	[self.appDelegate.canvas startRendering];
    
#ifndef DISABLE_TESTAPP
	if (self.appDelegate.isTestApp) {
		UIRotationGestureRecognizer *rotationRecognizer =
		[[UIRotationGestureRecognizer alloc]
         initWithTarget:self
         action:@selector(rotationDetected:)];
		[self.view addGestureRecognizer:rotationRecognizer];
		[rotationRecognizer release];
		self.backAlertView = [[UIAlertView alloc] initWithTitle:@"Return to Games List?"
                                                        message:@"Would you like to return to the games list?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
	}
#endif
    
    TeaLeafTextField *textField = [[TeaLeafTextField alloc] init];
    [[(TeaLeafViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController] view] addSubview:textField];
    
}


- (void) onKeyboardChange:(NSNotification *)info {
    NSDictionary *userInfo = [info userInfo];
    CGRect rawKeyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect properlyRotatedCoords = [self.view.window convertRect:rawKeyboardRect toView:self.view];
    CGFloat scale = self.view.contentScaleFactor;
    properlyRotatedCoords.origin.x *= scale;
    properlyRotatedCoords.origin.y *= scale;
    properlyRotatedCoords.size.width *= scale;
    properlyRotatedCoords.size.height *= scale;
    
    // TODO: might need this if the status bar is visible to compute the y-offset?
    // CGSize size = self.view.frame.size;
    
	JSContext* cx = [[js_core lastJS] cx];
	JSObject* event = JS_NewObject(cx, NULL, NULL, NULL);
  JS::RootedValue name(cx, JS::StringValue(JS_InternString(cx, "keyboardScreenResize")));
  JS::RootedValue height(cx, JS::NumberValue(properlyRotatedCoords.origin.y));
	JS_SetProperty(cx, event, "name", name);
	JS_SetProperty(cx, event, "height", height);
    
  JS::RootedValue evt(cx, OBJECT_TO_JSVAL(event));
	[[js_core lastJS] dispatchEvent:evt];
}

- (IBAction)rotationDetected:(UIGestureRecognizer *)sender {
	CGFloat velocity =
	[(UIRotationGestureRecognizer *)sender velocity];
    
	if (fabs(velocity) > 5) {
		if (!self.backAlertView.isVisible) {
			[self.backAlertView show];
		}
	}
}

- (void)assignCallback:(int)cb {
	callback = cb;
}

- (void)runCallback:(char *)arg {
	js_core* instance = [js_core lastJS];
  JS::RootedValue js_arg(instance.cx, STRING_TO_JSVAL(JS_NewStringCopyZ(instance.cx, arg)));
	[instance dispatchEvent:js_arg];
}

- (void)sendSMSTo:(NSString *)number withMessage:(NSString *)msg andCallback:(int)cb {
	if([MFMessageComposeViewController canSendText]) {
		MFMessageComposeViewController* sms = [[MFMessageComposeViewController alloc] init];
		sms.body = msg;
		sms.recipients = [NSArray arrayWithObject: number];
		sms.messageComposeDelegate = self;
		sms.delegate = self;
		[self assignCallback: cb];
		[self presentModalViewController: sms animated:YES];
		[sms release];
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissModalViewControllerAnimated: YES];
	char args[128];
	// TODO replace with JS_* calls
	sprintf(args, "{\"name\":\"smsStatus\", \"id\":%d, \"result\":%d}", callback, (int)result);
	[self runCallback: args];
}

- (void)showImagePickerForCamera:(NSString *)url width:(int)width height:(int)height crop:(int)crop {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera andURL:url width:width height:height crop:(int)crop];
}

- (void)showImagePickerForPhotoPicker:(NSString *)url width:(int)width height:(int)height crop:(int)crop {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary andURL:url width:width height:height crop:(int)crop];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType andURL:(NSString *)url width:(int)width height:(int)height crop:(int)crop
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    self.photoURL = url;
	self.photoWidth = width;
    self.photoHeight = height;
	self.photoCrop = crop;
    
    self.imagePickerController = imagePickerController;
    
	// Apple requires that we do this particular source type on iPad with a popover.
	if ((sourceType == UIImagePickerControllerSourceTypePhotoLibrary) &&
		[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
		popover.delegate = self;
        
		// Manually set rectangle since the view bounds are not working for this.
		CGRect rect;
		rect.origin.x = 0;
		rect.origin.y = 0;
		rect.size.width = self.appDelegate.screenWidthPixels - 64;
		rect.size.height = self.appDelegate.screenHeightPixels - 64;
        
		// Follow documentation to limit width of popover.
		if (rect.size.width > 600) {
			rect.size.width = 600;
		}
        
		// Present it once..
		[popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
		// Store it for later cleanup
		self.popover = popover;
	} else {
		[self presentModalViewController:imagePickerController animated:YES];
        
		// On iOS 7 the status bar decides to come back here
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
	// Always dismiss popover if user tries to close it.
	return YES;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.f);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)cropWithImage:(UIImage *)image withRect:(CGRect)rect {
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:1.f orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    return result;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[PluginManager get] dispatchJSEvent:@{ @"name" : @"PhotoBeginLoaded"}];
    
	if (self.popover != nil) {
		[self.popover dismissPopoverAnimated:YES];
	}
	
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    float bmpWidth = image.size.width;
    float bmpHeight = image.size.height;

	// If cropping,
	if (self.photoCrop != 0) {
		// Stretch as little as possible
		float wScale = self.photoWidth / bmpWidth;
		float hScale = self.photoHeight / bmpHeight;

		float minScale = (hScale > wScale) ? hScale : wScale;
		CGSize size = CGSizeMake(minScale * bmpWidth, minScale * bmpHeight);
		image = [self imageWithImage:image scaledToSize:size];

		// Now crop the edges off what remains
	    image = [self cropWithImage:image withRect:CGRectMake((image.size.width - self.photoWidth) / 2.f,
    	                                                      (image.size.height - self.photoHeight) / 2.f,
        	                                                  self.photoWidth,
            	                                              self.photoHeight)];
	}

    NSData *data = UIImagePNGRepresentation(image);
    NSString *b64Image = [NSString stringWithFormat:@"image/png;base64,%@", encodeBase64(data)];
    [[PluginManager get] dispatchJSEvent:@{ @"name" : @"PhotoLoaded", @"url": self.photoURL, @"data": b64Image }];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
	// Make sure the status bar is gone
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
	if (self.popover != nil) {
		[self.popover dismissPopoverAnimated:YES];
	}
    
	// Make sure the status bar is gone
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

@end

@implementation UIAlertViewEx

- (void) dispatch:(int)callbackIndex {
	JSContext* cx = [[js_core lastJS] cx];
  JS::RootedObject event(cx, JS_NewObject(cx, NULL, NULL, NULL));
  JS::RootedValue name(cx, JS::StringValue(JS_NewStringCopyZ(cx, "dialogButtonClicked")));
  JS::RootedValue idv(cx, JS::NumberValue(self->callbacks[callbackIndex]));
	JS_SetProperty(cx, event, "name", name);
	JS_SetProperty(cx, event, "id", idv);
    
  JS::RootedValue evt(cx, OBJECT_TO_JSVAL(event));
	[[js_core lastJS] dispatchEvent:evt];
}

- (void) registerCallbacks:(int *)cbs length:(int)len {
	self->callbacks = (int*)malloc(len * sizeof(int));
	memcpy(self->callbacks, cbs, len * sizeof(int));
	self->length = len;
}

- (void) dealloc {
	free(self->callbacks);
	[super dealloc];
}

@end

