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

//
//  InputUtils.mm
//  TeaLeafIOS
//
//  Created by Martin Hunt on 8/13/13.
//  Copyright (c) 2013 Game Closure. All rights reserved.
//

#import "InputUtils.h"

// static NSString *INPUTTYPE_DEFAULT = @"DEFAULT";
static NSString *INPUTTYPE_NUMBER = @"NUMBER";
static NSString *INPUTTYPE_PHONE = @"PHONE";
static NSString *INPUTTYPE_PASSWORD = @"PASSWORD";
static NSString *INPUTTYPE_CAPITAL = @"CAPITAL";

// default | go | google | join | next | route | search | send | yahoo | done | emergencycall
static NSString *RETURN_KEY_GO = @"go";
static NSString *RETURN_KEY_GOOGLE = @"google";
static NSString *RETURN_KEY_JOIN = @"join";
static NSString *RETURN_KEY_NEXT = @"next";
static NSString *RETURN_KEY_ROUTE = @"route";
static NSString *RETURN_KEY_SEARCH = @"search";
static NSString *RETURN_KEY_SEND = @"send";
static NSString *RETURN_KEY_YAHOO = @"yahoo";
static NSString *RETURN_KEY_DONE = @"done";
static NSString *RETURN_KEY_EMERGENCYCALL = @"emergencycall";

@implementation InputUtils

+(void)setKeyboardReturnType:(NSString*)returnButtonString forTextField:(UITextField *)textField {
    UIReturnKeyType returnKeyType = UIReturnKeyDefault;
    NSString *returnButtonUpper = [returnButtonString uppercaseString];
    if ([returnButtonUpper isEqualToString:RETURN_KEY_GO]) {
        returnKeyType = UIReturnKeyGo;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_GOOGLE]) {
        returnKeyType = UIReturnKeyGoogle;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_JOIN]) {
        returnKeyType = UIReturnKeyJoin;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_NEXT]) {
        returnKeyType = UIReturnKeyNext;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_ROUTE]) {
        returnKeyType = UIReturnKeyRoute;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_SEARCH]) {
        returnKeyType = UIReturnKeySearch;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_SEND]) {
        returnKeyType = UIReturnKeySend;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_YAHOO]) {
        returnKeyType = UIReturnKeyYahoo;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_DONE]) {
        returnKeyType = UIReturnKeyDone;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_EMERGENCYCALL]) {
        returnKeyType = UIReturnKeyEmergencyCall;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_SEND]) {
        returnKeyType = UIReturnKeySend;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_GO]) {
        returnKeyType = UIReturnKeyGo;
    } else if ([returnButtonUpper isEqualToString:RETURN_KEY_GOOGLE]) {
        returnKeyType = UIReturnKeyGoogle;
    }
    
    textField.returnKeyType = returnKeyType;
}

+(void)setKeyboardType:(NSString*)keyboardTypeString forTextField:(UITextField *)textField {
    
    UITextAutocapitalizationType autocapitalizationType = UITextAutocapitalizationTypeNone;
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
	NSString *inputTypeUpper = [keyboardTypeString uppercaseString];
    bool secureTextEntry = NO;
    
	if ([inputTypeUpper isEqualToString:INPUTTYPE_NUMBER]) {
		keyboardType = UIKeyboardTypeNumberPad;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_PHONE]) {
		keyboardType = UIKeyboardTypePhonePad;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_PASSWORD]) {
        autocapitalizationType = UITextAutocapitalizationTypeNone;
		secureTextEntry = YES;
	} else if ([inputTypeUpper isEqualToString:INPUTTYPE_CAPITAL]) {
		autocapitalizationType = UITextAutocapitalizationTypeWords;
	}
    
    textField.keyboardType = keyboardType;
    textField.autocapitalizationType = autocapitalizationType;
    textField.secureTextEntry = secureTextEntry;
}

@end