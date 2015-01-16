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

#import <UIKit/UIKit.h>

#import "core/platform/native.h"
#import "js/js_core.h"
#include "core/texture_manager.h"

void start_game(const char *appid) {
	// Violates Apple iTunes ToS
}

void apply_update() {
	// Violates Apple iTunes ToS
}

static const char *m_market_url = NULL;

const char *get_market_url() {
	if (!m_market_url) {
		js_core *instance = [js_core lastJS];

		NSString *myAppID = [instance.config objectForKey:@"apple_id"];
		NSString *url = [NSString stringWithFormat: @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", myAppID];

		m_market_url = strdup([url UTF8String]);
	}

	return m_market_url;
}

const char *get_app_version() {
	// TODO: Probably remove this
	return "TODO";
}

bool native_send_activity_to_back() {
	// Minimize the game
	return false;
}

char *get_storage_directory() {
	// Returns path to where files are stored (only needed for cross-promo and updates)
	return (char*)"TODO";
}

void upload_contacts() {
	// TODO: Remove this!
}

void upload_device_info() {
	// TODO: Remove this! 
}

const char *get_install_referrer() {
	// TODO: Look into options here
	return "TODO";
}

CEXPORT void set_halfsized_textures(bool on) {
	texture_manager_set_use_halfsized_textures(on);
}

CEXPORT void native_stay_awake(bool on) {
	[[UIApplication sharedApplication] setIdleTimerDisabled:(on ? YES : NO)];
}

const char *get_version_code() {
	// Incrementing number Info.plist
	return "TODO";
}

CEXPORT void report_gl_error(int error_code, gl_error **errors_hash, bool unrecoverable) {
	// TODO
}
