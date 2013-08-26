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
#import "core/core.h"
#import "core/tealeaf_canvas.h"
#import "JSONKit.h"
#import "jansson.h"
#import "jsonUtil.h"
#import "allExtensions.h"
#include "platform.h"
#import "iosVersioning.h"
#include "core/core_js.h"
#include "core/texture_manager.h"
#include "core/config.h"
#include "core/events.h"

#include <sys/types.h>
#include <sys/sysctl.h>


// Get hw.machine
static NSString *get_platform() {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size + 1);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    machine[size] = '\0';
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}


static volatile BOOL m_showing_splash = NO; // Maybe showing splash screen?

CEXPORT void device_hide_splash() {
	// If showing the splash screen,
	if (m_showing_splash) {
		// Hide it immediately!
		[((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]).tealeafViewController.loading_image_view removeFromSuperview];

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
	
	NSArray *supportedOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

	self.appDelegate.gameSupportsLandscape = NO;
	self.appDelegate.gameSupportsPortrait = NO;

	// If no orientations supported,
	if (supportedOrientations) {
		for (int ii = 0; ii < [supportedOrientations count]; ++ii) {
			NSString *orientation = [supportedOrientations objectAtIndex:ii];

			if ([orientation isEqualToString:@"UIInterfaceOrientationPortrait"]) {
				NSLOG(@"{tealeaf} Game supports portrait mode: %@", orientation);
				self.appDelegate.gameSupportsPortrait = YES;
			} else if ([orientation isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) {
				NSLOG(@"{tealeaf} Game supports portrait mode: %@", orientation);
				self.appDelegate.gameSupportsPortrait = YES;
			} else if ([orientation isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) {
				NSLOG(@"{tealeaf} Game supports landscape mode: %@", orientation);
				self.appDelegate.gameSupportsLandscape = YES;
			} else if ([orientation isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
				NSLOG(@"{tealeaf} Game supports landscape mode: %@", orientation);
				self.appDelegate.gameSupportsLandscape = YES;
			}
		}
	}

	// If no orientations supported,
	if (!self.appDelegate.gameSupportsLandscape &&
		!self.appDelegate.gameSupportsPortrait) {
		// Support any orientation
		self.appDelegate.gameSupportsLandscape = YES;
		self.appDelegate.gameSupportsPortrait = YES;
	}
	
	// Read manifest file
	NSError *err = nil;
	NSString *manifest_file = [[ResourceLoader get] initStringWithContentsOfURL:@"manifest.json"];
	NSDictionary *dict = nil;
	NSUInteger length = 0;
	if (manifest_file) {
		JSONDecoder *decoder = [JSONDecoder decoderWithParseOptions:JKParseOptionStrict];
		const char *manifest_utf8 = (const char *) [manifest_file UTF8String];
		length = strlen(manifest_utf8);
		dict = [decoder objectWithUTF8String:(const unsigned char *)manifest_utf8 length:length error:&err];
	}

	// If failed to load,
	if (!dict) {
		NSLOG(@"{manifest} Invalid JSON formatting: %@ (bytes:%d)", err ? err : @"(no error)", length);
	} else {
		self.appDelegate.appManifest = dict;
		NSLOG(@"{manifest} Successfully read manifest file from bundle");
	}
	
	return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void) dealloc {
   /* [inputAccTextField release];
    [inputAccView release];
    [inputAccBtnDone release];
    [inputAccBtnPrev release];
    [inputAccBtnNext release];*/
	[super dealloc];
}

-(void)createInputAccessoryView{
/*    inputAccView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 310.0, 40.0)];
    
    [inputAccView setBackgroundColor:[UIColor lightGrayColor]];
    
    [inputAccView setAlpha: 1.0];
    
    inputAccBtnPrev = [UIButton buttonWithType: UIButtonTypeCustom];
    
    [inputAccBtnPrev setFrame: CGRectMake(0.0, 0.0, 80.0, 40.0)];
    [inputAccBtnPrev setTitle: @"Prev" forState: UIControlStateNormal];
    [inputAccBtnPrev setBackgroundColor: [UIColor blueColor]];
    [inputAccBtnPrev addTarget: self action: @selector(gotoPrevTextfield) forControlEvents: UIControlEventTouchUpInside];
    
    inputAccBtnNext = [UIButton buttonWithType:UIButtonTypeCustom];
    [inputAccBtnNext setFrame:CGRectMake(85.0f, 0.0f, 80.0f, 40.0f)];
    [inputAccBtnNext setTitle:@"Next" forState:UIControlStateNormal];
    [inputAccBtnNext setBackgroundColor:[UIColor blueColor]];
    [inputAccBtnNext addTarget:self action:@selector(gotoNextTextfield) forControlEvents:UIControlEventTouchUpInside];
    
    inputAccBtnDone = [UIButton buttonWithType:UIButtonTypeCustom];
    [inputAccBtnDone setFrame:CGRectMake(240.0, 0.0f, 80.0f, 40.0f)];
    [inputAccBtnDone setTitle:@"Done" forState:UIControlStateNormal];
    [inputAccBtnDone setBackgroundColor:[UIColor greenColor]];
    [inputAccBtnDone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [inputAccBtnDone addTarget:self action:@selector(doneTyping) forControlEvents:UIControlEventTouchUpInside];
    
    [inputAccView addSubview:inputAccBtnPrev];
    [inputAccView addSubview:inputAccBtnNext];
    [inputAccView addSubview:inputAccBtnDone];*/
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [self createInputAccessoryView];
    
//    [textField setInputAccessoryView:inputAccView];
    
    //need to set the active text field somehow...
//    txtActiveField = textField;
}

-(void)gotoPrevTextfield{
  //  [inputAccActiveTextField becomeFirstResponder];
}

-(void)gotoNextTextfield{
  //  [inputAccActiveTextField becomeFirstResponder];
}

-(void)doneTyping{
    // When the "done" button is tapped, the keyboard should go away.
    // That simply means that we just have to resign our first responder.
    //[inputAccActiveTextField resignFirstResponder];
}

- (void) restartJS {
	UIViewController *controller = nil;

#ifndef UNITY
	bool isRemoteLoading = [[self.config objectForKey:@"remote_loading"] boolValue];
	if (!isRemoteLoading) {
#endif
		controller = self.appDelegate.tealeafViewController;
#ifndef UNITY
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
	NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
	if ([title isEqualToString:@"Yes"]) {
		[self restartJS];
	} else if ([title isEqualToString:@"No"]) {
		//do nothing
	} else {
		[(UIAlertViewEx*)sheet dispatch: buttonIndex];
		[sheet release];
	}
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
		NSLog(@"WTF");
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
			  [[self.appDelegate.config objectForKey:@"remote_loading"] boolValue],
			  [self.appDelegate.screenBestSplash UTF8String],
			  "");
	
	// Lower texture memory based on device model
    NSString *platform = get_platform();
    NSLog(@"{core} iOS device model '%@'", platform);

	texture_manager_set_max_memory(texture_manager_get(), get_platform_memory_limit());

	//create our openglview and size it correctly
	OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.appDelegate.initFrame];
	self.view = glView;
	self.appDelegate.canvas = glView;
	core_init_gl(1);

	int w = self.appDelegate.screenWidthPixels;
	int h = self.appDelegate.screenHeightPixels;
	tealeaf_canvas_resize(w, h);

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
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
		NSString *baseURL = [NSString stringWithFormat:@"http://%@:%d/", [self.appDelegate.config objectForKey:@"code_host"], [[self.appDelegate.config objectForKey:@"code_port"] intValue]];
		
		if (!core_init_js([baseURL UTF8String], [(NSString*)[self.appDelegate.config objectForKey:@"native_hash"] UTF8String])) {
			NSLOG(@"{tealeaf} ERROR: Unable to initialize javascript.");
		} else {
			[self onJSReady];
			[self.appDelegate postPauseEvent:self.appDelegate.wasPaused];
		}
	});
	
	[self.appDelegate.canvas startRendering];
	
	if ([[self.appDelegate.config objectForKey:@"remote_loading"] boolValue]) {
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
}

- (void) onKeyboardChange:(NSNotification *)info {
    NSDictionary *userInfo = [info userInfo];
    CGRect rawKeyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect properlyRotatedCoords = [self.view.window convertRect:rawKeyboardRect toView:self.view];
    CGSize size = self.view.frame.size;

	JSContext* cx = [[js_core lastJS] cx];
	JSObject* event = JS_NewObject(cx, NULL, NULL, NULL);
	jsval name = STRING_TO_JSVAL(JS_InternString(cx, "keyboardScreenResize"));
	jsval height = INT_TO_JSVAL(properlyRotatedCoords.origin.y);
	JS_SetProperty(cx, event, "name", &name);
	JS_SetProperty(cx, event, "height", &height);
    
	jsval evt = OBJECT_TO_JSVAL(event);
	[[js_core lastJS] dispatchEvent:&evt count:1];
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

static NSString *fixDictString(NSDictionary *dict, NSString *key) {
	NSString *value = [dict objectForKey:key];
	
	if (!value) {
		NSLOG(@"{settings} ERROR: Missing value for key %@", key);
		
		return @"";
	} else {
		return value;
	}
}

- (void)assignCallback:(int)cb {
	callback = cb;
}

- (void)runCallback:(char *)arg {
	js_core* instance = [js_core lastJS];
	jsval args[] = { STRING_TO_JSVAL(JS_NewStringCopyZ(instance.cx, arg)) };
	[instance dispatchEvent: args count: 1];
}

- (void)showImagePickerForCamera: (NSString *) url
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera andURL: url];
}


- (void)showImagePickerForPhotoPicker: (NSString *) url
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary andURL: url];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType andURL: (NSString *) url
{
       
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    self.photoURL = url;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    CGSize size = CGSizeMake(128, 128);
    image = [self imageWithImage: image scaledToSize: size];
    //TODO send an event to JS
    
    NSData *data = UIImagePNGRepresentation(image);
    NSString *b64Image = encodeBase64(data);
    NSDictionary *event = @{ @"name" : @"PhotoLoaded", @"url": self.photoURL, @"data": b64Image};
    [[PluginManager get] dispatchJSEvent: event];
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end

@implementation UIAlertViewEx

- (void) dispatch:(int)callback {
	JSContext* cx = [[js_core lastJS] cx];
	JSObject* event = JS_NewObject(cx, NULL, NULL, NULL);
	jsval name = STRING_TO_JSVAL(JS_InternString(cx, "dialogButtonClicked"));
	jsval idv = INT_TO_JSVAL(callback);
	JS_SetProperty(cx, event, "name", &name);
	JS_SetProperty(cx, event, "id", &idv);

	jsval evt = OBJECT_TO_JSVAL(event);
	[[js_core lastJS] dispatchEvent:&evt count:1];
}

- (void) registerCallbacks:(int *)cbs length:(int)len {
	self->callbacks = (int*)malloc(len * sizeof(int));
	memcpy(self->callbacks, cbs, len);
	self->length = len;
}

- (void) dealloc {
	[ResourceLoader release];
	free(self->callbacks);
	[super dealloc];
}

@end
