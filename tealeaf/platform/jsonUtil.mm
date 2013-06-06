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

#include "jsonUtil.h"

void JSON_AddOptionalString(json_t *obj, const char *key, NSString *value) {
	if (value == nil || value == (id)[NSNull null]) {
		json_object_set_nocheck(obj, key, json_null());
	} else {
		json_object_set_new(obj, key, json_string_nocheck([value UTF8String]));
	}
}

void JSON_AppendOptionalString(json_t *arr, NSString *value) {
    if (value == nil || value == (id)[NSNull null]) {
        json_array_append(arr, json_null());
    } else {
        json_array_append_new(arr, json_string_nocheck([value UTF8String]));
    }
}

