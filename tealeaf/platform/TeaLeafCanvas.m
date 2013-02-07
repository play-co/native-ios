#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "TeaLeafCanvas.h"
#import "draw_textures.h"

#import <stdlib.h>
#import <sys/time.h>

#include "config.h"
#import "TextInputManager.h"

#include "texture_manager.h"

@implementation Tickable
-(void) tick: (int) dt {}
@end


//@implementation UITouch (TouchSorting)
//- (NSComparisonResult)compareAddress:(id)obj {
//	  if ((void *)self < (void *)obj) return NSOrderedAscending;
//	  else if ((void *)self == (void *)obj) return NSOrderedSame;
//	else return NSOrderedDescending;
//}
//@end

@interface TeaLeafCanvas (EAGLViewPrivate)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@interface TeaLeafCanvas (EAGLViewSprite)

- (void)setupView;

@end

@implementation TeaLeafCanvas

@synthesize tickCallback;
@synthesize animating;
@synthesize renderer;
@synthesize events;
@synthesize backingWidth, backingHeight;
@synthesize viewRenderbuffer;
@synthesize currentOrientation;
@synthesize scale;
@dynamic animationFrameInterval;
@synthesize textField;

// You must implement this
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id) initWithFrame: (CGRect) frame
{
	self = [super initWithFrame:frame];
	scale = [[UIScreen mainScreen] scale];
	return self;
}

- (void)viewDidAppear
{
	// Get the layer
	CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
	
	eaglLayer.opaque = YES;
	/*eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	*/
	//CGRect bounds = [[UIScreen mainScreen] bounds];
	//self.frame = CGRectMake(bounds.origin.x, -bounds.size.width / 2, bounds.size.height, bounds.size.width);
	
	
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	if(!context || ![EAGLContext setCurrentContext:context]) {
		[self release];
		return;
	}
	
	animating = FALSE;
	displayLinkSupported = FALSE;
	animationFrameInterval = 1;
	displayLink = nil;
	animationTimer = nil;
	lastDestTex = -1;
	
	self.multipleTouchEnabled = YES;
	touchData = [[NSMutableArray arrayWithCapacity:2] retain];
	
	// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
	// class is used as fallback when it isn't available.
	NSString *reqSysVer = @"3.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
		displayLinkSupported = TRUE;
	
	[self setupView];
	//[self drawView];
}

-(void) setDeviceOrientation:(UIDeviceOrientation) _orientation {
	if (_orientation != currentOrientation) {
		currentOrientation = _orientation;
		int width = backingWidth;
		int height = backingHeight;
	
		if (_orientation != UIDeviceOrientationLandscapeLeft) {
			left = 0;
			right = width;
			bottom = height;
			top = 0;
			
		} else {
			left = width;
			right = 0;
			bottom = 0;
			top = height;
		}
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
	   
		glOrthof(left, right, bottom, top, -1, 1);
		glMatrixMode(GL_MODELVIEW);

	}
}

- (void)layoutSubviews
{
	if (!context) { [self viewDidAppear]; }
	
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	//[self drawView];
}


- (BOOL)createFramebuffer
{
	NSLog(@"creating a framebuffer");

	return YES;
}


- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}


- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void) startAnimation
{
	if (!animating)
	{
		if (displayLinkSupported)
		{
			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
			// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
			// not be called in system versions earlier than 3.1.
			
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(tick)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval)
										target:self
										selector:@selector(tick)
										userInfo:nil
										repeats:TRUE];
		
		animating = TRUE;
		
		gettimeofday(&now, NULL);
	}
}

- (void)tick {

	prevTime = now;
	gettimeofday(&now, NULL);
	
	int dt = (int) (
			1000 * (now.tv_sec - prevTime.tv_sec)
			+ (now.tv_usec - prevTime.tv_usec) / 1000.0
		);

	if (self.tickCallback) {
		[tickCallback tick: dt];
	}

	[self showView];
}

- (void)stopAnimation
{
	if (animating)
	{
		if (displayLinkSupported)
		{
			[displayLink invalidate];
			displayLink = nil;
		}
		else
		{
			[animationTimer invalidate];
			animationTimer = nil;
		}
		
		animating = FALSE;
	}
}

- (void)setupView
{	
	if ([[UIScreen mainScreen] scale] == 2.0) {
		[self setContentScaleFactor:2.0];
		backingWidth *=2;
		backingHeight *=2;
	}
	// Sets up matrices and transforms for OpenGL ES
	left = 0, right = backingWidth, bottom = backingHeight, top = 0;
}


// Updates the OpenGL view when the timer fires
- (void)drawView
{
	[self clearView];
	[self showView];
}

- (void)clearView
{
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
}

- (void) showView
{
	[context presentRenderbuffer:GL_RENDERBUFFER];
}


// Release resources when they are no longer needed.
- (void)dealloc
{
	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	[touchData release];
	[context release];
	context = nil;
	
	[super dealloc];
}

-(int) getTouchOffsetX {
	return currentOrientation == UIDeviceOrientationLandscapeLeft ? backingWidth : 0;
}


-(int) getTouchOffsetY {
	return currentOrientation == UIDeviceOrientationLandscapeLeft ? backingHeight : 0;
}

// Handles the start of a touch
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[TextInputManager get] dismissAll];
	for (UITouch *t in touches) {
		UITouchWrapper *wrapper = [[UITouchWrapper alloc] initWithUITouch: t andView: self];
		[touchData addObject: wrapper];
		[wrapper release];
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *t in touches) {
		for (UITouchWrapper *w in touchData) {
			if ([w isForUITouch:t]) {
				[w updateWithUITouch: t forView: self];
				break;
			}
		}
	}
}

// Handles the end of a touch event.
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *t in touches) {
		for (UITouchWrapper *w in touchData) {
			if ([w isForUITouch:t]) {
				[w removeWithUITouch: t forView: self];
				[touchData removeObject:w];
				break;
			}
		}
	}
}

// Touches cancelled by system event: e.g. phone call
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *t in touches) {
		for (UITouchWrapper *w in touchData) {
			if ([w isForUITouch:t]) {
				[w removeWithUITouch: t forView: self];
				[touchData removeObject:w];
				break;
			}
		}
	}
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) orientation {
	NSLog(@"rotating!!!!!!!!!!!!");
}

- (BOOL) canResignFirstResponder {
	return YES;
}

@end
