//
//  ViewController.m
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "MusicLibrary.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "Reachability.h"

@interface ViewController ()

- (void) animateHeaderPosition;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.trackedViewName = @"Main Screen";
    float width = UIScreen.mainScreen.bounds.size.width;
    float height = UIScreen.mainScreen.bounds.size.height;
    if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        float temp = width;
        width = height;
        height = temp;
    }
    self.headingVerticalSpace.constant = height/2 - 50;
    NSArray *buttons = [NSArray arrayWithObjects:self.rateButton, self.followButton, self.contactButton, self.clearCacheButton, nil];
    for (UIButton *button in buttons) {
        button.layer.borderColor = UIColor.whiteColor.CGColor;
        button.layer.borderWidth = 0.5;
        button.layer.cornerRadius = 5;
    }
    [UIView animateWithDuration:1.0 animations:^{
        self.subheading.alpha = 0;
    } completion:^(BOOL finished) {
        [self animateHeaderPosition];
    }];
}

- (void) animateHeaderPosition {
    [UIView animateWithDuration:1.5 animations:^{
        self.headingVerticalSpace.constant = 20;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.subheading.text = @"The server is off. You need to be on a WiFi network so that other devices can connect.";
        AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        self.server = delegate.server;
        self.server.delegate = self;
        if (delegate.reachability.currentReachabilityStatus==ReachableViaWiFi) {
            [self.server start];
        }
        self.subheadingHeight.constant = 60;
        self.subheadingVerticalSpace.constant = 40;
        self.tableView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1];
        [UIView animateWithDuration:1.0 animations:^{
            self.subheading.alpha = 1.0;
            self.tableView.alpha = 1.0;
            self.moreInfoView.alpha = 1.0;
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_headingVerticalSpace release];
    [_heading release];
    [_subheading release];
    [_subheadingHeight release];
    [_subheadingVerticalSpace release];
    [_tableView release];
    [_server release];
    [_moreInfoView release];
    [_scrollView release];
    [_mainView release];
    [_aboutLabel release];
    [_followButton release];
    [_rateButton release];
    [_adBannerVerticalSpace release];
    [_contactButton release];
    [_clearCacheButton release];
    [_scrollViewContentOffset release];
    [_adBannerHeight release];
    [super dealloc];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CONNECTIONS_TABLE"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CONNECTIONS_TABLE"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    if (self.server.sessionNames.count==0) {
        cell.textLabel.text = @"No Clients Connected";
    } else {
        cell.textLabel.text = [self.server.sessionNames.allValues objectAtIndex:indexPath.row];
    }
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.server.sessionNames.count==0) {
        return 1;
    }
    return self.server.sessionNames.count;
}

- (IBAction)showMoreInfo:(id)sender {
    float width = UIScreen.mainScreen.bounds.size.width;
    float height = UIScreen.mainScreen.bounds.size.height;
    if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        float temp = width;
        width = height;
        height = temp;
    }
    [UIView animateWithDuration:0.4 animations:^{
        self.scrollViewContentOffset.constant = -width;
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)showHomeScreen:(id)sender {
    [UIView animateWithDuration:0.4 animations:^{
        self.scrollViewContentOffset.constant = 0;
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)rate:(id)sender {
    //Launch VC
    /*SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    
    storeViewController.delegate = self;
    
    NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier:[NSNumber numberWithInteger:687568996]};
    
    [storeViewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError *error) {
        if (result) {
            [self presentViewController:storeViewController animated:YES completion:nil];
        }
    }];*/
    NSURL *url = [NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=687568996"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"APP_RATED"];
        [defaults synchronize];
        [self unlockPurchase:DisableAdsReasonAppRate];
    }
}

- (IBAction)follow:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted && !error) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            if ([accountsArray count] > 0) {
                NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"];
                NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"remotemusicapp", @"screen_name",
                                            @"true", @"follow",
                                            nil];
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:URL parameters:parameters];
                request.account = [accountsArray objectAtIndex:0];
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (responseData==nil || error!=nil) {
                        return;
                    }
                    NSError *jsonError = nil;
                    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                    if (result) {
                        BOOL following = [[result objectForKey:@"following"] boolValue];
                        if (following) {
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"TWITTER_FOLLOWED"];
                            [defaults synchronize];
                            [self unlockPurchase:DisableAdsReasonTwitterFollow];
                        }
                    }
                }];
            }
        } else {
            NSArray *urls = [NSArray arrayWithObjects:
                             @"twitter://user?screen_name=remotemusicapp",
                             @"http://twitter.com/remotemusicapp",
                             nil];
            
            UIApplication *application = [UIApplication sharedApplication];
            
            for (NSString *candidate in urls) {
                NSURL *url = [NSURL URLWithString:candidate];
                if ([application canOpenURL:url]) {
                    [application openURL:url];
                    return;
                }
            }
        }
    }];
}

- (IBAction)contact:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeView = [[MFMailComposeViewController alloc] init];
        mailComposeView.mailComposeDelegate = self;
        [mailComposeView setSubject:@"Remote Music Feedback"];
        [mailComposeView setToRecipients:[NSArray arrayWithObject:@"remotemusic@feistapps.com"]];
        [self presentViewController:mailComposeView animated:YES completion:nil];
        [mailComposeView release];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Send Mail" message:@"Sending mail is not supported from your device. You can contact me at remotemusic@feistapps.com." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (IBAction)clearCache:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"CLEAR_CACHE_ON_START"];
    [defaults synchronize];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cache Reset Scheduled" message:@"Your cache will automatically be emptied the next time you start Remote Music." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void) unlockPurchase:(DisableAdsReason)reason {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ADS_DISABLED"] boolValue]==YES) {
        return;
    }
    NSString *message = nil;
    NSString *title = nil;
    if (reason==DisableAdsReasonAppRate) {
        message = @"By giving us a good rating, you help spread the wonder of Remote Music to others and show that you care about us. To show that we care about you, all ads in Remote Music will be disabled from now on.";
        title = @"Thanks for Rating!";
    } else if (reason==DisableAdsReasonTwitterFollow) {
        message = @"By following us on twitter, you help spread the wonder of Remote Music to others and show that you care about us. To show that we care about you, all ads in Remote Music will be disabled from now on.";
        title = @"Thanks for Following!";
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"ADS_DISABLED"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    [alert release];
    [self hideAds];
}

- (void) hideAds {
    [UIView animateWithDuration:1.0 animations:^{
        self.adBannerVerticalSpace.constant = -self.adBannerHeight.constant;
        [self.view layoutIfNeeded];
    }];
}

- (void) showAds {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ADS_DISABLED"] boolValue]!=YES) {
        [UIView animateWithDuration:1.0 animations:^{
            self.adBannerVerticalSpace.constant = 0;
            [self.view layoutIfNeeded];
        }];
    } else {
        [self hideAds];
    }
}

#pragma mark - WebServerDelegate

- (void) webServerDidStart:(WebServer *)server {
    NSLog(@"Web Server Started");
    self.subheading.text = [NSString stringWithFormat:@"The server is on. Please type the following in your computer's web-browser: \n http://%@:80", self.server.getServerIP];
}

- (void) webServerDidStop:(WebServer *)server {
    NSLog(@"Web Server Stopped");
    self.subheading.text = @"The server is off. You need to be on a WiFi network so that other devices can connect.";
}

- (void) webServerFailedToStart:(WebServer *)server {
    NSLog(@"Web Server Failed to Start");
    self.subheading.text = @"There was an error initializing the server. If you keep getting this message, this issue will be resolved in a future update.";
}

- (void) webServerRequestingToConnect:(WebServer *)server withClientName:(NSString *)name {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Accept Connection?" message:[NSString stringWithFormat:@"Is it okay if %@ connects and accesses your music library?", name] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
    [alert release];
    [self.tableView reloadData];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==alertView.cancelButtonIndex) {
        for (NSString *key in self.server.musicLibraries.allKeys) {
            MusicLibrary *library = [self.server.musicLibraries objectForKey:key];
            if (library.active==NO) {
                [self.server.sessionNames removeObjectForKey:key];
                [self.server.musicLibraries removeObjectForKey:key];
                break;
            }
        }
    } else {
        for (MusicLibrary *library in self.server.musicLibraries.allValues) {
            if (library.active==NO) {
                library.active=YES;
                break;
            }
        
        }
    }
    [self.tableView reloadData];
}

#pragma mark - AdBannerViewDelegate

- (void) bannerViewDidLoadAd:(ADBannerView *)banner {
    NSLog(@"Loaded Ads");
    self.adBannerHeight.constant = banner.frame.size.height;
    [self showAds];
}

- (void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"Error Loading Ads: %@", error.description);
    [self hideAds];
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void) productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
