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

#include "core/platform/get_locale.h"

static locale_info m_locale = {
	"",
	""
};

static bool m_init = false;

locale_info *locale_get_locale() {
	if (!m_init) {
		m_init = true;

		NSLocale *currentLocale = [NSLocale currentLocale];
		NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
		NSString *language;
		if ([[NSLocale preferredLanguages] count] > 0) {
			language = [[NSLocale preferredLanguages] objectAtIndex:0];
		}
		else {
			language = [currentLocale objectForKey:NSLocaleLanguageCode];
		}

		m_locale.country = strdup([countryCode UTF8String]);
		m_locale.language = strdup([language UTF8String]);
	}

	return &m_locale;
}
