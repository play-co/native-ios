//
//  GameViewController.m
//  SImpleGame
//
//  Created by Derek Burch on 11/7/14.
//  Copyright (c) 2014 Derek Burch. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#include <sys/time.h>

@interface GameViewController () {

}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

extern "C" void eval_str(const char*);
extern "C" void js_tick(int);
extern "C" void core_timer_tick(int);
extern "C" void core_tick(int);

extern "C" void core_init(const char*, const char*, const char*, int, int, const char *, int, int, bool, const char*, const char*);
extern "C" void core_init_js(const char*, const char*);
extern "C" void core_init_gl(int, int);
extern "C" void core_run();
extern "C" void core_on_screen_resize(int, int);
extern int text_manager_init();
extern "C" void timestep_events_push(int, int, int, int);

#define LOG printf

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
	
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

static bool initialized = false;

static long getMilliseconds() {
	struct timeval time;
	gettimeofday(&time, NULL);
	long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
	return millis;
}

static long oldTime = 0;
	
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	if (!initialized) {
		const char *apkPath = "resources.bundle";
		bool remote_loading = true;
		
		CGRect rect = [view bounds];
		int width = rect.size.width * [UIScreen mainScreen].scale;
		int height = rect.size.height * [UIScreen mainScreen].scale;
		
		LOG("Calling core_init");
		LOG("Apk path is %s", apkPath);
		core_init("devkit.native.launchClient",
				  "http://localhost/",
				  "http://localhost/",
				  9200,
				  9200,
				  apkPath,
				  width,
				  height,
				  remote_loading,
				  NULL, // Disable OpenGL splash
				  "");
		LOG("Calling core_init_js");
		core_init_js("http://localhost:9200", "1");
		LOG("Calling _init_gl");
		GLint defaultFBO;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
		
		core_init_gl(defaultFBO, 0);
		LOG("Calling screen resize");
		core_on_screen_resize(width, height);
		LOG("calling core_run");
		core_run();
		initialized = true;
	}
	long newTime = getMilliseconds();
	long dt = newTime - oldTime;
	oldTime = newTime;
	core_tick(dt);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	float scale = [UIScreen mainScreen].scale;
	for( UITouch *touch in touches ) {
		CGPoint point = [touch locationInView: [touch view]];
		timestep_events_push((int) touch, 1, scale * point.x, scale * point.y);
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	float scale = [UIScreen mainScreen].scale;
	for( UITouch *touch in touches ) {
		CGPoint point = [touch locationInView: [touch view]];
		timestep_events_push((int) touch, 3, scale * point.x, scale * point.y);
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	float scale = [UIScreen mainScreen].scale;
	for( UITouch *touch in touches ) {
		CGPoint point = [touch locationInView: [touch view]];
		timestep_events_push((int) touch, 2, scale * point.x, scale * point.y);
	}
}

@end
