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

#ifndef JSON_UTIL_H
#define JSON_UTIL_H

// We use Jansson for JSON serialization.
// This adds the json_t type and associated functions.
// See the nice docs here: http://www.digip.org/jansson/doc/2.3/
// To avoid leaking memory, the basic rule is to use the json_object_set_new()
// method when you set a new key on a JSON object, and call json_decref(obj)
// on the top level JSON object when you are done.
#include "jansson.h"

// This is iPhone-specific stuff

// Add key to object with the given string as a value, or add a javascript
// null value if the string value is null in Objective C
void JSON_AddOptionalString(json_t *obj, const char *key, NSString *value);
void JSON_AppendOptionalString(json_t *arr, NSString *value);

#endif // JSON_UTIL_H

