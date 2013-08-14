//
//  AppDelegate.m
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "AppDelegate.h"
#import "GAI.h"

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"CLEAR_CACHE_ON_START"] boolValue]) {
        NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDir error:nil];
        NSLog(@"Clearing Cache At: %@ (%@)", documentsDir, files);
        for (NSString *file in files) {
            [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"CLEAR_CACHE_ON_START"];
        [defaults synchronize];
    }
    self.server = [[WebServer alloc] init];
    self.reachability = [Reachability reachabilityForLocalWiFi];
    [self.reachability startNotifier];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
    
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [GAI sharedInstance].debug = NO;
    //Debugging ID
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-42637180-1"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (self.server.running==YES) {
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Terminating App");
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)networkStatusChanged:(NSNotification *)notification {
    if (((Reachability *)notification.object).currentReachabilityStatus==ReachableViaWiFi) {
        if (self.server.running==NO) {
            [self.server start];
        }
    } else {
        if (self.server.running==YES) {
            [self.server stop];
        }
    }
}

@end
