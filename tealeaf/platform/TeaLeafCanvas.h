#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <GLKit/GLKit.h>

#import "jsapi.h"
#import "UITouchWrapper.h"
@class jsEvents;

@interface Tickable : NSObject {}
-(void) tick: (int) dt;
@end


@interface TeaLeafCanvas : UIView
{
	/* The pixel dimensions of the backbuffer */
	GLint backingWidth;
	GLint backingHeight;
	
@private
	
	
	EAGLContext *context;
	
	id renderer;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint offscreenFramebuffer;
    
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint depthRenderbuffer;
	
	BOOL animating;
	BOOL displayLinkSupported;
	NSInteger animationFrameInterval;
	// Use of the CADisplayLink class is the preferred method for controlling your animation timing.
	// CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
	// The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
	// isn't available.
	id displayLink;
    NSTimer *animationTimer;
	
	NSMutableArray *touchData;
	jsEvents *events;
	
	struct timeval prevTime, now;
	
	Tickable *tickCallback;

    UIDeviceOrientation currentOrientation;
    int left, right, bottom, top;

    UITextField *textField;
    
    int lastDestTex;
    
    float scale;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (assign) id renderer;
@property (assign) Tickable *tickCallback;
@property (nonatomic, assign) jsEvents *events;
@property (readonly, nonatomic) GLint backingWidth;
@property (readonly, nonatomic) GLint backingHeight;
@property (readonly, nonatomic) GLuint viewRenderbuffer;
@property (readonly) UIDeviceOrientation currentOrientation;
@property (readonly) float scale;

@property (retain) UITextField* textField;
- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;
- (void)clearView;
- (void)showView;
- (void)tick;
- (void)viewDidAppear;
- (void) setDeviceOrientation:(UIDeviceOrientation) orientation;
- (void)bindRenderBuffer;
- (void)destroyFramebuffer;
- (int) getTouchOffsetX;
- (int) getTouchOffsetY;


@end
