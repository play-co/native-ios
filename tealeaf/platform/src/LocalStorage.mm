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

#include "LocalStorage.h"

void local_storage_set(NSString *key, NSString *value) {
	NSMutableDictionary *storage = [[NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary*)retrieveFromUserDefaults(@"localStorage")] retain];
	if (!storage) {
		storage = [[NSMutableDictionary alloc] init];
	}
	[storage setObject:value forKey:key];
	saveToUserDefaults(@"localStorage", storage);
	[storage release];
}

NSString *local_storage_get(NSString *key) {
	NSMutableDictionary *storage = (NSMutableDictionary*)retrieveFromUserDefaults(@"localStorage");
	if (!storage) {
		return nil;
	}
	return [storage objectForKey:key];
}

void local_storage_remove(NSString *key) {
	NSMutableDictionary *storage = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary*)retrieveFromUserDefaults(@"localStorage")];
	if (storage) {
		[storage removeObjectForKey:key];
		saveToUserDefaults(@"localStorage", storage);
	}
}

void local_storage_clear() {
	NSMutableDictionary *storage = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary*)retrieveFromUserDefaults(@"localStorage")];
	if (storage) {
		[storage removeAllObjects];
		saveToUserDefaults(@"localStorage", storage);
	}
}

NSString *local_storage_key(int index) {
	NSMutableDictionary *storage = [NSMutableDictionary dictionaryWithDictionary:(NSMutableDictionary*)retrieveFromUserDefaults(@"localStorage")];
	if (!storage) {
		return nil;
	}
	NSString *key = nil;
	NSEnumerator *i = [storage keyEnumerator];
	int count = 0;
	while ((key =[i nextObject])) {
		if (count++ == index) {
			return key;
		}
	}
	return nil;
}

void saveToUserDefaults(NSString* key, id value) {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

	if (standardUserDefaults) {
		[standardUserDefaults setObject:value forKey:key];
	}
}

id retrieveFromUserDefaults(NSString *key) {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	id val = nil;

	if (standardUserDefaults) {
		val = [standardUserDefaults objectForKey:key];
	}
	return val;
}

void removeFromUserDefaults(NSString *key) {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

	if (standardUserDefaults) {
		[standardUserDefaults removeObjectForKey:key];
	}
}

void clearUserDefaults() {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
	}
}

void syncUserDefaults() {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults synchronize];
	}
}

