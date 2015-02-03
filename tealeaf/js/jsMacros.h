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

#ifndef JS_MACROS_H
#define JS_MACROS_H

#include <memory>

namespace JS {
  struct FreePolicy
  {
    void operator()(void* ptr) {
      js_free(ptr);
    }
  };
} // JS

// JSTR = JavaScript SpiderMonkey string
// NSTR = NSString Objective-C string
// CSTR = UTF8 C string

// The string created by these conversions will last until the
// function returns and does not need to be explicitly freed.

#define JSTR_TO_CSTR(cx, jstr, cstr) \
	size_t cstr ## _len = JS_GetStringEncodingLength(cx, jstr); \
	char *cstr = (char*)alloca(sizeof(char) * (cstr ## _len + 1)); \
	JS_EncodeStringToBuffer(cx, jstr, cstr, cstr ## _len); \
	cstr[cstr ## _len] = (char)'\0';

#define JSTR_TO_CSTR_PERSIST(cx, jstr, cstr) \
	size_t cstr ## _len = JS_GetStringEncodingLength(cx, jstr); \
	char *cstr = (char*)malloc(sizeof(char) * (cstr ## _len + 1)); \
	JS_EncodeStringToBuffer(cx, jstr, cstr, cstr ## _len); \
	cstr[cstr ## _len] = (char)'\0';

#define PERSIST_CSTR_RELEASE(cstr) \
	free(cstr);

#define STRINGIZE(x) STRINGIZE1(x)
#define STRINGIZE1(x) #x
#define AG_FILELINE __FILE__ " at line " STRINGIZE(__LINE__)

#define CSTR_TO_JSTR(cx, cstr) JS_NewStringCopyZ(cx, cstr)

#define CSTR_TO_JSVAL(cx, cstr) STRING_TO_JSVAL(CSTR_TO_JSTR(cx, cstr))

#if (__OBJC__) == 1

#define JSTR_TO_NSTR(cx, jstr, nstr) \
	size_t nstr ## _len; \
	jschar *nstr ## _jc = (jschar*)JS_GetStringCharsZAndLength(cx, jstr, &nstr ## _len); \
	NSString *nstr = [[[NSString alloc] initWithCharactersNoCopy:(unichar*)nstr ## _jc length:nstr ## _len freeWhenDone:NO] autorelease];

inline JSString *JSStringFromNSString(JSContext *cx, NSString *nstr) {
	int chars = (int)[nstr length];
	unichar *buffer;

	if (chars <= 0) {
		return JSVAL_TO_STRING(JS_GetEmptyStringValue(cx));
	} else {
		buffer = (unichar*)JS_malloc(cx, chars * sizeof(unichar));
		[nstr getCharacters:buffer range:NSMakeRange(0, chars)];

		JSString *rval = JS_NewUCString(cx, (jschar*)buffer, chars);
		if (!rval) {
			JS_free(cx, buffer);
		}
		return rval;
	}
}

#define NSTR_TO_JSTR(cx, nstr) JSStringFromNSString(cx, nstr)

#define NSTR_TO_JSVAL(cx, nstr) STRING_TO_JSVAL(NSTR_TO_JSTR(cx, nstr))

#define JSVAL_TO_NSTR(cx, val, nstr) \
	JSString *nstr ## _jstr = JS::ToString(cx, val); \
	JSTR_TO_NSTR(cx, nstr ## _jstr, nstr);

#endif

#define JSVAL_TO_CSTR(cx, val, cstr) \
	JSString *cstr ## _jstr = JSVAL_TO_STRING(val); \
	JSTR_TO_CSTR(cx, cstr ## _jstr, cstr);

// TODO: Needed?
//#ifndef __UNUSED
//#define __UNUSED __attribute__((unused))
//#endif

#define PROPERTY_FLAGS JSPROP_ENUMERATE | JSPROP_PERMANENT
#define FUNCTION_FLAGS JSPROP_READONLY | JSPROP_PERMANENT
#define JS_MUTABLE_FUNCTION_FLAGS JSPROP_PERMANENT




// Engine-agnosticizer

#define JSAG_OBJECT JS::RootedObject
#define JSAG_VALUE JS::Value

#define JSAG_BOOL bool
#define JSAG_FALSE false
#define JSAG_TRUE true

// Member definitions

#define JSAG_MEMBER_BEGIN_NOARGS(jsName) \
	static const int jsag_member_ ## jsName ## _argCount = 0; \
	static bool jsag_member_ ## jsName (JSContext *cx, unsigned argc, jsval *vp) { \

#define JSAG_MEMBER_END_NOARGS \
	return true; }

#define JSAG_MEMBER_BEGIN(jsName, minArgs) \
	static const int jsag_member_ ## jsName ## _argCount = minArgs; \
	static bool jsag_member_ ## jsName (JSContext *cx, unsigned argc, jsval *vp) { \
		static const char *JSAG_FN_NAME_STR = #jsName; { \
		if (unlikely(argc < minArgs)) { goto jsag_fail; } \
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp); \
		unsigned argsLeft = argc; \
		JSAutoRequest areq(cx);

// JS function arguments

#define JSAG_THIS \
	JS_THIS_OBJECT(cx, vp)

#define JSAG_ARG_SKIP \
	--argsLeft;

#define JSAG_ARG_JSVAL(cx, name) \
	JS::RootedValue name(cx, args[argc-argsLeft]); \
	--argsLeft;

#define JSAG_ARG_INT32(name) \
	int32_t name; \
  JS::RootedValue name##_rooted(cx, args[argc-argsLeft]); \
  if (unlikely(false == JS::ToInt32(cx, name##_rooted, &name))) { goto jsag_fail; } \
	--argsLeft;

#define JSAG_ARG_INT32_OPTIONAL(name, default) \
	int32_t name = default; \
  JS::RootedValue name##_rooted(cx, args[argc-argsLeft]); \
	if (argsLeft > 0) { \
    if (unlikely(false == JS::ToInt32(cx, name##_rooted, &name))) { goto jsag_fail; } \
		--argsLeft; \
	}

#define JSAG_ARG_JSTR(name) \
  JS::RootedValue name##_rooted(cx, args[argc-argsLeft]); \
	JS::RootedString name(cx, JS::ToString(cx, name##_rooted)); \
	if (unlikely(!name)) { goto jsag_fail; } \
	--argsLeft; \

#define JSAG_ARG_NSTR_OPTIONAL(name, default) \
	NSString *name = default; \
	if (argsLeft > 0) { \
		JS::RootedString name(cx, ## _jstr = JS_ValueToString(cx, args[argc-argsLeft])); \
		if (unlikely(!name)) { goto jsag_fail; } \
		--argsLeft; \
		JSTR_TO_NSTR(cx, name ## _jstr, name ## _tmp); \
		name = name ## _tmp; \
	}

#define JSAG_ARG_IS_STRING JSVAL_IS_STRING(args[argc-argsLeft])

#define JSAG_ARG_IS_ARRAY ( JSVAL_IS_OBJECT(args[argc-argsLeft]) && \
  JS_IsArrayObject(cx, JSVAL_TO_OBJECT(args[argc-argsLeft])) )

#define JSAG_ARG_CSTR(name) JSAG_ARG_JSTR(name##_jstr) \
  std::unique_ptr<char, JS::FreePolicy> h_##name (JS_EncodeStringToUTF8(cx, name##_jstr));\
  const char* name = h_##name.get();

#define JSAG_ARG_NSTR(name) JSAG_ARG_JSTR(name ## _jstr); JSTR_TO_NSTR(cx, name ## _jstr, name);

#define JSAG_ARG_CSTR_FIRST(name, count) \
	JSAG_ARG_JSTR(name ## _jstr); \
	char name[count] = {0}; \
	JS_EncodeStringToBuffer(cx, name ## _jstr, name, count);

#define JSAG_ARG_DOUBLE(name) \
  double name; \
  JS::RootedValue name##_rootedValue(cx, args[argc-argsLeft]); \
	if (unlikely(false == JS::ToNumber(cx, name##_rootedValue, &name))) { goto jsag_fail; } \
	--argsLeft;

#define JSAG_ARG_DOUBLE_OPTIONAL(name, default) \
	double name = default; \
  JS::RootedValue name##_rooted(cx, args[argc-argsLeft]); \
	if (argsLeft > 0) { \
		if (unlikely(false == JS::ToNumber(cx, name##_rooted, &name))) { goto jsag_fail; } \
		--argsLeft; \
	}

#define JSAG_ARG_OBJECT(name) \
	JS::RootedObject name(cx); \
	{ JS::RootedValue name ## _val(cx, args[argc-argsLeft]); \
		if (unlikely(JSVAL_IS_PRIMITIVE(name ## _val))) { goto jsag_fail; } \
		name = JSVAL_TO_OBJECT(name ## _val);\
	} --argsLeft;

// Will be NULL if not present
#define JSAG_ARG_OBJECT_OPTIONAL(name) \
	JS::RootedObject name(cx); \
	if (argsLeft > 0) { \
		JS::RootedValue name ## _val(cx, args[argc-argsLeft]); \
		if (unlikely(JSVAL_IS_PRIMITIVE(name ## _val))) { goto jsag_fail; } \
		--argsLeft; \
		name = JSVAL_TO_OBJECT(name ## _val);\
	}

#define JSAG_ARG_ARRAY(name) \
	JS::RootedObject name(cx); \
	{ JS::RootedValue name ## _val(cx, args[argc-argsLeft]); \
		if (unlikely(JSVAL_IS_PRIMITIVE(name ## _val))) { goto jsag_fail; } \
		name = JSVAL_TO_OBJECT(name ## _val);\
		if (unlikely(!JS_IsArrayObject(cx, name))) { goto jsag_fail; } \
	} --argsLeft;

#define JSAG_ARG_FUNCTION(name) \
	JS::RootedObject name(cx); \
	{ JS::RootedValue name ## _val(cx, args[argc-argsLeft]); \
		if (unlikely(JSVAL_IS_PRIMITIVE(name ## _val))) { goto jsag_fail; } \
		name = JSVAL_TO_OBJECT(name ## _val);\
		if (unlikely(!name || !JS_ObjectIsFunction(cx, name))) { goto jsag_fail; } \
	} --argsLeft;

#define JSAG_ARG_BOOL(name) \
  JS::RootedValue name##_rooted(cx, args[argc-argsLeft]); \
  bool name = JS::ToBoolean(name##_rooted); \
	--argsLeft;

#define JSAG_RETURN_INT32(name) \
  args.rval().set(INT_TO_JSVAL(name));

#define JSAG_RETURN_DOUBLE(name) \
  args.rval().set(DOUBLE_TO_JSVAL(name));

#define JSAG_RETURN_BOOL(name) \
  args.rval().set(BOOLEAN_TO_JSVAL(name));

#define JSAG_RETURN_TRUE \
  args.rval().setBoolean(true);

#define JSAG_RETURN_FALSE \
  args.rval().setBoolean(false);

#define JSAG_RETURN_CSTR(cstr) \
  args.rval().set(CSTR_TO_JSVAL(cx, cstr));

#define JSAG_RETURN_NSTR(nstr) \
  args.rval().set(NSTR_TO_JSVAL(cx, nstr));

#define JSAG_RETURN_NULL \
  args.rval().set(JSVAL_NULL);

#define JSAG_RETURN_VOID \
  args.rval().set(JSVAL_VOID);

#define JSAG_RETURN_OBJECT(obj) \
  args.rval().set(OBJECT_TO_JSVAL(obj));

#define JSAG_RETURN_JSVAL(val) \
  args.rval().set(val);

#define JSAG_MEMBER_END \
	return true; \
} \
jsag_fail: \
	JS_ReportError(cx, "Invalid arguments to %s", JSAG_FN_NAME_STR); \
	return false; \
}

// Class definition

#define JSAG_CLASS_FINALIZE(className, obj) \
	static void class_ ## className ## _finalizer(JSFreeOp *fop, JSObject *obj)

#define JSAG_CLASS_IMPL(name) \
	static const JSClass name ## _class = { \
		#name, JSCLASS_HAS_PRIVATE, \
		JS_PropertyStub, JS_DeletePropertyStub, JS_PropertyStub, JS_StrictPropertyStub, \
		JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, class_ ## name ## _finalizer, \
		JSCLASS_NO_OPTIONAL_MEMBERS \
	};

#define JSAG_CLASS_INSTANCE(name) \
	JS_NewObjectForConstructor(cx, (JSClass*)&name ## _class, vp);

#define JSAG_ADD_PROPERTY(obj, name, value) \
	JS_SetProperty(cx, obj, #name, value);

#define JSAG_GET_PRIVATE(name) \
	JS_GetPrivate(name)

#define JSAG_SET_PRIVATE(name, value) \
	JS_SetPrivate(name, value);

#define JSAG_CREATE_CLASS(obj, name) \
	JS_InitClass(cx, obj, NULL, (JSClass*)&name ## _class, jsag_member_ ## name, jsag_member_ ## name ## _argCount, NULL, (JSFunctionSpec*)jsag_ ## name ## _members, NULL, NULL);

// Object definition

#define JSAG_OBJECT_START(name) \
	static const JSFunctionSpec jsag_ ## name ## _members[] = {

#define JSAG_OBJECT_MEMBER(jsName) \
	JS_FN(#jsName, jsag_member_ ## jsName, jsag_member_ ## jsName ## _argCount, FUNCTION_FLAGS),

#define JSAG_MUTABLE_OBJECT_MEMBER(jsName) \
	JS_FN(#jsName, jsag_member_ ## jsName, jsag_member_ ## jsName ## _argCount, JS_MUTABLE_FUNCTION_FLAGS),

#define JSAG_OBJECT_MEMBER_NAMED(jsName, functionName) \
JS_FN(#jsName, jsag_member_ ## functionName, jsag_member_ ## functionName ## _argCount, FUNCTION_FLAGS),

#define JSAG_MUTABLE_OBJECT_MEMBER_NAMED(jsName, functionName) \
JS_FN(#jsName, jsag_member_ ## functionName, jsag_member_ ## functionName ## _argCount, JS_MUTABLE_FUNCTION_FLAGS),

#define JSAG_OBJECT_END \
	JS_FS_END };

#define JSAG_OBJECT_ATTACH(cx, parent, jsClassName) { \
    JS::RootedObject jsClassName ## _obj(cx, JS_NewObject(cx, nullptr, nullptr, nullptr)); \
		JS_DefineProperty(cx, parent, #jsClassName, JS::ObjectValue(*jsClassName ## _obj.get()), nullptr, nullptr, PROPERTY_FLAGS); \
		JS_DefineFunctions(cx, jsClassName ## _obj.get(),  (JSFunctionSpec*)jsag_ ## jsClassName ## _members); \
	}

#define JSAG_OBJECT_ATTACH_EXISTING(cx, parent, jsClassName, existingObject) { \
		JS_DefineProperty(cx, parent, #jsClassName, OBJECT_TO_JSVAL(existingObject), NULL, NULL, PROPERTY_FLAGS); \
		JS_DefineFunctions(cx, existingObject,  (JSFunctionSpec*)jsag_ ## jsClassName ## _members); \
	}


#endif

