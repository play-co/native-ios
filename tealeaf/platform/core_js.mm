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

#include "types.h"

#import "js_core.h"
#include "log.h"
#include "js/js.h"
#include "core/config.h"
#import "allExtensions.h"
#import "ResourceLoader.h"
#import "TeaLeafAppDelegate.h"
#include "core/timestep/timestep_animate.h"
#include "core/timestep/timestep_events.h"
#include "core/timestep/timestep_view.h"
#include "core/timer.h"
#include "core_js.h"
//#import "TeaLeafEvent.h"
#import "SoundManager.h"


static js_core *m_core = 0;

CEXPORT bool setup_js_runtime() {
	return 0 != (m_core = [[js_core alloc] initRuntime]);
}

CEXPORT bool init_js(const char *uri, const char *version) {
	if (m_core && !js_ready) {
		TeaLeafAppDelegate *app = (TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate];
        
		NSString *baseURL = [NSString stringWithUTF8String:uri];
		
		js_core *js = m_core;
		[js setConfig:app.config pluginManager:app.pluginManager];
		
		ResourceLoader *loader = [ResourceLoader get];
		[loader setBaseURL:[NSURL URLWithString:baseURL]];
		
		[jsConsole addToRuntime:js];
		[jsGL addToRuntime:js];
		[jsSound addToRuntime:js];
		[jsLocalStorage addToRuntime:js];
		[jsXHR addToRuntime:js];
		[jsTextInput addToRuntime:js withSuperView:app.tealeafViewController.view];
		[jsOverlay addToRuntime:js withSuperView:app.tealeafViewController.view];
		[jsDialog addToRuntime:js];
		[jsPhoto addToRuntime:js];
		[jsTimestep addToRuntime:js];
		[jsLocale addToRuntime:js];
		[jsNavigator addToRuntime:js];
		[jsAds addToRuntime:js];
		[jsGC addToRuntime:js];
		[jsPluginManager addToRuntime:js];
		[jsMarket addToRuntime:js];
		[jsBuild addToRuntime:js];
		[jsInput addToRuntime:js];
		[jsHaptics addToRuntime:js];
		[jsBase addToRuntime:js];
		[jsTimer addToRuntime:js];
		[jsSocket addToRuntime:js];
		[jsImageCache addToRuntime:js];
   //     [TeaLeafEvent InitWithJS: js];
		
		[jsBase setLocation:baseURL];
		
		js_ready = true;
	}
    
	return true;
}

CEXPORT bool destroy_js() {
	if (js_ready) {
		js_ready = false;
		
		LOG("{js} Shutting down...");
		
		TeaLeafAppDelegate *app = (TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate];
        
		[app.canvas stopRendering];
        
		view_animation_shutdown();
		timestep_events_shutdown();
		timestep_view_shutdown();
        
		[jsConsole onDestroyRuntime];
		[jsGL onDestroyRuntime];
		[jsSound onDestroyRuntime];
		[jsLocalStorage onDestroyRuntime];
		[jsXHR onDestroyRuntime];
		[jsTextInput onDestroyRuntime];
		[jsOverlay onDestroyRuntime];
		[jsDialog onDestroyRuntime];
		[jsPhoto onDestroyRuntime];
		[jsTimestep onDestroyRuntime];
		[jsLocale onDestroyRuntime];
		[jsNavigator onDestroyRuntime];
		[jsAds onDestroyRuntime];
		[jsGC onDestroyRuntime];
		[jsPluginManager onDestroyRuntime];
		[jsMarket onDestroyRuntime];
		[jsBuild onDestroyRuntime];
		[jsInput onDestroyRuntime];
		[jsHaptics onDestroyRuntime];
		[jsBase onDestroyRuntime];
		[jsTimer onDestroyRuntime];
		[jsSocket onDestroyRuntime];
		
		core_timer_clear_all();
        
		SoundManager *sm = [SoundManager get];
		if (sm) {
			[sm stopBackgroundMusic];
			[sm clearEffects];
		}
	}
    
	if (m_core) {
		[m_core shutdown];
		[m_core release];
		m_core = 0;
	}
    
	return true;
}

CEXPORT void eval_str(const char *str) {
	if (m_core) {
		[m_core evalStr:[NSString stringWithUTF8String:str]];
	}
}


CEXPORT void js_dispatch_event(const char *evt) {
	if (m_core) {
		[m_core performSelectorOnMainThread: @selector(dispatchEventFromString:) withObject:[NSString stringWithUTF8String:evt] waitUntilDone:NO];
	}
}

CEXPORT void js_on_pause() {
	
}

CEXPORT void js_on_resume() {
	
}


CEXPORT void js_object_wrapper_init(PERSISTENT_JS_OBJECT_WRAPPER *obj) {
	*obj = NULL;
}

CEXPORT void js_object_wrapper_root(PERSISTENT_JS_OBJECT_WRAPPER *obj, JS_OBJECT_WRAPPER target) {
	js_object_wrapper_delete(obj);
    
	*obj = target;
    
	JS_AddObjectRoot(get_js_context(), obj);
}

CEXPORT void js_object_wrapper_delete(PERSISTENT_JS_OBJECT_WRAPPER *obj) {
	if (*obj) {
		JS_RemoveObjectRoot(get_js_context(), obj);
		*obj = NULL;
	}
}
