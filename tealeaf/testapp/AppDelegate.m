//
//  AppDelegate.m
//  js.io Companion
//
//  Created by Joe Wilm on 9/14/15.
//  Copyright (c) 2015 Weeby.co. All rights reserved.
//

#import "AppDelegate.h"

#include "tealeaf.h"

@interface AppDelegate () {
    tl_app_t *app;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.gameViewController = [[GameViewController alloc] init];
    [self.window addSubview:self.gameViewController.view];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    self.window.rootViewController = self.gameViewController;
    
    struct tl_app_options opts;
    opts.name = "";
    opts.splash = NULL;
    opts.url = "";
    opts.origin = TL_APP_ORIGIN_LOCAL_ASSETS_UNPACKED;
    
    tealeaf_t *tealeaf = [self.gameViewController getTealeaf];
    app = tl_app_from_options(tealeaf, &opts);
    
    [self startApp];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)backPressed:(UIButton*)sender {
    NSLog(@"got backPressed");
    [self.gameViewController onBackPressed];
}

- (void)playPressed:(UIButton*)sender {
    //    [self.gameViewController runAppByName:"gummies"];
}

- (void)startApp {
    [self.gameViewController loadApp:app];
    [self.gameViewController runApp:app];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive
    // state. This can occur for certain types of temporary interruptions (such
    // as an incoming phone call or SMS message) or when the user quits the
    // application and it begins the transition to the background state.  Use
    // this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.  If
    // your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive
    // state; here you can undo many of the changes made on entering the
    // background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if
    // appropriate. See also applicationDidEnterBackground:.
}


@end
