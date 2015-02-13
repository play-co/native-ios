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

#import "js/jsOverlay.h"
#import "platform/TeaLeafAppDelegate.h"
#import "platform/ResourceLoader.h"

// #define CACHE_POLICY NSURLRequestUseProtocolCachePolicy
#define CACHE_POLICY NSURLRequestReloadIgnoringCacheData

static js_core *m_core = nil;


@interface OverlayView : UIWebView <UIWebViewDelegate>
@end

@implementation OverlayView

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.delegate = self;
	return self;
}

- (BOOL) webView:(UIWebView *)myWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	NSLOG(@">> %@", url);
	
	if ([[url host] isEqualToString:@"localhost"] && [[url path] hasPrefix:@"/MESSAGE"]) {
		NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[m_core evalStr:[NSString stringWithFormat: @"NATIVE.overlay.delegate.publish('message', %@);", query]];
		NSLOG(@"{overlay} Navigation event: %@", query);
		return NO;
	}
	
	return YES;
}

@end


static OverlayView *overlayView = nil;


static void loadURL(NSString *urlStr) {
	NSURL *url = [[ResourceLoader get] resolve:urlStr];
	BOOL there = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
	NSURL *theURL = [NSURL fileURLWithPath:[url path]];
	NSLOG(@"{overlay} Loading '%@' / '%@' - %@ - %@", [url absoluteString], [url path], (there ? @"Exists" : @"Does Not Exist"), theURL);
	NSURLRequest *req = [NSURLRequest requestWithURL:theURL cachePolicy:CACHE_POLICY timeoutInterval: 1000];
	[overlayView loadRequest:req];
}


JSAG_MEMBER_BEGIN(load, 1)
{
	JSAG_ARG_NSTR(url);

	loadURL(url);
}
JSAG_MEMBER_END

JSAG_MEMBER_BEGIN_NOARGS(show)
{
	LOG("{overlay} Shown");
	overlayView.hidden = NO;
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN_NOARGS(hide)
{
	LOG("{overlay} Hidden");
	overlayView.hidden = YES;
}
JSAG_MEMBER_END_NOARGS

JSAG_MEMBER_BEGIN(send, 1)
{
	JSAG_ARG_NSTR(data);

	NSLOG(@"{overlay} Sending event %@", data);

	[overlayView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"GC.onMessage(%@)", data]];
}
JSAG_MEMBER_END


JSAG_OBJECT_START(overlay)
JSAG_OBJECT_MEMBER(load)
JSAG_OBJECT_MEMBER(show)
JSAG_OBJECT_MEMBER(send)
JSAG_OBJECT_MEMBER(hide)
JSAG_OBJECT_END


@implementation jsOverlay

+ (void) addToRuntime:(js_core *)js withSuperView:(UIView *)superView {
	m_core = js;

	JSObject *overlay = JS_NewObject(js.cx, NULL, NULL, NULL);
	JSAG_OBJECT_ATTACH_EXISTING(js.cx, js.native, overlay, overlay);
	JS_DefineProperty(js.cx, overlay, "delegate", JSVAL_NULL, NULL, NULL, 0);

	//HACK TODO fix or remove this. We don't use overlays anymore, though.
	if (false && !overlayView) {
		CGRect bounds = [superView bounds];
		//bounds.origin.x = bounds.size.width;
		// bounds.origin.y = bounds.size.height;
		overlayView = [[[OverlayView alloc] initWithFrame:bounds] autorelease];
		overlayView.hidden = YES;
		overlayView.opaque = NO;
		overlayView.backgroundColor = [UIColor clearColor];
		//[overlayView setTransform: CGAffineTransformRotate(overlayView.transform , M_PI)];
		
		//[superView addSubview:overlayView];
	}
}

+ (void) onDestroyRuntime {
	if (m_core) {
		m_core = nil;

		if (overlayView) {
			overlayView.hidden = YES;
			overlayView.opaque = NO;
			overlayView.backgroundColor = [UIColor clearColor];
		}
	}
}

@end
