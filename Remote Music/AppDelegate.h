//
//  AppDelegate.h
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebServer.h"
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UIBackgroundTaskIdentifier bgTask;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) WebServer *server;
@property (strong, nonatomic) Reachability *reachability;

- (void) networkStatusChanged;

@end
