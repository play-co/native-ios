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
#include "js/OldDebugAPI.h"


@class js_core;
@class DebugServer;


//// Scripts

@interface DebugFragment : NSObject

@property(nonatomic) int startLine;
@property(nonatomic) int lineCount;
@property(nonatomic, assign) JSScript *fragment;

- (id) init:(JSScript *)fragment startLine:(int)startLine lineCount:(int)lineCount;

@end


@interface DebugScript : NSObject

@property(nonatomic) long index;
@property(nonatomic) long lineCount;
@property(nonatomic, retain) NSString *key;
@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSString *source;
@property(nonatomic, retain) NSMutableArray *fragments; // From live device

- (id) init:(int)index key:(NSString *)key path:(NSString *)path source:(NSString *)source;

- (NSDictionary *) generateScriptInfo:(bool)includeSource;

- (void) addFragment:(JSScript *)fragment startLine:(int)startLine lineCount:(int)lineCount;

- (DebugFragment *) findFragment:(int)line;

@end


@interface DebugScriptCollexion : NSObject

@property(nonatomic, retain) NSMutableArray *scripts;

- (id) init;

- (DebugScript *) setScriptForPath:(NSString *)path source:(NSString *)source;

- (DebugScript *) getScriptForKey:(NSString *)nameKey;
- (DebugScript *) getScriptForId:(int)scriptId;
- (DebugScript *) getScriptForFragment:(JSScript *)fragment;

- (NSArray *) generateScriptsResponseBody:(NSArray *)ids includeSource:(bool)includeSource;

@end


//// Debugger

@interface DebugBreakpoint : NSObject

@property(nonatomic) int number;
@property(nonatomic, retain) DebugScript *script;
@property(nonatomic) int line;
@property(nonatomic) bool enabled;
@property(nonatomic, assign) uint8_t *pc;
@property(nonatomic, retain) DebugFragment *fragment;

- (id) init:(DebugScript *)script line:(int)line number:(int)number;

- (void) toggle:(bool)enabled server:(DebugServer *)server;

@end


@interface DebugBreakpointCollexion : NSObject

@property(nonatomic, retain) NSMutableArray *breakpoints;
@property(nonatomic) int nextNumber;
@property(nonatomic, retain) DebugServer *server;

- (DebugBreakpoint *) addBreakpoint:(DebugScript *)script line:(int)line enabled:(bool)enabled;
- (DebugBreakpoint *) findBreakpoint:(JSScript *)script line:(int)line;
- (void) clearBreakpoints;
- (bool) clearBreakpoint:(int)breakpointId;

@end


//// Debug Server

enum DebugStep {
	STEP_CONTINUE,	// Default
	
	STEP_SUSPEND,	// Suspended execution

	STEP_IN,
	STEP_OUT,
	STEP_OUT_TRACE,
	STEP_NEXT
};


@interface DebugServer : NSObject

@property(nonatomic) bool valid;
@property(nonatomic) CFSocketRef sock;
@property(nonatomic, retain) NSMutableArray *collexion; // of connexions
@property(nonatomic, retain) DebugScriptCollexion *scripts;
@property(nonatomic) CFRunLoopSourceRef runLoopSource;
@property(nonatomic) CFRunLoopRef runLoop;
@property(nonatomic, retain) NSRecursiveLock *lock;
@property(nonatomic) dispatch_group_t dgroup;
@property(nonatomic) dispatch_queue_t dqueue;
@property(nonatomic, retain) DebugBreakpointCollexion *breakpoints;
@property(nonatomic, assign) js_core *js;
@property(nonatomic) bool running;
@property(nonatomic) DebugStep stepMode;
@property(nonatomic) JSScript *stepScript;
@property(nonatomic) int stepLine;
@property(nonatomic, retain) NSMutableArray *evals;
@property(nonatomic) bool hasEvals;
@property(nonatomic) bool ignoreHooks; // Used to avoid recursion during hooks

// These help reduce state changes:
@property(nonatomic) bool throwHookSet;
@property(nonatomic) bool interpHookSet;
@property(nonatomic) bool callHookSet;

@property(nonatomic) int callDepth; // Used to measure how far into a call tree we got

@property(nonatomic) bool pendingDeaths; // Indicates that some connextions are dead and need to be reclaimed

- (id) init:(js_core *)js;

- (void) serverThread:(id)param;

- (void) onLogMessage:(NSString *)msg;

- (void) setInterpHook:(bool)enable;
- (void) setThrowHook:(bool)enable;
- (void) setCallHook:(bool)enable;

// These functions return true to suspend execution until server.running == true, or false to continue
- (bool) onBreakpoint:(JSContext *)cx script:(JSScript *)script line:(int)line;
- (bool) onStep:(JSContext *)cx script:(JSScript *)script line:(int)line;
- (bool) onDebug:(JSContext *)cx script:(JSScript *)script line:(int)line;
- (bool) onThrow:(JSContext *)cx script:(JSScript *)script line:(int)line;
- (bool) onCall:(JSContext *)cx frame:(JSAbstractFramePtr) fp before:(bool)before;

- (void) runQueuedEval:(JSContext *)cx;
- (void) queueEval:(NSString *)expression global:(bool)global disable:(bool)disable conn:(id)conn seqno:(int)seqno;

- (void) broadcast:(const char*)message count:(long)bytes;
- (void) broadcastMessage:(NSString *)msg;
- (void) broadcastEvent:(NSString *)name body:(id)body;

// Walk the collexion of connexions and delete objects that are no longer valid
- (void) reclaimConnexions;

// Assigns a unique identifier and returns it; this should be passed to SpiderMonkey for the script path
- (NSString *) setScriptForPath:(NSString *)path source:(NSString *)source;

- (void) close;

@end
