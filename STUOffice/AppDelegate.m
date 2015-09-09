//
//  AppDelegate.m
//  STUOffice
//
//  Created by JunhaoWang on 8/30/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "AppDelegate.h"
#import "Define.h"
#import "MobClick.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Umeng
    [MobClick startWithAppkey:@"55e308f1e0f55a2812002610" reportPolicy:BATCH channelId:@"App Store"];
    
    // version标识
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick setAppVersion:version];
    
    
    // setting status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // setting nav bar background color
    [UINavigationBar appearance].barTintColor = COLOR_NAVBAR;
    
    // setting nav bar text style
    [UINavigationBar appearance].titleTextAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:19.0], NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    // setting nav bar item color
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    
    // setting backButton Icon
    UIImage *backBtnIcon = [UIImage imageNamed:@"toolbar-previous"];
    [UINavigationBar appearance].backIndicatorImage = backBtnIcon;
    [UINavigationBar appearance].backIndicatorTransitionMaskImage = backBtnIcon;
    
    [NSThread sleepForTimeInterval:0.8];
    
    [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
