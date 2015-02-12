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

#import "js/jsSocket.h"
#import "AsyncSocket.h"
#import "platform/log.h"
#include "core/events.h"

#import "jansson.h"
#import "jsonUtil.h"

@interface SocketWrapper : NSObject

@property (nonatomic, retain) AsyncSocket *socket;
@property (nonatomic) JSContext *cx;
@property (nonatomic) JSObject *thiz;

- (id) initWithContext:(JSContext *)cx andObject:(JSObject *)thiz andHost:(NSString *)host andPort:(int)port andTimeout:(int)timeout;

- (void) send:(NSString *)data;

@end


@implementation SocketWrapper

@synthesize thiz = _thiz;

- (void) dealloc {
	JS_RemoveObjectRoot(self.cx, &_thiz);
	
	self.socket = nil;
	self.cx = nil;
	self.thiz = nil;

	[super dealloc];
}

- (id) initWithContext:(JSContext *)cx andObject:(JSObject *)pthiz andHost:(NSString *)host andPort:(int)port andTimeout:(int)timeout {
	self = [super init];

	self.thiz = pthiz;
	self.cx = cx;

	JS_AddObjectRoot(cx, &_thiz);

	NSLOG(@"{socket} Connecting...");

	NSError *err;
	self.socket = [[[AsyncSocket alloc] initWithDelegate:self] autorelease];
	if ([self.socket connectToHost:host onPort:port withTimeout:timeout error:&err]) {
		// Success!
	} else {
		jsval rval, jstr = CSTR_TO_JSVAL(cx, "could not connect");
		JS_CallFunctionName(cx, pthiz, "onError", 1, &jstr, &rval);

		self.socket = nil;
	}
	
	return self;
}

- (void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	NSString *titleString = @"socket error";
	NSString *messageString = [err localizedDescription];
	NSString *moreString = [err localizedFailureReason] ? [err localizedFailureReason] : @"";
	messageString = [NSString stringWithFormat:@"%@: %@. %@", titleString, messageString, moreString];
	NSLOG(@"{socket} Socket error '%@'", messageString);
	jsval rval, jstr = NSTR_TO_JSVAL(self.cx, messageString);
	JS_CallFunctionName(self.cx, self.thiz, "onError", 1, &jstr, &rval);
}

- (void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	jsval rval;
	JS_CallFunctionName(self.cx, self.thiz, "onConnect", 0, NULL, &rval);
	[sock readDataWithTimeout:-1 tag:0];
}

- (void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length])];
	NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
	if (msg) {
		[msg autorelease];
    JS::RootedValue rval(self.cx);
		JS_GetProperty(self.cx, self.thiz, "__id", &rval);
    int32_t intVal = 0;
    if (!JS::ToInt32(self.cx, rval, &intVal)) {
      intVal = 0;
    }
		NSString *evt = [NSString stringWithFormat: @"{\"id\":%d,\"name\":\"socketRead\"}", intVal];
		const char *cEvt = [evt UTF8String];
		json_error_t err;
		json_t *jsEvt = json_loads(cEvt, 0, &err);
		if (jsEvt && json_is_object(jsEvt)) {
			JSON_AddOptionalString(jsEvt, "data", msg);
			const char *jsChars = json_dumps(jsEvt, JSON_PRESERVE_ORDER);
			core_dispatch_event(jsChars);
		} else {
			NSLOG(@"{socket} failed to create JSON event object: '%@'", msg);
		}
	} else {
		const char *err = "Error converting received data into UTF-8 String";
    
		LOG("{socket} %s", err);

		jsval rval, jstr = CSTR_TO_JSVAL(self.cx, err);
		JS_CallFunctionName(self.cx, self.thiz, "onError", 1, &jstr, &rval);
	}
	
	[self.socket readDataWithTimeout:-1 tag:0];
}

- (void) onSocketDidDisconnect:(AsyncSocket *)sock {
	jsval rval;
	JS_CallFunctionName(self.cx, self.thiz, "onClose", 0, NULL, &rval);

	JS_RemoveObjectRoot(self.cx, &_thiz);
}

- (void) send:(NSString *)message {
	if (!self.socket || !message || ![message length]) {
		return;
	}
	
	NSData *msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
	[self.socket writeData:msgData withTimeout:-1 tag:0];
	[self.socket readDataWithTimeout:-1 tag:0];
}

- (void) close {
	if (self.socket) {
		[self.socket setDelegate:nil];
		[self.socket disconnect];
		self.socket = nil;
	}
}

@end


JSAG_CLASS_FINALIZE(Socket, obj) {
	SocketWrapper *socket = (SocketWrapper*)JSAG_GET_PRIVATE(obj);
	
	if (likely(!!socket)) {
		[socket close];
		[socket release];
	}
}

JSAG_CLASS_IMPL(Socket);

int idCounter = 1;

JSAG_MEMBER_BEGIN(Socket, 2)
{
	JSAG_ARG_NSTR(host);
	JSAG_ARG_INT32(port);
	JSAG_ARG_INT32_OPTIONAL(timeout, 5);

//  JSAG_OBJECT *thiz(cx, JSAG_CLASS_INSTANCE(Socket));
  JS::RootedObject thiz(cx, JS_NewObjectForConstructor(cx, &Socket_class, vp));
	
	NSLOG(@"{socket} Created for %@:%d", host, port);

	SocketWrapper *socket = [[SocketWrapper alloc] initWithContext:cx andObject:thiz andHost:host andPort:port andTimeout:timeout];

	JSAG_SET_PRIVATE(thiz, socket);

  JS::RootedValue jsID(cx, JS::NumberValue(idCounter++));
	JSAG_ADD_PROPERTY(thiz, __id, jsID);

	JSAG_RETURN_OBJECT(thiz);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(send, 1)
{
	JSObject *thiz = JSAG_THIS;

	if (likely(!!thiz)) {
		SocketWrapper *socket = (SocketWrapper *)JSAG_GET_PRIVATE(thiz);
		if (!socket) {
			const char *err = "Cannot send on a closed socket.";
			LOG("{socket} %s", err);

			jsval rval, jstr = CSTR_TO_JSVAL(cx, err);
			JS_CallFunctionName(cx, thiz, "onError", 1, &jstr, &rval);
		} else {
			JSAG_ARG_NSTR(msg);

			[socket send:msg];
		}
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN(close, 0)
{
  JS::RootedObject thiz(cx, JSVAL_TO_OBJECT(args.thisv()));

	if (likely(!!thiz)) {
		SocketWrapper *socket = (SocketWrapper *)JSAG_GET_PRIVATE(thiz);
		
		if (socket) {
			[socket close];
			// TODO: Release socket in a way that won't cause problems with double-free if closed twice etc
		}
	}
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(defaultCallback)
{
}
JSAG_MEMBER_END_NOARGS

JSAG_OBJECT_START(Socket)
JSAG_OBJECT_MEMBER(send)
JSAG_OBJECT_MEMBER(close)
JSAG_MUTABLE_OBJECT_MEMBER_NAMED(onConnect, defaultCallback)
JSAG_MUTABLE_OBJECT_MEMBER_NAMED(onRead, defaultCallback)
JSAG_MUTABLE_OBJECT_MEMBER_NAMED(onError, defaultCallback)
JSAG_MUTABLE_OBJECT_MEMBER_NAMED(onClose, defaultCallback)
JSAG_OBJECT_END


@implementation jsSocket

+ (void) addToRuntime:(js_core *)js {
	JSContext *cx = js.cx;

	JSAG_CREATE_CLASS(js.native, Socket);
}

+ (void) onDestroyRuntime {
	
}

@end
