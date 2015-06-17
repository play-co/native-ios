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

#import "DebugServer.h"

#include "js/OldDebugAPI.h"
#include "js/js_core.h"

#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>

@class DebugConnexion; // Forward declaration for DebugMirror

static const unsigned short SERVER_PORT = 9222;


/*
	Collection of scripts.

	This is needed because the SpiderMonkey debug API does not keep track of these for me.
	When a remote debugger connects I need to be able to send it the source code.

	The debug API supports naming each script that gets evaluated, so I generate a unique
	name for each script and then later I can use the name to look up the script in response
	to an event.
 */

@implementation DebugFragment

- (void) dealloc {
	[super dealloc];
}

- (id) init:(JSScript *)fragment startLine:(int)startLine lineCount:(int)lineCount {
	self.startLine = startLine;
	self.lineCount = lineCount;
	self.fragment = fragment;
	
	return self;
}

@end


@implementation DebugScript

- (void) dealloc {
	self.key = nil;
	self.path = nil;
	self.source = nil;
	self.fragments = nil;

	[super dealloc];
}

- (id) init:(int)index key:(NSString *)key path:(NSString *)path source:(NSString *)source {
	self = [super init];
	if (!self) {
		return nil;
	}

	self.index = index;
	self.key = key;
	self.path = path;
	self.source = source;
	self.lineCount = [[source componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
	self.fragments = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

	return self;
}

- (void) addFragment:(JSScript *)fragment startLine:(int)startLine lineCount:(int)lineCount {
	DebugFragment *frag = [[[DebugFragment alloc] init:fragment startLine:startLine lineCount:lineCount] autorelease];

	[self.fragments addObject:frag];
}

- (DebugFragment *) findFragment:(int)line {
	for (unsigned long ii = 0, count = [self.fragments count]; ii < count; ++ii) {
		DebugFragment *fragment = (DebugFragment *)[self.fragments objectAtIndex:ii];

		if (fragment) {
			int endLine = fragment.startLine + fragment.lineCount - 1;

			if (line >= fragment.startLine && line <= endLine) {
				return fragment;
			}
		}
	}

	return nil;
}

- (NSDictionary *) generateScriptInfo:(bool)includeSource {
	unsigned long lineOffset = 1, columnOffset = 1, lineCount = self.lineCount, sourceLength = [self.source length];

	if (includeSource) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInteger:self.index],@"id",
				self.key,@"name",
				self.source,@"source",
				[NSNumber numberWithInteger:sourceLength],@"sourceLength",
				[NSNumber numberWithInteger:lineOffset],@"lineOffset",
				[NSNumber numberWithInteger:columnOffset],@"columnOffset",
				[NSNumber numberWithInteger:lineCount],@"lineCount", nil];
	} else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInteger:self.index],@"id",
				self.key,@"name",
				[NSNumber numberWithInteger:sourceLength],@"sourceLength",
				[NSNumber numberWithInteger:lineOffset],@"lineOffset",
				[NSNumber numberWithInteger:columnOffset],@"columnOffset",
				[NSNumber numberWithInteger:lineCount],@"lineCount", nil];
	}
}

@end


@implementation DebugScriptCollexion

- (void) dealloc {
	self.scripts = nil;

	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	self.scripts = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

	return self;
}

- (DebugScript *) setScriptForPath:(NSString *)path source:(NSString *)source {

	size_t uniqueId = [self.scripts count];

	NSString *uniqueString = [NSString stringWithFormat:@"%@ %zu", path, uniqueId, nil];

	// Make a copy of the source since it may be temporary
	NSString *sourceCopy = [NSString stringWithString:source];
	
	DebugScript *script = [[[DebugScript alloc] init:(int)uniqueId key:uniqueString path:path source:sourceCopy] autorelease];
	
	[self.scripts addObject:script];

	return script;
}

- (NSArray *) generateScriptsResponseBody:(NSArray *)ids includeSource:(bool)includeSource {

	// If no request list,
	if (!ids) {
		// Send all the scripts!
		const size_t count = [self.scripts count];
		NSMutableArray *scripts = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
		
		for (size_t ii = 0; ii < count; ++ii) {
			DebugScript *data = [self.scripts objectAtIndex:ii];
			if (data) {
				[scripts addObject:[data generateScriptInfo:includeSource]];
			}
		}
		
		return scripts;
	} else {
		// Send the requested ones
		const size_t scriptCount = [self.scripts count];
		const size_t requestCount = [ids count];
		NSMutableArray *scripts = [[[NSMutableArray alloc] initWithCapacity:requestCount] autorelease];
		
		for (int ii = 0; ii < requestCount; ++ii) {
			int index = [(NSNumber*)[ids objectAtIndex:ii] intValue];

			if (index >= 0 && index < scriptCount) {
				DebugScript *data = [self.scripts objectAtIndex:index];
				if (data) {
					[scripts addObject:[data generateScriptInfo:includeSource]];
				}
			}
		}

		return scripts;
	}
}

- (DebugScript *) getScriptForKey:(NSString *)nameKey {
	// For each script,
	for (DebugScript *script in self.scripts) {
		if ([script.key caseInsensitiveCompare:nameKey] == NSOrderedSame) {
			return script;
		}
	}

	return nil;
}

- (DebugScript *) getScriptForId:(int)scriptId {
	if (scriptId < 0 || scriptId >= [self.scripts count]) {
		NSLOG(@"{debugger} Script not found for id=%d (out of range)", scriptId);
	} else {
		return (DebugScript *)[self.scripts objectAtIndex:scriptId];
	}

	return nil;
}

- (DebugScript *) getScriptForFragment:(JSScript *)fragment {
	// For each script,
	for (DebugScript *script in self.scripts) {
		for (DebugFragment *frag in script.fragments) {
			if (frag.fragment == fragment) {
				return script;
			}
		}
	}

	return nil;
}

@end


/*
	Track script fragments as they are compiled by SpiderMonkey, activating pending breakpoints.

	As new breakpoints are added, look up the corresponding script fragment and insert it immediately if found.
 */

static JSTrapStatus TrapHandler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, jsval closure) {
	DebugServer *server = (DebugServer *)JSVAL_TO_PRIVATE(closure);

	if (server.ignoreHooks) {
		return JSTRAP_CONTINUE;
	}
	
	server.running = false;
	
	if (server.hasEvals) {
		[server runQueuedEval:cx];
	}

	int line = JS_PCToLineNumber(cx, script, pc);

	// If breakpoint is recognized,
	if ([server onBreakpoint:cx script:script line:line]) {
		// Wait here until the server says we should be running again
		while (!server.running) {
			usleep(100);
			
			if (server.hasEvals) {
				[server runQueuedEval:cx];
			}
		}
	}

	server.running = true;
	
	return JSTRAP_CONTINUE;
}

static JSTrapStatus StepHandler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
	DebugServer *server = (DebugServer *)closure;

	if (server.ignoreHooks) {
		return JSTRAP_CONTINUE;
	}

	server.running = false;

	if (server.hasEvals) {
		[server runQueuedEval:cx];
	}

	int line = JS_PCToLineNumber(cx, script, pc);

	// If breakpoint is recognized,
	if ([server onStep:cx script:script line:line]) {
		// Wait here until the server says we should be running again
		while (!server.running) {
			usleep(100);

			if (server.hasEvals) {
				[server runQueuedEval:cx];
			}
		}
	}

	server.running = true;

	return JSTRAP_CONTINUE;
}

// debugger;
static JSTrapStatus DebuggerHandler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
	DebugServer *server = (DebugServer *)closure;

	if (server.ignoreHooks) {
		return JSTRAP_CONTINUE;
	}

	server.running = false;

	if (server.hasEvals) {
		[server runQueuedEval:cx];
	}

	int line = JS_PCToLineNumber(cx, script, pc);

	// If breakpoint is recognized,
	if ([server onDebug:cx script:script line:line]) {
		// Wait here until the server says we should be running again
		while (!server.running) {
			usleep(100);
			
			if (server.hasEvals) {
				[server runQueuedEval:cx];
			}
		}
	}

	server.running = true;
	
	return JSTRAP_CONTINUE;
}

// Exception handler
static JSTrapStatus ThrowHook(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
	DebugServer *server = (DebugServer *)closure;
	
	if (server.ignoreHooks) {
		return JSTRAP_CONTINUE;
	}
	
	server.running = false;
	
	if (server.hasEvals) {
		[server runQueuedEval:cx];
	}
	
	int line = JS_PCToLineNumber(cx, script, pc);

	// If breakpoint is recognized,
	if ([server onThrow:cx script:script line:line]) {
		// Wait here until the server says we should be running again
		while (!server.running) {
			usleep(100);
			
			if (server.hasEvals) {
				[server runQueuedEval:cx];
			}
		}
	}
	
	server.running = true;
	
	return JSTRAP_CONTINUE;
}

// For profiling: Captures function in-out
static void *CallHook(JSContext *cx, JSAbstractFramePtr fp, bool isConstructing, bool before, bool *ok, void *closure) {
	DebugServer *server = (DebugServer *)closure;

	server.running = false;

	// Allow server to skip suspension
	if ([server onCall:cx frame:fp before:(before == true)]) {
		// Wait here until the server says we should be running again
		while (!server.running) {
			usleep(100);
		}
	}

	server.running = true;

	if (ok) {
		*ok = true;
	}

	return server;
}


@implementation DebugBreakpoint

- (void) dealloc {
	self.script = nil;
	self.fragment = nil;
	
	[super dealloc];
}

- (id) init:(DebugScript *)script line:(int)line number:(int)number {
	self.script = script;
	self.line = line;
	//self.enabled = false;
	self.number = number;

	return self;
}

- (void) toggle:(bool)enabled server:(DebugServer *)server {
	if (enabled != self.enabled) {
		if (enabled) {
			DebugFragment *fragment = [self.script findFragment:self.line];

			if (!fragment) {
				NSLOG(@"{debugger} WARNING: Unable to find compiled script fragment for script:%@ line:%d", self.script.path, self.line);
			} else {
				NSLOG(@"{debugger} Breakpoint set for script:%@ line:%d", self.script.path, self.line);
				
				// NOTE: SpiderMonkey does not support columns for looking up bytecode offsets
				jsbytecode *pc = JS_LineNumberToPC(server.js.cx, fragment.fragment, self.line);

				self.pc = pc;
				self.fragment = fragment;
				
				JS_SetTrap(server.js.cx, fragment.fragment, pc, TrapHandler, PRIVATE_TO_JSVAL(server));

				self.enabled = true;
			}
		} else {
			if (self.enabled)
			{
				JS_ClearTrap(server.js.cx, self.fragment.fragment, (jsbytecode *)self.pc, NULL, NULL);
				self.enabled = false;

				NSLOG(@"{debugger} Breakpoint cleared for script:%@ line:%d", self.script.path, self.line);
			}
			else
			{
				NSLOG(@"{debugger} WARNING: Unset breakpoint clear ignored for script:%@ line:%d", self.script.path, self.line);
			}
		}
	}
}

@end


@implementation DebugBreakpointCollexion

- (void) dealloc {
	self.breakpoints = nil;
	self.server = nil;

	[super dealloc];
}

- (id) init:(DebugServer *)server {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	self.server = server;

	self.breakpoints = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

	return self;
}

- (DebugBreakpoint *) addBreakpoint:(DebugScript *)script line:(int)line enabled:(bool)enabled {
	// Return an existing one if possible
	for (size_t ii = 0, icount = [self.breakpoints count]; ii < icount; ++ii) {
		DebugBreakpoint *bp = [self.breakpoints objectAtIndex:ii];
		
		if (bp && bp.line == line && bp.script == script) {
			if (enabled) {
				[bp toggle:true server:self.server];
			}

			return bp;
		}
	}

	// Create a new one
	int number = self.nextNumber++;
	DebugBreakpoint *bp = [[[DebugBreakpoint alloc] init:script line:line number:number] autorelease];

	[self.breakpoints addObject:bp];

	if (enabled) {
		[bp toggle:true server:self.server];
	}

	return bp;
}

- (DebugBreakpoint *) findBreakpoint:(JSScript *)script line:(int)line {
	for (size_t ii = 0, icount = [self.breakpoints count]; ii < icount; ++ii) {
		DebugBreakpoint *bp = [self.breakpoints objectAtIndex:ii];

		if (bp && bp.line == line) {
			for (size_t jj = 0, jcount = [bp.script.fragments count]; jj < jcount; ++jj) {
				DebugFragment *frag = [bp.script.fragments objectAtIndex:jj];

				if (frag && frag.fragment == script) {
					return bp;
				}
			}
		}
	}

	return nil;
}

- (void) clearBreakpoints {
	// Clear the traps
	for (DebugBreakpoint *bp in self.breakpoints) {
		[bp toggle:false server:self.server];
	}

	// Remove all of the breakpoints
	[self.breakpoints removeAllObjects];
}

- (bool) clearBreakpoint:(int)breakpointId {
	for (DebugBreakpoint *bp in self.breakpoints) {
		if (bp.number == breakpointId) {
			[bp toggle:false server:self.server];

			return true;
		}
	}

	LOG("{debugger} Unable to clear invalid breakpoint id %d", breakpointId);
	return false;
}

@end


// Object database for lookup command
@interface DebugMirror : NSObject

@property(nonatomic) int next_object_id;
@property(nonatomic, retain) NSRecursiveLock *lock;
@property(nonatomic, retain) NSMutableArray *mirror;
@property(nonatomic, assign) DebugConnexion *conn; // Parent object -- Note that it is not retained to avoid circular references!

- (id) init:(DebugConnexion *)conn;
- (NSDictionary *) addObject:(JSObject *)obj context:(JSContext *)cx; // Returns a handle used to reference it
- (NSDictionary *) addObject:(JSObject *)obj obj_handle:(NSNumber *)obj_handle context:(JSContext *)cx cycles:(NSMutableDictionary *)cycles; // Internal
- (void) postHandle:(int)handle seqno:(int)seqno;
- (NSDictionary *) findObject:(int)handle;
- (void) clearObjects;

@end


/*
	This is implementing a V8 debug server emulator for SpiderMonkey so we can use the same web front-end for both.
	iOS allows you to host a TCP server on the device over WiFi, so we'll listen on SERVER_PORT.
	BASIL SERVER will attempt to connect back to the IP address of the last test app connexion from an iOS client.

	Protocol notes:

	All messages obey the same protocol:
	Message headers end in a "\r\n\r\n" delimiter.
	One of the headers should be "Content-Length: X",
	where X is the number of bytes following the delimiter that are part of the message data content.
	Other headers are ignored by the NativeInspector client so don't bother to send them.
	The message data should be a valid JSON object.

	Example: "Content-Length: 11\r\n\r\n{'HELLO':0}"
 */


@interface DebugConnexion : NSObject

@property(nonatomic) bool valid;
@property(nonatomic, assign) DebugServer *server; // Not retained to avoid refcount loop
@property(nonatomic, retain) NSRecursiveLock *lock; // Send buffer lock

@property(nonatomic) CFSocketNativeHandle socketId;
@property(nonatomic) CFReadStreamRef readStream;
@property(nonatomic) CFWriteStreamRef writeStream;

@property(nonatomic) char *buffer_data;
@property(nonatomic) long buffer_len;
@property(nonatomic) size_t buffer_offset;

@property(nonatomic) char *deframe_data;
@property(nonatomic) size_t deframe_len;
@property(nonatomic) size_t deframe_offset;
@property(nonatomic) ssize_t deframe_expected; // 0 = in headers, waiting for \r\n\r\n delimiter, else = data length expected

@property(nonatomic) int outgoing_seq;

@property(nonatomic, retain) DebugMirror *mirror; // Used for lookup command


- (id) initWithSocket:(CFSocketNativeHandle)socketId andServer:(DebugServer *)server;
- (void) write:(const void *)buffer count:(long)bytes;

// Events called from callbacks executing in run loop
- (void) onConnect;
- (void) onReadReady;
- (void) onWriteReady;
- (void) onReadDead;
- (void) onWriteDead;

// Processed events
- (void) onRead:(UInt8 *)buffer count:(CFIndex)count;
- (bool) onMessage:(char *)buffer count:(size_t)count;
- (bool) onMessageObject:(NSDictionary*)object;

- (bool) dequeueWrite; // Returns true if write buffer is empty
- (void) appendWrite:(const void *)data count:(long)bytes;
- (size_t) processRead:(char *)data count:(size_t)bytes; // Returns number of bytes consumed

- (void) postMessage:(NSString *)msg;
- (void) postConnect;
// TODO: not implemented? removing to avoid warning:
// - (void) postObject:(NSDictionary *)object;

- (void) postResponse:(int)requestSeq success:(bool)success;
- (void) postResponse:(int)requestSeq success:(bool)success body:(id)body refs:(id)refs; // Body and Refs are optional (pass nil to disable)

- (void) backtrace:(int)requestSeq;
- (void) listbreakpoints:(int)requestSeq;

- (void) close;

@end


@implementation DebugConnexion

@synthesize readStream = _readStream;
@synthesize writeStream = _writeStream;

static void OnReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
	DebugConnexion *conn = (DebugConnexion *)clientCallBackInfo;

	if (conn && conn.valid) {
		switch (eventType) {
			case kCFStreamEventHasBytesAvailable:
				[conn onReadReady];
				break;
			case kCFStreamEventErrorOccurred:
			case kCFStreamEventEndEncountered:
				[conn onReadDead];
				break;
		}
	}
}

static void OnWriteStreamClientCallBack(CFWriteStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
	DebugConnexion *conn = (DebugConnexion *)clientCallBackInfo;

	if (conn && conn.valid) {
		switch (eventType) {
			case kCFStreamEventOpenCompleted:
				[conn onConnect];
				break;
			case kCFStreamEventCanAcceptBytes:
				[conn onWriteReady];
				break;
			case kCFStreamEventErrorOccurred:
			case kCFStreamEventEndEncountered:
				[conn onWriteDead];
				break;
		}
	}
}

- (void) dealloc {
	[self close];

	self.mirror = nil;
	self.lock = nil;
	
	[super dealloc];
}

- (id) initWithSocket:(CFSocketNativeHandle)socketId andServer:(DebugServer *)server {
	if ((self = [super init])) {
		self.valid = true;
		self.socketId = socketId;
		self.server = server;
		self.lock = [[[NSRecursiveLock alloc] init] autorelease];
		self.mirror = [[[DebugMirror alloc] init:self] autorelease];

		CFStreamCreatePairWithSocket(kCFAllocatorDefault, socketId, &_readStream, &_writeStream);

		if (!self.readStream || !self.writeStream) {
			LOG("{debugger} WARNING: Unable to create stream pair from new connexion");
		} else {
			CFStreamClientContext readCtx = {
				0, self, NULL, NULL, NULL
			};

			if (!CFReadStreamSetClient(self.readStream, kCFStreamEventOpenCompleted |
									   kCFStreamEventHasBytesAvailable |
									   kCFStreamEventEndEncountered |
									   kCFStreamEventErrorOccurred,
									   OnReadStreamClientCallBack, &readCtx)) {
				LOG("{debugger} WARNING: Unable to set read stream client");
			} else {
				CFStreamClientContext writeCtx = {
					0, self, NULL, NULL, NULL
				};

				if (!CFWriteStreamSetClient(self.writeStream, kCFStreamEventOpenCompleted |
										   kCFStreamEventCanAcceptBytes |
										   kCFStreamEventEndEncountered |
										   kCFStreamEventErrorOccurred,
										   OnWriteStreamClientCallBack, &writeCtx)) {
					LOG("{debugger} WARNING: Unable to set write stream client");
				} else {
					CFReadStreamScheduleWithRunLoop(self.readStream, server.runLoop, kCFRunLoopCommonModes);
					CFWriteStreamScheduleWithRunLoop(self.writeStream, server.runLoop, kCFRunLoopCommonModes);

					if (!CFReadStreamOpen(self.readStream) || !CFWriteStreamOpen(self.writeStream)) {
						LOG("{debugger} WARNING: Unable to open stream pair from new connexion");
					} else {
						LOG("{debugger} Created connexion %d", self.socketId);
						return self;
					}
				}
			}
		}
	}

	[self release];
	return nil;
}

- (void) onConnect {
	LOG("{debugger} Connexion established");

	[self postConnect];
}

- (void) onReadReady {
	UInt8 buffer[1024];

	for (;;) {
		CFIndex count = 0;
		if (self.readStream) {
			[self.lock lock];
			if (CFReadStreamHasBytesAvailable(self.readStream)) {
				count = CFReadStreamRead(self.readStream, buffer, sizeof(buffer));
			}
			[self.lock unlock];
		}

		if (count <= 0) {
			if (count < 0) {
				[self onReadDead];
			}

			break;
		} else {
			[self onRead:buffer count:count];

			// If no longer valid,
			if (!self.valid) {
				break;
			}
		}
	}
}

- (void) onWriteReady {
	[self.lock lock];
	[self dequeueWrite];
	[self.lock unlock];
}

- (void) onReadDead {
	LOG("{debugger} Read pipe broke");
	[self close];
}

- (void) onWriteDead {
	LOG("{debugger} Write pipe broke");
	[self close];
}

- (void) onRead:(UInt8 *)buffer count:(CFIndex)count {
	if (count > 0) {
		if (self.deframe_data) {
			// Combine immediately into existing data, since existing data is always incomplete
			size_t remainder = self.deframe_len - self.deframe_offset;
			size_t new_size = remainder + count;
			char *new_data = (char*)malloc(new_size);
			memcpy(new_data, self.deframe_data + self.deframe_offset, remainder);
			memcpy(new_data + remainder, buffer, count);

			size_t consumed = [self processRead:new_data count:new_size];

			// Update buffer with what is left over
			free(self.deframe_data);
			if (consumed >= new_size) {
				free(new_data);
				self.deframe_data = NULL;
			} else {
				self.deframe_data = new_data;
				self.deframe_len = new_size;
				self.deframe_offset = consumed;
			}
		} else {
			size_t consumed = [self processRead:(char*)buffer count:count];
			size_t remainder = count - consumed;

			if (remainder > 0) {
				// Make a copy
				self.deframe_data = (char*)malloc(remainder);
				memcpy(self.deframe_data, buffer + consumed, remainder);
				self.deframe_len = remainder;
				self.deframe_offset = 0;
			}
		}
	}
}

- (size_t) processRead:(char *)data count:(size_t)bytes {
	size_t original_bytes = bytes;

	for (;;) {
    if (!bytes) { break; }
		if (self.deframe_expected == 0) {
			bool found = false;

			// Looking for \r\n\r\n
			for (size_t ii = 0, last = bytes - 4; ii <= last; ++ii) {
				// If delimiter was found,
				if (data[ii] == '\r' && data[ii+1] == '\n' && data[ii+2] == '\r' && data[ii+3] == '\n') {
					// Process out the headers: Looking for "Content-Length: x\r\n"

					// NOTE: strstr() expects a nul-terminated string
					data[ii] = '\0';

					char *token = strstr(data, "Content-Length:");
					if (token) {
						char *lenstr = token + 15;
						
						// NOTE: atoi skips leading spaces and will stop at the first non-numeric character
						self.deframe_expected = atoi(lenstr);
						
						// If expected is invalid,
						if (self.deframe_expected < 0) {
							LOG("{debugger} WARNING: Frame content length < 0");
							self.deframe_expected = 0;
						}
					}

					// Eat the headers
					ii += 4;
					data += ii;
					bytes -= ii;

					// Stop looking after the first one
					found = true;
					break;
				}
			}

			if (!found) {
				break;
			}
		} else {
			// Waiting for expected data
			if (bytes >= self.deframe_expected) {
				// Got it!
				if (![self onMessage:data count:self.deframe_expected]) {
					// Set bytes to zero here so that the return value will indicate consuming
					// the entire buffer, preventing bad state problems if we did [self close]
					// in response to a message like 'disconnect'
					bytes = 0;
					break;
				}
				
				// Eat the data
				data += self.deframe_expected;
				bytes -= self.deframe_expected;
				
				// Switch back to waiting for headers
				self.deframe_expected = 0;
			} else {
				// Truncated.  Stop here..
				break;
			}
		}
	}

	return original_bytes - bytes;
}

- (bool) onMessage:(char *)buffer count:(size_t)count {
    
    NSError *err;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[NSString
                                                                   stringWithCString:buffer
                                                                   encoding:NSUTF8StringEncoding]
                                                                  dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&err];
    
	bool rval = true;
	if (!dict) {
		NSLOG(@"{debugger} Invalid JSON formatting: %@ (bytes:%d)", err, count);
	} else {
		rval = [self onMessageObject:dict];
	}

	return rval;
}

- (bool) onMessageObject:(NSDictionary*)object {
	bool rval = true;

	id itype = [object valueForKey:@"type"];
	id iseq = [object valueForKey:@"seq"];
	id icmd = [object valueForKey:@"command"];
	id iargs = [object valueForKey:@"arguments"];

	if (itype && [itype isKindOfClass:[NSString class]] &&
		iseq && [iseq isKindOfClass:[NSNumber class]] &&
		icmd && [icmd isKindOfClass:[NSString class]]) {

		NSString *type = itype, *command = icmd;
		NSNumber *seq = iseq;
		NSDictionary *args = nil;
		if (iargs && [iargs isKindOfClass:[NSDictionary class]]) {
			args = iargs;
		}

		int seq_no = [seq intValue];

		if ([type caseInsensitiveCompare:@"request"] == NSOrderedSame) {
			if ([command caseInsensitiveCompare:@"version"] == NSOrderedSame) {
				[self postResponse:seq_no success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
															 @"version",@"type",
															 kCFBooleanTrue,@"ios",
															 [NSString stringWithFormat:@"SpiderMonkey %s",JS_GetImplementationVersion()],@"V8Version", nil] refs:nil ];
			} else if ([command caseInsensitiveCompare:@"setbreakpoint"] == NSOrderedSame) {
				DebugBreakpoint *bp = nil;

				if (args) {
					id itarget = [args valueForKey:@"target"];
					id iline = [args valueForKey:@"line"];
					id icolumn = [args valueForKey:@"column"];
					int target = -1, line = -1, column = -1;

					DebugScript *script = nil;

					if (itarget) {
						if ([itarget isKindOfClass:[NSString class]]) {
							NSString *url = (NSString *)itarget;

							script = [self.server.scripts getScriptForKey:url];
						} else if ([itarget isKindOfClass:[NSNumber class]]) {
							target = [(NSNumber *)itarget intValue];

							if (target >= 0) {
								script = [self.server.scripts getScriptForId:target];
							}
						}
					}
					
					if (iline) {
						if ([iline isKindOfClass:[NSString class]]) {
							line = [(NSString *)iline intValue];
						} else if ([iline isKindOfClass:[NSNumber class]]) {
							line = [(NSNumber *)iline intValue];
						}
					}

					if (icolumn) {
						if ([icolumn isKindOfClass:[NSString class]]) {
							column = [(NSString *)icolumn intValue];
						} else if ([icolumn isKindOfClass:[NSNumber class]]) {
							column = [(NSNumber *)icolumn intValue];
						}
					}

					if (line >= 0 && column >= 0) {
						id ienabled = [args valueForKey:@"enabled"];
						bool enabled = (CFBooleanRef)ienabled == kCFBooleanTrue;

						if (script) {
							bp = [self.server.breakpoints addBreakpoint:script line:line enabled:enabled];
						}
					}
				}

				if (bp) {
          int line = bp.line, column = 1;
          long scriptId = bp.script.index;

					[self postResponse:seq_no success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"breakpoint",@"type",
																 [NSNumber numberWithInt:bp.number],@"breakpoint",
																 [NSArray arrayWithObject:
																  [NSDictionary dictionaryWithObjectsAndKeys:
																   [NSNumber numberWithInt:line],@"line",
																   [NSNumber numberWithInt:column],@"column",
																   [NSNumber numberWithLong:scriptId],@"script_id", nil]
																  ],@"actual_locations", nil] refs:nil ];
				} else {
					[self postResponse:seq_no success:false];
				}
			} else if ([command caseInsensitiveCompare:@"continue"] == NSOrderedSame) {
				if (args) {
					id istepaction = [args valueForKey:@"stepaction"];
/*					id istepcount = [args valueForKey:@"stepcount"];
					TODO: Do something with step count
					int stepcount = 1;

					if (istepcount) {
						if ([istepcount isKindOfClass:[NSString class]]) {
							stepcount = [(NSString *)istepcount intValue];
						} else if ([istepcount isKindOfClass:[NSNumber class]]) {
							stepcount = [(NSNumber *)istepcount intValue];
						}
					}
*/
					if ([istepaction isKindOfClass:[NSString class]]) {
						NSString *stepaction = (NSString *)istepaction;

						if ([stepaction caseInsensitiveCompare:@"in"] == NSOrderedSame) {
							// Step in
							self.server.stepMode = STEP_IN;
						} else if ([stepaction caseInsensitiveCompare:@"next"] == NSOrderedSame) {
							// Next
							self.server.stepMode = STEP_NEXT;
						} else if ([stepaction caseInsensitiveCompare:@"out"] == NSOrderedSame) {
							// Step out
							self.server.stepMode = STEP_OUT;
						}

						[self.server setInterpHook:true];
					}
				}

				if (self.server.stepMode == STEP_SUSPEND)
				{
					// Break out of the stepping
					self.server.stepMode = STEP_CONTINUE;
				}

				// Resume the VM if it was paused on a breakpoint
				self.server.running = true;
			} else if ([command caseInsensitiveCompare:@"backtrace"] == NSOrderedSame) {
				if (self.server.running) {
					[self postResponse:seq_no success:false];
				} else {
					[self backtrace:seq_no];
				}
			} else if ([command caseInsensitiveCompare:@"suspend"] == NSOrderedSame) {
				// Enter suspended execution
				self.server.stepMode = STEP_SUSPEND;
				[self.server setInterpHook:true];
			} else if ([command caseInsensitiveCompare:@"clearbreakpoint"] == NSOrderedSame) {
				int breakpointId = -1;

				// Parse out breakpoint id parameter
				if (args) {
					id ibpid = [args valueForKey:@"breakpoint"];
					
					if (ibpid) {
						if ([ibpid isKindOfClass:[NSString class]]) {
							breakpointId = [(NSString*)ibpid intValue];
						} else if ([ibpid isKindOfClass:[NSNumber class]]) {
							breakpointId = [(NSNumber*)ibpid intValue];
						}
					}
				}

				[self postResponse:seq_no success:[self.server.breakpoints clearBreakpoint:breakpointId]];
			} else if ([command caseInsensitiveCompare:@"setexceptionbreak"] == NSOrderedSame) {
				// Parse out breakpoint id parameter
				if (args) {
					id ienabled = [args valueForKey:@"enabled"];
					int enabled = 0;

					if (ienabled) {
						if ([ienabled isKindOfClass:[NSString class]]) {
							enabled = [(NSString*)ienabled intValue];
						} else if ([ienabled isKindOfClass:[NSNumber class]]) {
							enabled = [(NSNumber*)ienabled intValue];
						}
					}
/*					TODO: Do something with the type
					id itype = [args valueForKey:@"type"];
					NSString *type = @"none";

					if (itype) {
						if ([itype isKindOfClass:[NSString class]]) {
							type = (NSString*)itype;
						}
					}
*/
					// TODO: How to handle ONLY uncaught exceptions?
					
					[self.server setThrowHook:(enabled != 0)];

					[self postResponse:seq_no success:true];
				}
			} else if ([command caseInsensitiveCompare:@"disconnect"] == NSOrderedSame) {
				// Close the socket and return false to unwind gracefully
				[self close];
				rval = false;
			} else if ([command caseInsensitiveCompare:@"listbreakpoints"] == NSOrderedSame) {
				[self listbreakpoints:seq_no];
			} else if ([command caseInsensitiveCompare:@"scripts"] == NSOrderedSame) {
				bool includeSource = false;
				NSArray *ids = nil;

				if (args) {
					id iids = [args valueForKey:@"ids"];
					if (iids && [iids isKindOfClass:[NSArray class]]) {
						ids = (NSArray*)iids;
						size_t count = [ids count];
						NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];

						// Scrub input
						for (int ii = 0; ii < count; ++ii) {
							id inum = [ids objectAtIndex:ii];
							NSNumber *num = (NSNumber*)inum;

							if (!inum) {
								num = [NSNumber numberWithInt:-1];
							} else if ([inum isKindOfClass:[NSString class]]) {
								num = [NSNumber numberWithInt:[(NSString*)inum intValue]];
							} else if ([inum isKindOfClass:[NSNumber class]]) {
								num = (NSNumber*)inum;
							} else {
								num = [NSNumber numberWithInt:-1];
							}

							[temp setObject:num atIndexedSubscript:ii];
						}

						ids = temp;
					}

					id iincludeSource = [args valueForKey:@"includeSource"];
					includeSource = (CFBooleanRef)iincludeSource == kCFBooleanTrue;
				}

				[self.server.lock lock];
				id body = [self.server.scripts generateScriptsResponseBody:ids includeSource:includeSource];
				[self.server.lock unlock];
				
				[self postResponse:seq_no success:true body:body refs:nil];
			} else if ([command caseInsensitiveCompare:@"lookup"] == NSOrderedSame) {
				if (args) {
					id ihandles = [args valueForKey:@"handles"];

					if (ihandles && [ihandles isKindOfClass:[NSArray class]]) {
						NSArray *handles = (NSArray *)ihandles;

						// TODO: I only see how to return one object at a time, so ignoring other array elements for now.

						if ([handles count] >= 1) {
							id inum = [handles objectAtIndex:0];
							
							if (inum && [inum isKindOfClass:[NSNumber class]]) {
								int handle = [(NSNumber *)inum intValue];

								[self.mirror postHandle:handle seqno:seq_no];
							}
						}
					}
				}
			} else if ([command caseInsensitiveCompare:@"evaluate"] == NSOrderedSame) {
				if (args) {
					id iexpression = [args valueForKey:@"expression"];
					id iglobal = [args valueForKey:@"global"];
					id idisable = [args valueForKey:@"disable_break"];

					if (iexpression && [iexpression isKindOfClass:[NSString class]]) {
						NSString *expression = iexpression;
						// Ignore max string length..

						bool global = (CFBooleanRef)iglobal == kCFBooleanTrue;
						bool disable = (CFBooleanRef)idisable == kCFBooleanTrue;
						
						// Queue up an evaluation next time the JS engine is halted
						[self.server queueEval:expression global:global disable:disable conn:self seqno:seq_no];
						[self.server setInterpHook:true];
					}
				}
			} else {
				NSLOG(@"{debugger} WARNING: Unrecognized request: %@", [object debugDescription]);
			}
		}
	} else {
		NSLOG(@"{debugger} WARNING: Missing field for received object: %@", [object debugDescription]);
	}

	return rval;
}

- (bool) dequeueWrite {
	if (self.writeStream && self.buffer_data) {
		while (CFWriteStreamCanAcceptBytes(self.writeStream)) {
			ssize_t remaining = self.buffer_len - self.buffer_offset;
			
			ssize_t written = CFWriteStreamWrite(self.writeStream, (const UInt8 *)self.buffer_data + self.buffer_offset, remaining);
			
			if (written <= 0) {
				if (written < 0) {
					[self onWriteDead];
				}

				return false;
			} else {
				self.buffer_offset += written;
				
				// If the entire buffer was written,
				if (written >= remaining) {
					free(self.buffer_data);
					self.buffer_data = NULL;

					break;
				}
			}
		}
	}

	return true;
}

- (void) appendWrite:(const void *)data count:(long)bytes {
	if (!self.buffer_data) {
		// Just copy buffer
		self.buffer_data = (char*)malloc(bytes);
		if (!self.buffer_data || bytes < 0) {
			LOG("{debugger} ERROR: Lost data. Unable to copy write buffer with %d bytes", bytes);
		} else {
			self.buffer_len = bytes;
			self.buffer_offset = 0;
			memcpy(self.buffer_data, data, bytes);
		}
	} else {
		long remaining = self.buffer_len - self.buffer_offset;
		long new_size = remaining + bytes;

		char *new_buffer = (char*)malloc(new_size);
		if (!new_buffer || new_size < 0) {
			LOG("{debugger} ERROR: Lost data. Unable to append to write buffer old=%d+%d new=%d bytes", self.buffer_len, self.buffer_offset, bytes);
		} else {
			memcpy(new_buffer, self.buffer_data + self.buffer_offset, remaining);
			memcpy(new_buffer + remaining, data, bytes);

			free(self.buffer_data);

			self.buffer_data = new_buffer;
			self.buffer_offset = 0;
			self.buffer_len = new_size;
		}
	}
}

- (void) write:(const void *)buffer count:(long)bytes {
	[self.lock lock];

	// If write buffer is clean,
	if (self.writeStream && [self dequeueWrite]) {
		// If we can write immediately,
		if (CFWriteStreamCanAcceptBytes(self.writeStream) && bytes > 0) {
			// Try it
			CFIndex written = CFWriteStreamWrite(self.writeStream, (const UInt8 *)buffer, bytes);
		
			if (written < 0) {
				[self onWriteDead];

				[self.lock unlock];
				return;
			} else if (written > 0) {
				// Needed to buffer some of the bytes: Eat the sent bytes
				buffer = (char*)buffer + written;
				bytes -= written;
			}
		}
	}

	// If not all the bytes were sent,
	if (bytes > 0) {
		// Append to write buffer
		[self appendWrite:buffer count:bytes];
	}

	[self.lock unlock];
}

- (void) postMessage:(NSString *)msg {
	NSString *frame = [NSString stringWithFormat:@"Content-Length: %ld\r\n\r\n%@",
                       (unsigned long)[msg length], msg];

	[self write:[frame UTF8String] count:[frame length]];
}

- (void) postConnect {
	// Note that this leaves out a lot of fields that V8 normally sends
	NSString *frame = [NSString stringWithFormat:@"Type: connect\r\nContent-Length: 0\r\n\r\n"];

	[self write:[frame UTF8String] count:[frame length]];
}

- (void) postResponse:(int)requestSeq success:(bool)success {
	[self postResponse:requestSeq success:success body:nil refs:nil];
}

- (void) postResponse:(int)requestSeq success:(bool)success body:(id)body refs:(id)refs {
	NSMutableDictionary *msg = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								@"response",@"type",
								[NSNumber numberWithInteger:requestSeq],@"request_seq",
								[NSNumber numberWithInteger:self.outgoing_seq++],@"seq",
								self.server.running ? kCFBooleanTrue : kCFBooleanFalse,@"running",
								success ? kCFBooleanTrue : kCFBooleanFalse,@"success", nil];

	if (body) {
		[msg setObject:body forKey:@"body"];
	}

	if (refs) {
		[msg setObject:refs forKey:@"refs"];
	}

	NSError *err;
  NSString *str = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:msg options:0 error:&err] encoding:NSUTF8StringEncoding];
	
	if (!str) {
		NSLOG(@"{debugger} WARNING: Unable to post response for object: %@. Error: %@", [msg debugDescription], err);
	} else {
		[self postMessage:str];
	}
}

- (void) postEvent:(NSString *)name body:(id)body {
	NSMutableDictionary *msg = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								@"event",@"type",
								name,@"event",
								[NSNumber numberWithInteger:self.outgoing_seq++],@"seq", nil];

	if (body) {
		[msg setObject:body forKey:@"body"];
	}

	NSError *err;
	NSString *str = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:msg options:0 error:&err] encoding:NSUTF8StringEncoding];
	
	if (!str) {
		NSLOG(@"{debugger} WARNING: Unable to post event for object: %@. Error: %@", [msg debugDescription], err);
	} else {
		[self postMessage:str];
	}
}

- (void) listbreakpoints:(int)requestSeq {
	NSMutableArray *breakpoints = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

	// For each connexion,
	for (DebugBreakpoint *bp in self.server.breakpoints.breakpoints) {
		int breakpointId = bp.number;

		[breakpoints addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"breakpoint",@"type",
						   [NSNumber numberWithInt:breakpointId],@"number", nil]];
	}

	[self postResponse:requestSeq success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
													 @"breakpoints",@"type",
													 breakpoints,@"breakpoints", nil] refs:nil ];
}

- (void) backtrace:(int)requestSeq {
	JS_BeginRequest(self.server.js.cx);

	JS::StackDescription *stack = JS::DescribeStack(self.server.js.cx, 16);

	NSMutableArray *frames = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

	for (int ii = 0, count = stack->nframes; ii < count; ++ii) {
		JS::FrameDescription *frame = &stack->frames[ii];

		int column = 1, line = frame->lineno;
		long scriptId = -1;
		NSString *inferredName = @"global";

		// Attempt to fill in the script id
		DebugScript *script = [self.server.scripts getScriptForFragment:frame->script];
		if (script) {
			scriptId = script.index;
		}

		// If frame function is not global,
		if (frame->fun) {
			JSString *functionName = JS_GetFunctionDisplayId(frame->fun);
			if (functionName) {
				JSTR_TO_NSTR(self.server.js.cx, functionName, temp);
				inferredName = temp;
			} else {
				JSString *functionId = JS_GetFunctionId(frame->fun);
				if (functionId) {
					JSTR_TO_NSTR(self.server.js.cx, functionId, temp);
					inferredName = temp;
				}
			}
		}

		[frames addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"frame",@"type",
						   [NSNumber numberWithInt:column],@"column",
						   [NSNumber numberWithInt:line],@"line",
						   [NSArray arrayWithObjects:nil],@"scopes",
						   [NSDictionary dictionaryWithObjectsAndKeys:
							@"function",@"type",
							[NSNumber numberWithLong:scriptId],@"scriptId",
							inferredName,@"inferredName", nil],@"func", nil]];
	}

	JS_EndRequest(self.server.js.cx);

	[self postResponse:requestSeq success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
													 @"frames",@"type",
													 frames,@"frames", nil] refs:nil ];
}

- (void) close {
	[self.lock lock];

	self.valid = false;

	// Reset write buffer
	if (self.buffer_data) {
		free(self.buffer_data);
		self.buffer_data = NULL;
	}
	self.buffer_len = 0;
	self.buffer_offset = 0;
	
	// Reset deframe buffer
	if (self.deframe_data) {
		free(self.deframe_data);
		self.deframe_data = NULL;
	}
	self.deframe_len = 0;
	self.deframe_offset = 0;
	self.deframe_expected = 0;

	if (self.readStream) {
		CFReadStreamSetClient(self.readStream, 0, NULL, NULL);
		CFReadStreamUnscheduleFromRunLoop(self.readStream, self.server.runLoop, kCFRunLoopCommonModes);
		CFReadStreamClose(self.readStream);
		CFRelease(self.readStream);
		self.readStream = NULL;
	}

	if (self.writeStream) {
		CFWriteStreamSetClient(self.writeStream, 0, NULL, NULL);
		CFWriteStreamUnscheduleFromRunLoop(self.writeStream, self.server.runLoop, kCFRunLoopCommonModes);
		CFWriteStreamClose(self.writeStream);
		CFRelease(self.writeStream);
		self.writeStream = NULL;
	}

	if (self.socketId != -1) {
		LOG("{debugger} Closing connexion %d", self.socketId);

		close(self.socketId);
		self.socketId = -1;
	}

	// NOTE: Cannot remove from server here because server
	// broadcast -> write -> write fail -> close path can happen,
	// which would cause the enumeration of connexions by the server
	// for broadcast to become invalid and crash the server.

	// Let the server know there is an invalid connexion in its list to reclaim
	self.server.pendingDeaths = true;

	[self.lock unlock];
}

@end


@implementation DebugMirror

- (void) dealloc {
	self.mirror = nil;
	self.lock = nil;

	// self.conn is not retained

	[super dealloc];
}

- (id) init:(DebugConnexion *)conn {
	if ((self = [super init])) {
		self.conn = conn;

		self.mirror = [NSMutableArray arrayWithCapacity:0];
		self.lock = [[[NSRecursiveLock alloc] init] autorelease];
		self.next_object_id = 1;
	}

	return self;
}

- (void) clearObjects {
	[self.lock lock];

	[self.mirror removeAllObjects];

	[self.lock unlock];
}

static NSDictionary *findInArray(NSArray *list, int handle) {
	for (size_t ii = 0, count = [list count]; ii < count; ++ii) {
		NSDictionary *dict = [list objectAtIndex:ii];

		if ([(NSNumber*)[dict objectForKey:@"handle"] intValue] == handle) {
			return dict;
		}
	}
	
	return nil;
}

- (NSDictionary *) findObject:(int)handle {
	return findInArray(self.mirror, handle);
}

- (NSDictionary *) addObject:(JSObject *)obj obj_handle:(NSNumber *)obj_handle context:(JSContext *)cx cycles:(NSMutableDictionary *)cycles {
	// Enumerate all the properties of the object
	JSIdArray *idArray = JS_Enumerate(cx, obj);
	const int count = JS_IdArrayLength(cx, idArray);
	NSMutableArray *props = [NSMutableArray arrayWithCapacity:count];

	// Create an mirror entry for this object, but leave the properties off until the end
	NSDictionary *obj_dict = [NSDictionary dictionaryWithObjectsAndKeys:@"object",@"type", obj_handle,@"handle", props,@"properties", nil];
	[self.mirror addObject:obj_dict];
	
	// Mark the object as having been seen to avoid cycles
	[cycles setObject:obj_dict forKey:[NSValue valueWithPointer:obj]];

	// For each object property,
	for (int ii = 0; ii < count; ++ii) {
		jsid jid = JS_IdArrayGet(cx, idArray, ii);
    jsval _idval;
    JS::RootedValue propval(cx);

		JS_IdToValue(cx, jid, &_idval);
		JS_LookupPropertyById(cx, obj, jid, &propval);

    JS::RootedValue idval(cx, _idval);
    
		// Create a new unique handle
		NSNumber *handle = [NSNumber numberWithInt:(self.next_object_id++)];

		id key = nil;

		// Grab the key
		if (JSVAL_IS_STRING(idval)) {
			JSVAL_TO_NSTR(cx, idval, tempid);
			key = [NSString stringWithString:tempid];
		} else if (JSVAL_IS_NUMBER(idval)) {
			int n = (int)JSVAL_TO_INT(idval);
			key = [NSNumber numberWithInt:n];
		}

		if (key) {
			// Based on the type of the property,
			if (JSVAL_IS_NUMBER(propval)) {
				int n = (int)JSVAL_TO_INT(propval);

				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", [NSNumber numberWithInt:n],@"value", @"number",@"type", nil]];
			} else if (JSVAL_IS_BOOLEAN(propval)) {
				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", (JSVAL_TO_BOOLEAN(propval) ? kCFBooleanTrue : kCFBooleanFalse), @"value", @"boolean",@"type", nil]];
			} else if (JSVAL_IS_STRING(propval)) {
				JSVAL_TO_NSTR(cx, propval, tempprop);
				NSString *nsprop = [NSString stringWithString:tempprop];

				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", nsprop,@"value", @"string",@"type", nil]];
			} else if (!JSVAL_IS_PRIMITIVE(propval)) {
				JSObject *sub_obj = JSVAL_TO_OBJECT(propval);

				NSDictionary *existing = [cycles objectForKey:[NSValue valueWithPointer:sub_obj]];
				
				if (!existing) {
					[self addObject:sub_obj obj_handle:handle context:cx cycles:cycles];
				} else {
					handle = (NSNumber *)[existing objectForKey:@"handle"];
				}
			} else if (JSVAL_IS_VOID(propval)) {
				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", nil,@"value", @"object",@"type", nil]];
			} else if (JSVAL_IS_NULL(propval)) {
				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", [NSNull null],@"value", @"null",@"type", nil]];
			} else {
				[self.mirror addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"handle", @"(unhandled type)",@"value", @"string",@"type", nil]];
			}

			[props addObject:[NSDictionary dictionaryWithObjectsAndKeys:handle,@"ref", key,@"name", nil]];
		}
	}

	JS_DestroyIdArray(cx, idArray);

	return obj_dict;
}

- (NSDictionary *) addObject:(JSObject *)obj context:(JSContext *)cx {
	/*
	 Object serialization format:
	 {
		refs: [
			{
				handle: 1
				value: "value"
			}
		],
		body: {
			properties: [
				{
					name: "name"
					ref: 1
				}
			]
		}
	 }
	 */

	NSMutableDictionary *cycles = [NSMutableDictionary dictionaryWithCapacity:0];

	[self.lock lock];
	
	NSNumber *handle = [NSNumber numberWithInt:(self.next_object_id++)];
	NSDictionary *dict = [self addObject:obj obj_handle:handle context:cx cycles:cycles];

	[self.lock unlock];

	return dict;
}

- (void) postHandle:(int)handle seqno:(int)seqno {

	bool success = true;
	NSMutableArray *refs = nil;
	
	[self.lock lock];

	NSDictionary *obj = [self findObject:handle];

	if (!obj) {
		success = false;
	} else {
		refs = [NSMutableArray arrayWithCapacity:0];

		NSArray *props = (NSArray *)[obj objectForKey:@"properties"];
		if (props) {
			for (size_t jj = 0, prop_count = [props count]; jj < prop_count; ++jj) {
				int sub_handle = [(NSNumber*)[(NSDictionary *)[props objectAtIndex:jj] objectForKey:@"ref"] intValue];

				// If not already in the refs array,
				if (!findInArray(refs, sub_handle)) {
					NSDictionary *sub_dict = [self findObject:sub_handle];
					if (sub_dict) {
						[refs addObject:sub_dict];
					} else {
						LOG("{debugger} WARNING: Unable to find reference in mirror. This kills the UI");
						success = false;
						break;
					}
				}
			}
		}
	}

	if (success) {
		NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
							  obj,[NSString stringWithFormat:@"%d", handle, nil], nil];

		[self.conn postResponse:seqno success:true body:body refs:refs];
	} else {
		[self.conn postResponse:seqno success:false];
	}

	[self.lock unlock];
}

@end


// An element of the evals list on the server object
@interface DebugEval : NSObject

@property(nonatomic, retain) NSString *expression;
@property(nonatomic) bool global;
@property(nonatomic) bool disable;
@property(nonatomic, retain) DebugConnexion *conn;
@property(nonatomic) int seqno;

- (id) init:(NSString *)expression global:(bool)global disable:(bool)disable conn:(id)conn seqno:(int)seqno;

@end

@implementation DebugEval

- (void) dealloc {
	self.expression = nil;
	self.conn = nil;
	
	[super dealloc];
}

- (id) init:(NSString *)expression global:(bool)global disable:(bool)disable conn:(id)conn seqno:(int)seqno {
	if ((self = [super init])) {
		self.expression = expression;
		self.global = global;
		self.disable = disable;
		self.seqno = seqno;
		self.conn = conn;
	}

	return self;
}

@end


static js_core *m_core = nil;


//// CPU Profiler

JSAG_MEMBER_BEGIN_NOARGS(getProfilesCount)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(getProfile)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(findProfile)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(startProfiling)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(stopProfiling)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(deleteAllProfiles)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(getProfileHeaders)
{
}
JSAG_MEMBER_END_NOARGS


JSAG_OBJECT_START(cpuProfiler)
JSAG_OBJECT_MEMBER(getProfilesCount)
JSAG_OBJECT_MEMBER(getProfile)
JSAG_OBJECT_MEMBER(findProfile)
JSAG_OBJECT_MEMBER(startProfiling)
JSAG_OBJECT_MEMBER(stopProfiling)
JSAG_OBJECT_MEMBER(deleteAllProfiles)
JSAG_OBJECT_MEMBER(getProfileHeaders)
JSAG_OBJECT_END


JSAG_MEMBER_BEGIN_NOARGS(takeSnapshot)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(getSnapshot)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(findSnapshot)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(getSnapshotsCount)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(deleteAllSnapshots)
{
}
JSAG_MEMBER_END_NOARGS


JSAG_OBJECT_START(heapProfiler)
JSAG_OBJECT_MEMBER(takeSnapshot)
JSAG_OBJECT_MEMBER(getSnapshot)
JSAG_OBJECT_MEMBER(findSnapshot)
JSAG_OBJECT_MEMBER(getSnapshotsCount)
JSAG_OBJECT_MEMBER(deleteAllSnapshots)
JSAG_OBJECT_END



@implementation DebugServer

static void OnAccept(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
	DebugServer *server = (DebugServer *)info;
	
	if (server && callbackType == kCFSocketAcceptCallBack) {
		const CFSocketNativeHandle socketId = *(const CFSocketNativeHandle *)data;

		// Enable keep alive option to avoid disconnecting on inactivity
		int opt = 1;
		if (setsockopt(socketId, SOL_SOCKET, SO_KEEPALIVE, &opt, sizeof(opt)) < 0)
		{
			LOG("{debugger} WARNING: Unable to set keep-alive option on socket");
		}
		
		DebugConnexion *conn = [[[DebugConnexion alloc] initWithSocket:socketId andServer:server] autorelease];

		if (conn) {
			[server.lock lock];
			[server.collexion addObject:conn];
			[server.lock unlock];

			// At this point, the connexion read/write callbacks will fire for this client
			LOG("{debugger} Accepted connexion from remote client");
		}
	}
}

static void NewScriptHook(JSContext	 *cx,
						  const char *filename,	 /* URL of script */
						  unsigned	  lineno,	 /* first line */
						  JSScript	 *script,
						  JSFunction *fun,
						  void		 *callerdata) {
	// This callback is invoked for EACH FUNCTION that is compiled by SpiderMonkey.

	if (script && filename && callerdata) {
		DebugServer *server = (DebugServer *)callerdata;

		NSString *fileNameStr = [NSString stringWithUTF8String:filename];

		DebugScript *ds = [server.scripts getScriptForKey:fileNameStr];

		int line_count = JS_GetScriptLineExtent(cx, script);

		if (ds) {
			[ds addFragment:script startLine:lineno lineCount:line_count];
		}
	}
}

- (void) dealloc {
	[self close];

	self.collexion = nil;
	self.evals = nil;
	self.scripts = nil;
	self.lock = nil;
	self.breakpoints = nil;

	[super dealloc];
}

- (id) init:(js_core *)js {
	if ((self = [super init])) {
		self.js = js;

		//// Start of JS calls here ////
		
		JS_BeginRequest(js.cx);

		// If bindings are not set,
		if (!m_core) {
			m_core = js;

			// Inject JS bindings
			JSObject *jsprof_obj = JS_NewObject(js.cx, NULL, NULL, NULL);
			JS_DefineProperty(js.cx, js.global, "PROFILER", OBJECT_TO_JSVAL(jsprof_obj), NULL, NULL, PROPERTY_FLAGS);
			JSAG_OBJECT_ATTACH(js.cx, jsprof_obj, cpuProfiler);
			JSAG_OBJECT_ATTACH(js.cx, jsprof_obj, heapProfiler);

			// Hook the log messages
			LoggerSetDebugger(self);
		}

		// Set up debugger hooks
		JS_SetRuntimeDebugMode(js.rt, true);
		JS_SetDebugMode(js.cx, true);
		JS_SetNewScriptHook(js.rt, NewScriptHook, self);

		JS_EndRequest(js.cx);

		//// End of JS calls here ////
		
		// Create collections
		self.collexion = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
		self.evals = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

		// Create a collexion of breakpoints
		self.breakpoints = [[[DebugBreakpointCollexion alloc] init:self] autorelease];
		
		// Create a mutex
		self.lock = [[[NSRecursiveLock alloc] init] autorelease];
		[self.lock setName:@"JSDSLockName"];

		// Create a socket
		const CFSocketContext ctx = {
			0, self, NULL, NULL, NULL
		};

		self.sock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, OnAccept, &ctx);

		if (!self.sock) {
			LOG("{debugger} Unable to create debug server socket");
		} else {
			// Fixes socket "in use" error
			int yes = 1;
			setsockopt(CFSocketGetNative(self.sock), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

			// Initialize the bind address
			struct sockaddr_in sin;
			memset(&sin, 0, sizeof(sin));

			sin.sin_len = sizeof(sin);
			sin.sin_family = AF_INET;
			sin.sin_port = htons(SERVER_PORT);
			sin.sin_addr.s_addr = INADDR_ANY;
			
			// Bind socket to address
			CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)&sin, sizeof(sin));
			if (kCFSocketSuccess != CFSocketSetAddress(self.sock, sincfd)) {
				LOG("{debugger} ERROR: Unable to bind debug server. Is another server already running?");
			} else {
				self.runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.sock, 0);
				
				if (!self.runLoopSource) {
					LOG("{debugger} ERROR: Unable to create run loop source");
				} else {
					self.dqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
					if (!self.dqueue) {
						LOG("{debugger} ERROR: Unable to get global dispatch queue");
					} else {
						// Create a thread to create the socket and execute the run loop
						self.dgroup = dispatch_group_create();
						if (!self.dgroup) {
							LOG("{debugger} ERROR: Unable to create dispatch group");
						} else {
							// Success!
							self.valid = true;

							self.scripts = [[[DebugScriptCollexion alloc] init] autorelease];
							
							dispatch_group_async(self.dgroup, self.dqueue, ^{
								[self serverThread:nil];
							});
						}
					}
				}
			}
		}
	}

	return self;
}

- (void) setInterpHook:(bool)enable {
	[self.lock lock];

	if (self.interpHookSet != enable) {
		if (enable) {
			JS_SetInterrupt(self.js.rt, StepHandler, self);
		} else {
			JS_SetInterrupt(self.js.rt, NULL, NULL);
		}

		self.interpHookSet = enable;
	}

	[self.lock unlock];
}

- (void) setThrowHook:(bool)enable {
	[self.lock lock];

	if (self.throwHookSet != enable) {
		if (enable) {
			JS_SetDebuggerHandler(self.js.rt, DebuggerHandler, self);
			JS_SetThrowHook(self.js.rt, ThrowHook, self);
		} else {
			JS_SetDebuggerHandler(self.js.rt, NULL, NULL);
			JS_SetThrowHook(self.js.rt, NULL, NULL);
		}

		self.throwHookSet = enable;
	}
	
	[self.lock unlock];
}

- (void) setCallHook:(bool)enable {
	[self.lock lock];

	if (self.callHookSet != enable) {
		if (enable) {
			// It looks like ExecuteHook is something else..
			JS_SetExecuteHook(self.js.rt, CallHook, self);
			JS_SetCallHook(self.js.rt, CallHook, self);
		} else {
			JS_SetExecuteHook(self.js.rt, NULL, NULL);
			JS_SetCallHook(self.js.rt, NULL, NULL);
		}
		
		self.callHookSet = enable;
	}
	
	[self.lock unlock];
}

- (void) serverThread:(id)param {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	self.runLoop = CFRunLoopGetCurrent();

	CFRunLoopAddSource(self.runLoop, self.runLoopSource, kCFRunLoopDefaultMode);

	LOG("{debugger} JavaScript Debug Server is listening on port %d", SERVER_PORT);

	CFRunLoopRun();

	self.valid = false;

	LOG("{debugger} JavaScript Debug Server terminated");

	[pool release];
}

- (bool) onStep:(JSContext *)cx script:(JSScript *)script line:(int)line {
	if (self.stepMode == STEP_CONTINUE) {
		[self setInterpHook:false];
		return false;
	}

	bool halt = false;

	switch (self.stepMode) {
	case STEP_IN:
		// If the line has changed,
		if (self.stepScript != script || self.stepLine != line) {
			halt = true;
			self.stepMode = STEP_CONTINUE;
		}
		break;
	case STEP_OUT:
		self.callDepth = 0;
		[self setCallHook:true];
		self.stepMode = STEP_OUT_TRACE;
		break;
	case STEP_OUT_TRACE:
		break;
	case STEP_NEXT:
		[self setCallHook:true];
		if (self.stepScript != script || self.stepLine != line) {
			halt = true;
			self.stepMode = STEP_CONTINUE;
		}
		break;
	case STEP_SUSPEND:
		// Halt execution here until 'continue' command
		halt = true;
	default:
		break;
	}

	if (halt) {
		// Look up script to trigger
		DebugScript *info = [self.scripts getScriptForFragment:script];
		if (info) {
			NSDictionary *si = [NSDictionary dictionaryWithObjectsAndKeys:
								info.path,@"name", nil];
			
			[self broadcastEvent:@"break" body:[NSDictionary dictionaryWithObjectsAndKeys:
												si,@"script",
												[NSNumber numberWithInt:line],@"sourceLine",
												@"[Source line text]",@"sourceLineText", nil]];
		}
	}

	self.stepScript = script;
	self.stepLine = line;

	return halt;
}

- (bool) onThrow:(JSContext *)cx script:(JSScript *)script line:(int)line {
	// Look up script to trigger
	DebugScript *info = [self.scripts getScriptForFragment:script];
	if (info) {
		NSDictionary *si = [NSDictionary dictionaryWithObjectsAndKeys:
							info.path,@"name", nil];
		
		[self broadcastEvent:@"break" body:[NSDictionary dictionaryWithObjectsAndKeys:
											si,@"script",
											[NSNumber numberWithInt:line],@"sourceLine",
											@"[Source line text]",@"sourceLineText", nil]];
	}

	// Always halt on exception if we caught one
	return true;
}

- (bool) onDebug:(JSContext *)cx script:(JSScript *)script line:(int)line {
	// Look up script to trigger
	DebugScript *info = [self.scripts getScriptForFragment:script];
	if (info) {
		NSDictionary *si = [NSDictionary dictionaryWithObjectsAndKeys:
							info.path,@"name", nil];

		[self broadcastEvent:@"break" body:[NSDictionary dictionaryWithObjectsAndKeys:
											si,@"script",
											[NSNumber numberWithInt:line],@"sourceLine",
											@"[Source line text]",@"sourceLineText", nil]];
	}

	// Always halt on exception if we caught one
	return true;
}

- (bool) onBreakpoint:(JSContext *)cx script:(JSScript *)script line:(int)line {
	self.stepScript = script;
	self.stepLine = line;
	
	DebugBreakpoint *bp = [self.breakpoints findBreakpoint:script line:line];

	if ([self.collexion count] <= 0) {
		LOG("{debugger} WARNING: Break while no clients attached. Resuming.");
	} else {
		if (!bp) {
			LOG("{debugger} WARNING: Break on unset breakpoint. Resuming.");
		} else {
			if (!bp.enabled) {
				LOG("{debugger} WARNING: Breakpoint encountered that was supposed to be cleared. Resuming.");
			} else {
				NSDictionary *si = [NSDictionary dictionaryWithObjectsAndKeys:
									bp.script.path,@"name", nil];

				[self broadcastEvent:@"break" body:[NSDictionary dictionaryWithObjectsAndKeys:
													si,@"script",
													[NSNumber numberWithInt:line],@"sourceLine",
													@"[Source line text]",@"sourceLineText", nil]];
				return true;
			}
		}
	}
	
	return false;
}

- (bool) onCall:(JSContext *)cx frame:(JSAbstractFramePtr)fp before:(bool)before {
	if (self.stepMode == STEP_CONTINUE) {
		[self setCallHook:false];
		return false;
	}

	if (before) {
		self.callDepth++;
	} else {
		self.callDepth--;
	}

	bool halt = false;

	switch (self.stepMode) {
		case STEP_IN:
			// Ignore call hook during step in
			[self setCallHook:false];
			break;
		case STEP_OUT:
		case STEP_OUT_TRACE:
			if (self.callDepth < 0) {
				self.callDepth = 0;

				// Switch mode so that interpreter hook doesn't pass it back here
				self.stepMode = STEP_SUSPEND;
				[self setCallHook:false];
			}
			break;
		case STEP_NEXT:
			if (self.callDepth > 0) {
				[self setInterpHook:false];
			} else {
				[self setInterpHook:true];
				self.callDepth = 0;
			}
			break;
		case STEP_SUSPEND:
			// Ignore call hook during suspend
			[self setCallHook:false];
		default:
			break;
	}

	return halt;
}

- (void) queueEval:(NSString *)expression global:(bool)global disable:(bool)disable conn:(id)conn seqno:(int)seqno {
	DebugEval *eval = [[DebugEval alloc] init:expression global:global disable:disable conn:conn seqno:seqno];

	[self.lock lock];
	[self.evals addObject:eval];
	self.hasEvals = true;
	[self.lock unlock];
}

- (void) runQueuedEval:(JSContext *)cx {
	// NOTE: We don't need to do BeginRequest and EndRequest here to make it GC-threadsafe

  JSBrokenFrameIterator fi(cx);
  JSAbstractFramePtr fp = fi.abstractFramePtr();
  
  JS::RootedObject jsobj(cx);
	if (fp) {
    jsobj = fp.callObject(cx);
  } else {
    jsobj = JS::CurrentGlobalOrNull(cx);
	}

	// If no stack frame,
	if (!fp) {
		LOG("{debugger} WARNING: No stack frame available for queued eval");
		return;
	}

	[self.lock lock];

	self.ignoreHooks = true;

	// For each eval queued,
	for (DebugEval *eval in self.evals) {
		// If attached connexion is valid,
		if (eval.conn.valid) {
			int chars = (int)[eval.expression length];
			unichar *buffer;

			if (chars <= 0) {
				buffer = (unichar*)"\0\0";
			} else {
				buffer = (unichar*)JS_malloc(cx, chars * sizeof(unichar));
				[eval.expression getCharacters:buffer range:NSMakeRange(0, chars)];
			}

      JS::RootedValue rval(cx);
			if (fp.evaluateUCInStackFrame(cx, (jschar*)buffer, chars, "(debug)", 0, &rval)) {
				if (!JSVAL_IS_PRIMITIVE(rval)) {
          JS::RootedObject obj(cx, JSVAL_TO_OBJECT(rval));

					NSDictionary *dict = [eval.conn.mirror addObject:obj context:cx];

					[eval.conn postResponse:eval.seqno success:true body:dict refs:nil];
				} else {
          JS::RootedString jstr(cx, JS::ToString(cx, rval));

					if (!jstr) {
						[eval.conn postResponse:eval.seqno success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
																			  @"string",@"type",
																			  @"(empty string)",@"value", nil] refs:nil];
					} else {
						JSTR_TO_NSTR(cx, jstr, nstr);
						
						NSString *type = @"string";

						if (JSVAL_IS_BOOLEAN(rval)) {
							type = @"boolean";
						} else if (JSVAL_IS_NUMBER(rval)) {
							type = @"number";
						}

						[eval.conn postResponse:eval.seqno success:true body:[NSDictionary dictionaryWithObjectsAndKeys:
																			  type,@"type",
																			  nstr,@"value", nil] refs:nil];
					}
				}
			} else {
				[eval.conn postResponse:eval.seqno success:false];
			}

			if (chars > 0) {
				JS_free(cx, buffer);
			}
		}
	}

	[self.evals removeAllObjects];

	self.hasEvals = false;
	self.ignoreHooks = false;

	[self.lock unlock];
}

- (void) reclaimConnexions {
	if (self.pendingDeaths) {

		// Race condition here could allow some deaths to go unreclaimed for a while, but this is OK

		self.pendingDeaths = false;

		NSMutableArray *tokill = [NSMutableArray arrayWithCapacity:0];

		[self.lock lock];

		// For each connexion,
		for (DebugConnexion *conn in self.collexion) {
			if (!conn.valid) {
				[tokill addObject:conn];
			}
		}
		
		[self.collexion removeObjectsInArray:tokill];

		[self.lock unlock];
	}
}

- (void) broadcast:(const char*)message count:(long)bytes {
	[self.lock lock];

	// For each connexion,
	for (DebugConnexion *conn in self.collexion) {
		if (conn.valid) {
			[conn write:message count:bytes];
		}
	}

	[self.lock unlock];
	
	// Reclaim connexions here if needed
	// NOTE: Heuristically this will happen "often enough" because it happens when log messages are broadcast
	[self reclaimConnexions];
}

- (void) broadcastMessage:(NSString *)msg {
	NSString *frame = [NSString stringWithFormat:@"Content-Length: %ld\r\n\r\n%@",
                     (unsigned long)[msg length], msg];

	[self broadcast:[frame UTF8String] count:[frame length]];
}

- (void) broadcastEvent:(NSString *)name body:(id)body {
	[self.lock lock];

	// For each connexion,
	for (DebugConnexion *conn in self.collexion) {
		if (conn.valid) {
			[conn postEvent:name body:body];
		}
	}

	[self.lock unlock];

	// Reclaim connexions here if needed
	// NOTE: Heuristically this will happen "often enough" because it happens when log messages are broadcast
	[self reclaimConnexions];
}

- (NSString *) setScriptForPath:(NSString *)path source:(NSString *)source {
	[self.lock lock];
	DebugScript *script = [self.scripts setScriptForPath:path source:source];
	[self.lock unlock];

	// Broadcast compile notification without source
	[self broadcastEvent:@"afterCompile" body:[NSDictionary dictionaryWithObjectsAndKeys:
											   [script generateScriptInfo:false],@"script", nil]];

	return script.key;
}

- (void) onLogMessage:(NSString *)msg {
	// Broadcast log messages
	[self broadcastEvent:@"log" body:[NSDictionary dictionaryWithObjectsAndKeys:
											   msg,@"message", nil]];
}

- (void) close {
	self.valid = false;

	if (self.sock) {
		CFSocketInvalidate(self.sock);
		CFRelease(self.sock);

		self.sock = nil;
	}

	if (self.runLoop) {
		CFRunLoopStop(self.runLoop);
	}
 
	// Wait here for server thread to stop
	if (self.dgroup) {
		dispatch_group_wait(self.dgroup, DISPATCH_TIME_FOREVER);
		dispatch_release(self.dgroup);

		self.dgroup = nil;
	}
	
	if (self.runLoopSource) {
		CFRelease(self.runLoopSource);
		
		self.runLoopSource = nil;
	}
}

@end
