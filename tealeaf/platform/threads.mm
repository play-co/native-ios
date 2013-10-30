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

#include "core/platform/threads.h"


@class ThreadWrapper;


// Internal type for ThreadsThread
struct ThreadSpec {
	ThreadWrapper *thread;
	ThreadsThreadProc proc;
	void *param;
};


//// ThreadWrapper Object

@interface ThreadWrapper : NSThread

- (id) init:(ThreadSpec *)spec;

@property(nonatomic, assign) ThreadSpec *spec;
@property(nonatomic, assign) bool done;
@property(nonatomic, retain) NSCondition *joinLock;

@end


@implementation ThreadWrapper

- (void) dealloc {
	self.joinLock = nil;

	[super dealloc];
}

- (id) init:(ThreadSpec *)spec {
	if (nil != (self = [super initWithTarget:self selector:@selector(threadMain) object:nil])) {
		self.spec = spec;
		self.joinLock = [[NSCondition alloc] init];
	}

	return self;
}

- (void) threadMain {
	ThreadSpec *spec = self.spec;
	if (spec) {
		//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		spec->proc(spec->param);
/*
		if (pool != nil) {
			[pool drain];
		}*/
	}

	self.done = true;

	// Signal 'done' flag
	[self.joinLock lock];
	[self.joinLock broadcast];
	[self.joinLock unlock];
}

@end


// Start a thread
CEXPORT ThreadsThread threads_create_thread(ThreadsThreadProc proc, void *param) {
	// Generate a thread spec to return
	ThreadSpec *spec = (ThreadSpec *)malloc(sizeof(ThreadSpec));
	spec->proc = proc;
	spec->param = param;

	ThreadWrapper *thread = [ThreadWrapper alloc];
	
	thread = [thread init:spec];

	spec->thread = thread;

	[thread start];

	GC_COMPILER_FENCE;

	// Return spec; now, caller must release it by calling threads_join_thread
	return spec;
}

CEXPORT void threads_join_thread(ThreadsThread *thread) {
	if (thread) {
		ThreadSpec *spec = (ThreadSpec *)*thread;

		if (spec) {
			ThreadWrapper *wrapper = spec->thread;

			// Wait for 'done' flag
			if (!wrapper.done) {
				[wrapper.joinLock lock];
				while (!wrapper.done) {
					[wrapper.joinLock wait];
				}
				[wrapper.joinLock unlock];
			}

			[wrapper release];

			free(spec);

			*thread = THREADS_INVALID_THREAD;
		}
	}
}

