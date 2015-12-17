//
//  GameViewController.h
//  SImpleGame
//
//  Created by Derek Burch on 11/7/14.
//  Copyright (c) 2014 Derek Burch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "tealeaf.h"

@interface GameViewController : GLKViewController

- (tl_app_t *) initApp:(const char *)name fromUrl:(const char *)url;
- (void) loadApp:(tl_app_t *)app;
- (void) runApp:(tl_app_t *)app;
- (void) runAppByName:(const char *)name;
- (void) stopAppByName:(const char *)name;
- (void) onBackPressed;
- (tealeaf_t*) getTealeaf;


@property (strong, nonatomic) EAGLContext *context;


@end
