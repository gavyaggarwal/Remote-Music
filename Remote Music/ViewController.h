//
//  ViewController.h
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "WebServer.h"
#import <StoreKit/StoreKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "GAITrackedViewController.h"

typedef enum {
    DisableAdsReasonAppRate,
    DisableAdsReasonTwitterFollow
} DisableAdsReason;

@interface ViewController : GAITrackedViewController <UITableViewDataSource, WebServerDelegate, UIAlertViewDelegate, ADBannerViewDelegate, SKStoreProductViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *headingVerticalSpace;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *subheadingHeight;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *subheadingVerticalSpace;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *adBannerVerticalSpace;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *adBannerHeight;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *scrollViewContentOffset;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIView *mainView;
@property (retain, nonatomic) IBOutlet UILabel *heading;
@property (retain, nonatomic) IBOutlet UILabel *subheading;
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIView *moreInfoView;
@property (retain, nonatomic) IBOutlet UILabel *aboutLabel;
@property (retain, nonatomic) IBOutlet UIButton *rateButton;
@property (retain, nonatomic) IBOutlet UIButton *followButton;
@property (retain, nonatomic) IBOutlet UIButton *contactButton;
@property (retain, nonatomic) IBOutlet UIButton *clearCacheButton;
@property (retain, nonatomic) WebServer *server;
- (IBAction)showMoreInfo:(id)sender;
- (IBAction)showHomeScreen:(id)sender;
- (IBAction)rate:(id)sender;
- (IBAction)follow:(id)sender;
- (IBAction)contact:(id)sender;
- (IBAction)clearCache:(id)sender;
- (void)unlockPurchase:(DisableAdsReason)reason;
- (void)showAds;
- (void)hideAds;

@end
