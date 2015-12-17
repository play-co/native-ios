/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 *
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 *
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#pragma once

#ifdef __GNUC__
#  ifdef __cplusplus
#    define TL_EXPORT extern "C" __attribute__( (visibility ("default")) )
#  else
#    define TL_EXPORT __attribute__( (visibility ("default")) )
#  endif
#else
#  ifdef __cplusplus
#    define TL_EXPORT extern "C"
#  else
#    define TL_EXPORT
#  endif
#  warning "Unknown compiler, all external linkage symbols will be visibile"
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

typedef struct app tl_app_t;
typedef struct tealeaf tealeaf_t;

// Input events
enum tl_input_type {
    TL_INPUT_EVENT_START = 1,
    TL_INPUT_EVENT_MOVE,
    TL_INPUT_EVENT_SELECT,
    TL_INPUT_EVENT_SCROLL,
    TL_INPUT_EVENT_CLEAR,
};

/* Found in core/core.c */
tealeaf_t *tl_init(const char *entry_point,
                   const char *tcp_host,
                   const char *code_host,
                   int tcp_port,
                   int code_port,
                   const char *source_dir,
                   bool remote_loading,
                   const char *simulate_id);
int tl_init_gl(tealeaf_t *tl, int framebuffer_name, int tex_name);
void tl_shutdown(tealeaf_t *tl);
void tl_shutdown_gl(tealeaf_t *tl);

void tl_viewport_resize(tealeaf_t *tl, int width, int height);
int tl_tick(tealeaf_t *tl, long dt);

/**
 * Dispatch touch / mouse events to the engine. The active application will
 * receive the events.
 *
 * @param tl - The engine
 * @param id - Touch index
 * @param type - Input type
 * @param x - Y-position in device pixels
 * @param y - X-position in device pixels
 */
void tl_dispatch_input_event(tealeaf_t *tl, int id, enum tl_input_type type,
        int x, int y);

// -----------------------------------------------------------------------------
// Error Handling
//
// The `tl_errno` type will be returned from certain methods and passed as part
// of a callback signature for some asynchronous methods. To retrieve a
// description of the error, call `tl_strerror`.
// -----------------------------------------------------------------------------

typedef enum tealeaf_error_numbers {
    TEALEAFE_OK = 0,
    TEALEAFE_UNPACK = 1,
    TEALEAFE_NETWORK = 2
} tl_errno;

/**
 * Get a string description for the given error
 *
 * @param err the error number
 * @return error description string
 */

const char *tl_strerror(tl_errno err);

// -----------------------------------------------------------------------------
// Application Management
// -----------------------------------------------------------------------------

/**
 * Generic callback type for app APIs
 */
typedef void (*tl_app_callback)(tl_app_t *app, tl_errno err, void *extra);

void tl_app_load_async(tl_app_t *app, tl_app_callback cb, void *ptr);

void tl_app_run(tl_app_t *app);
bool tl_app_pop(tealeaf_t *tealeaf);
tl_errno tl_app_load(tl_app_t *app);
void tl_app_stop(tl_app_t *app);

/**
 * When using the tl_app_from_options api an app origin is specified in the
 * options.
 */
enum tl_app_origin {
    // We will guess (poorly) where the app originates from based on the URL.
    TL_APP_ORIGIN_GUESS = 0,

    // Do not load an application. This is typically only used by the shell and
    // engine tests.
    TL_APP_ORIGIN_NONE,

    // App is in a local zip like /tmp/files/app.zip
    TL_APP_ORIGIN_LOCAL_PACKED,

    // App is unpacked to a local location like /tmp/files/app
    TL_APP_ORIGIN_LOCAL_UNPACKED,

    // UNSUPPORTED
    // Zipped app is located in .ipa or .apk assets folder
    TL_APP_ORIGIN_LOCAL_ASSETS_PACKED,

    // Unzipped app is located in .ipa or .apk assets folder
    TL_APP_ORIGIN_LOCAL_ASSETS_UNPACKED,

    // Zipped app is available from an http(s) location
    TL_APP_ORIGIN_NETWORK_PACKED,

    // UNSUPPORTED
    // Unzipped app is available from an http(s) location. In this case, some
    // sort of manifest will need to be available to fetch all the files.
    TL_APP_ORIGIN_NETWORK_UNPACKED,
};

typedef void(*tl_app_progress_func)(void *app, double loaded, double total);

/**
 * options struct passed to tl_app_from_options
 */
struct tl_app_options {
    enum tl_app_origin origin;
    const char *url;
    const char *name;
    const char *splash;

    // The progress_func will be called during bundle download
    tl_app_progress_func progress_func;
    void *progress_data;
};

/**
 * Initialize a new application using the provided options
 *
 * Example:
 *
 *     struct tl_app_options opts;
 *     opts.url = "http://example.com/app.zip";
 *     opts.origin = TL_APP_ORIGIN_NETWORK_PACKED;
 *     opts.name = "My Application";
 *     opts.splash = "resources/splash.png";
 *
 *     // `tealeaf` is obtained from `tl_init`
 *     tl_app_t *app = tl_app_from_options(tealeaf, &opts);
 *
 * @param tealeaf - instance of the engine
 * @param opts - options to initialize the new app
 * @returns tl_app_t*
 */

tl_app_t*
tl_app_from_options(tealeaf_t *tealeaf, const struct tl_app_options *opts);

/**
 * Destroy an application
 *
 * The application's scripting environment will be reclaimed, and other
 * resources owned by the application will be freed. The application must not be
 * running when tl_app_destroy is called.
 *
 * @param app - the application to destroy
 * @return 0 on success or -1 on failure
 */

int tl_app_destroy(tl_app_t *app);

/**
 * Read contents of `path` and evaluate withen context of app.
 *
 * @param app - javascript is evaluated in this context
 * @param path - contents of file will be passed to tl_app_eval
 */

int tl_app_eval_file(tl_app_t *app, const char* path);

/**
 * Run some JavaScript in the context of the given application.
 *
 * @param app - javascript is evaluated in this context.
 * @param filename - Name used for evaluation
 * @param javascript - the UTF8 script bytes to evaluate.
 * @param bytes - number of bytes in javascript.
 */

int tl_app_eval(tl_app_t *app, const char *filename, const char *javascript,
        size_t bytes);

/* found in core/app.c */
tl_app_t* tl_app_get(tealeaf_t *tl, const char *name);

/**
 * Initialize an application using name and url
 *
 * @deprecated
 * @param tl the tealeaf engine
 * @param name string name for app
 * @param url bundle/archive url
 * @return tl_app_t*
 */

tl_app_t* tl_app_init(tealeaf_t *tl, const char *name, const char *url);

tl_app_t* tl_get_active_app(tealeaf_t *tl);

void tl_app_event_push(tl_app_t *app, const char *event);

// You need to free the result of this function after you are done with it
char * tl_app_event_pop(tl_app_t *app);

void tl_app_pause(tl_app_t *app);
void tl_app_resume(tl_app_t *app);

/**
 * Set the splash image for an app
 */
void tl_app_set_splash(tl_app_t *app, const char *url);

// passed as the last argument to tl_app_run.
typedef enum {
  TL_RUN_DEFAULT = 0,
  TL_RUN_ONCE,
  TL_RUN_NOWAIT
} tl_run_mode;

// Run the event loop for app. Nonzero if the loop still has active handles.
int tl_run_loop(tl_app_t *app, tl_run_mode mode);

/**
 * Events that embedders may subscribe to
 */

enum tl_event {
    TL_EVENT_SPLASH_SHOW,
    TL_EVENT_GAME_READY
};

/**
 * Engine event callback
 */

typedef void (*tl_event_callback)(tl_app_t *app, void *extra);

/**
 * Subscribe to engine events
 *
 * @return int32_t the event id
 */

int tl_subscribe(tealeaf_t *, enum tl_event, tl_event_callback, void *);

/**
 * Remove an event subscription
 */

void tl_unsubscribe(tealeaf_t *tl, int id);


#ifdef __cplusplus
}
#endif // __cplusplus
