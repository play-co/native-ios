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

#import "OpenGLView.h"
#include "core/core.h"
#include "core/tealeaf_context.h"
#import "TextInputManager.h"
#import "TeaLeafAppDelegate.h"
#import "platform/log.h"
#import "timestep_events.h"

void timestep_animation_tick_animations(double);

@implementation OpenGLView

static CADisplayLink *displayLink;

- (id)init {
	self = [super init];
	if (self) {
		cond = [NSCondition new];
	}
	
	return self;
}

- (void)dealloc
{
	NSLOG(@"Exciting: Deallocating OpenGLView");
	
	[self destroyDisplayLink];
	
	[super dealloc];
}

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (void)setupLayer {
	_eaglLayer = (CAEAGLLayer*) self.layer;
	_eaglLayer.opaque = YES;
}

- (void)setupContext {
	EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
	_context = [[EAGLContext alloc] initWithAPI:api];
	if (!_context) {
		NSLOG(@"{glview} FATAL: Failed to initialize OpenGLES 2.0 context");
		exit(1);
	}
	
	if (![EAGLContext setCurrentContext:_context]) {
		NSLOG(@"{glview} FATAL: Failed to set current OpenGL context");
		exit(1);
	}
}

- (void)setupRenderBuffer {
	GLTRACE(glGenRenderbuffers(1, &_colorRenderBuffer));
	GLTRACE(glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer));
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}


- (void)setupFrameBuffer {
	GLuint framebuffer;
	GLTRACE(glGenFramebuffers(1, &framebuffer));
	GLTRACE(glBindFramebuffer(GL_FRAMEBUFFER, framebuffer));
	GLTRACE(glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer));
}

static CFTimeInterval last_timestamp = 0.0f;


//// Start/Stop Rendering

#include <libkern/OSAtomic.h>

static volatile BOOL m_ogl_en = NO; // OpenGL calls enabled
static volatile BOOL m_ogl_in = NO; // In OpenGL calls right now?

- (void)startRendering {
	m_ogl_en = YES;
	last_timestamp = CFAbsoluteTimeGetCurrent();
}

- (void)stopRendering {
	m_ogl_en = NO;
	
	[cond lock];
	while (m_ogl_in) {
		[cond wait];
	}
	[cond unlock];
}

- (void)render:(CADisplayLink*)displayLink {
	m_ogl_in = YES;
	
	// Compiler memory barrier
	__asm__ volatile("" ::: "memory");
	
	if (m_ogl_en) {
		CFTimeInterval timestamp = CFAbsoluteTimeGetCurrent();
		long dt = (long)(1000 * (timestamp - last_timestamp));
		core_tick(dt);
		
		// Measure time to perform a tick
		// CFTimeInterval after_tick = CFAbsoluteTimeGetCurrent();
		
		last_timestamp = timestamp;
		[_context presentRenderbuffer:GL_RENDERBUFFER];
		
		/*
		 // Limit to 30 FPS
		 int tick_dt = (int)(1000 * (after_tick - timestamp));
		 if (tick_dt < 30) {
		 // Measure time to perform gc
		 CFTimeInterval before_gc = CFAbsoluteTimeGetCurrent();
		 
		 JS_MaybeGC(get_js_context());
		 
		 // Measure time to perform gc
		 CFTimeInterval after_gc = CFAbsoluteTimeGetCurrent();
		 
		 int gc_dt = (int)(1000 * (after_gc - before_gc));
		 
		 if (gc_dt + tick_dt < 30) {
		 int sleep_ms = 30 - (gc_dt + tick_dt);
		 [NSThread sleepForTimeInterval:(sleep_ms / 1000.0)];
		 }
		 }*/
	}
	
	m_ogl_in = NO;
	
	if (!m_ogl_en) {
		[cond lock];
		[cond signal];
		[cond unlock];
	}
}

- (void)setupDisplayLink {
	// Enable multi-touch
	self.multipleTouchEnabled = YES;
	
	displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	displayLink.frameInterval = 1;
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)destroyDisplayLink {
	[self stopRendering];
	
	[displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	[_context release];
	_context = nil;
}


- (id)initWithFrame:(CGRect)frame {
	NSLOG(@"{OpenGL} Init with frame");
	
	self = [super initWithFrame:frame];
	if (self) {
		// Adjust for retina displays
		if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
			[self setContentScaleFactor:[UIScreen mainScreen].scale];
		}
		
		touchData = [[NSMutableArray alloc] init];
		[self setupLayer];
		[self setupContext];
		[self setupRenderBuffer];
		[self setupFrameBuffer];
		
		[self setupDisplayLink];
	}
	return self;
}

-(int) getTouchOffsetX {
	return 0;
}


-(int) getTouchOffsetY {
	return 0;
}


//// Touch subsystem

//#define TOUCH_VERBOSE

#if defined(TOUCH_VERBOSE)
#define TOUCHLOG(fmt, ...) LOG("{touch} " fmt, ##__VA_ARGS__)
#else
#define TOUCHLOG(fmt, ...)
#endif

#include <stdint.h>

typedef struct {
	const UITouch *t;
	int uid;
	CGFloat x, y;
} Touch;

#define TOUCH_DOWN 1
#define TOUCH_MOVE 2
#define TOUCH_UP 3

static int m_next_uid = 0;
static const int TOUCH_SIZE = 32; // pow2
static Touch m_touches[TOUCH_SIZE] = { {0} };
static const int MAX_TOUCHES = 16;
static int m_touches_size = 0;

static uint32_t wangHash(uint32_t a) {
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}

static void on_touch_start(int event_type, UITouch *t, CGFloat x, CGFloat y) {
	uint32_t low = *(uint32_t*)&t;
	uint32_t hash = wangHash(low);
	int key = hash & (TOUCH_SIZE - 1);
	Touch *slot = &m_touches[key];
	
	// If worth scanning for insertion point,
	if (m_touches_size < MAX_TOUCHES) {
		// While the table entries are filled and not the given one,
		while (slot->t && slot->t != t) {
			TOUCHLOG("TS:%d StartingType:%d key:%d", m_touches_size, event_type, key);

			key = (key + 1) & (TOUCH_SIZE - 1);
			slot = &m_touches[key];
		}
	}
	
	// If inserting now,
	if (slot->t != t) {
		// If displacing a slot,
		if (slot->t) {
			TOUCHLOG("TS:%d StartingType:%d key:%d DISPLACING EVENT IN SLOT", m_touches_size, event_type, key);
			
			// Touch up at old location (should never happen)
			timestep_events_push(slot->uid, TOUCH_UP, slot->x, slot->y);
		} else {
			++m_touches_size;
		}
		
		TOUCHLOG("TS:%d StartingType:%d key:%d INSERTING", m_touches_size, event_type, key);
		
		slot->t = t;
		slot->uid = ++m_next_uid;
	} else {
		TOUCHLOG("TS:%d StartingType:%d key:%d UPDATING", m_touches_size, event_type, key);
	}
	
	// Modify
	slot->x = x;
	slot->y = y;
	timestep_events_push(slot->uid, event_type, x, y);
}

static void on_touch_move(int event_type, UITouch *t, CGFloat x, CGFloat y) {
    uint32_t low = *(uint32_t*)&t;
    uint32_t hash = wangHash(low);
    int key = hash & (TOUCH_SIZE - 1);
    int start_key = key;
    Touch *slot = &m_touches[key];
    
    if (slot->t != t) {
        do {
            TOUCHLOG("TS:%d TouchMove:%d key:%d", m_touches_size, event_type, key);
            
            key = (key + 1) & (TOUCH_SIZE - 1);
            slot = &m_touches[key];
        } while (slot->t != t && key != start_key);
    }
    
    // If inserting now,
    if (slot->t != t) {
        // If displacing a slot,
        if (slot->t) {
            TOUCHLOG("TS:%d TouchMove:%d key:%d DISPLACING EVENT IN SLOT", m_touches_size, event_type, key);
            
            // Touch up at old location (should never happen)
            timestep_events_push(slot->uid, TOUCH_UP, slot->x, slot->y);
        } else {
            ++m_touches_size;
        }
        
        TOUCHLOG("TS:%d TouchMove:%d key:%d INSERTING", m_touches_size, event_type, key);
        
        slot->t = t;
        slot->uid = ++m_next_uid;
    } else {
        TOUCHLOG("TS:%d TouchMove:%d key:%d UPDATING", m_touches_size, event_type, key);
    }
    
    // Modify
    slot->x = x;
    slot->y = y;
    timestep_events_push(slot->uid, event_type, x, y);
}

static void on_touch_up(UITouch *t, CGFloat x, CGFloat y) {
	uint32_t low = *(uint32_t*)&t;
	uint32_t hash = wangHash(low);
	int key = hash & (TOUCH_SIZE - 1);
	Touch *slot = &m_touches[key];
	int limit = TOUCH_SIZE;
	
	TOUCHLOG("TS:%d TouchUp key:%d", m_touches_size, key);
	
	// While the table entries are filled and not the given one,
	while (--limit >= 0) {
		if (slot->t == t) {
			TOUCHLOG("TS:%d TouchUp key:%d REMOVING", m_touches_size, key);
			timestep_events_push(slot->uid, TOUCH_UP, x, y);
			--m_touches_size;
			slot->t = 0;
			return;
		}
		
		key = (key + 1) & (TOUCH_SIZE - 1);
		slot = &m_touches[key];
	}
	
	TOUCHLOG("TS:%d TouchUp key:%d ONESHOTWEIRD", m_touches_size, key);
	timestep_events_push(++m_next_uid, TOUCH_UP, x, y);
}


// Handles the start of a touch
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[TextInputManager get] dismissAll];
	
	CGFloat scale = [[UIScreen mainScreen] scale];
	for (UITouch *t in touches) {
		CGPoint loc = [t locationInView:self];
		on_touch_start(TOUCH_DOWN, t, loc.x * scale, loc.y * scale);
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGFloat scale = [[UIScreen mainScreen] scale];
	for (UITouch *t in touches) {
		CGPoint loc = [t locationInView:self];
		on_touch_move(TOUCH_MOVE, t, loc.x * scale, loc.y * scale);
	}
}

// Handles the end of a touch event.
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGFloat scale = [[UIScreen mainScreen] scale];
	for (UITouch *t in touches) {
		CGPoint loc = [t locationInView:self];
		on_touch_up(t, loc.x * scale, loc.y * scale);
	}
}

// Touches cancelled by system event: e.g. phone call
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGFloat scale = [[UIScreen mainScreen] scale];
	for (UITouch *t in touches) {
		CGPoint loc = [t locationInView:self];
		on_touch_up(t, loc.x * scale, loc.y * scale);
	}
}

@end
