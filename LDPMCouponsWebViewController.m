//
//  LDPMSegmentWebViewController.m
//  PreciousMetals
//
//  Created by wangchao on 9/28/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "LDPMCouponsWebViewController.h"
#import "NPMTradeSession.h"
#import "JLRoutes.h"
#import "NPMLoginAction.h"
#import "ECLaunch.h"

@interface LDPMCouponsWebViewController ()

@property (assign, nonatomic) NSInteger defaultTabIndex;

@end

@implementation LDPMCouponsWebViewController

+ (void)load
{
    [self registerRoutes];
}

+ (void)registerRoutes
{
    [JLRoutes addRoute:@"/redpacket" handler:^(NSDictionary *parameters) {
        [NPMLoginAction loginWithSuccessBlock:^{
            LDPMCouponsWebViewController *messageEntranceViewController = [LDPMCouponsWebViewController new];
            if ([parameters[@"tab"] isEqual:@"coupon"]) {
                messageEntranceViewController.defaultTabIndex = 1;
            } else if ([parameters[@"tab"] isEqual:@"redpacket"]) {
                messageEntranceViewController.defaultTabIndex = 0;
            }
            messageEntranceViewController.hidesBottomBarWhenPushed = YES;
            [ECLaunch launchViewController:messageEntranceViewController];
        } andFailureBlock:nil];
        return YES;
    }];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //add segmentControl
    UISegmentedControl *titleSegment = [[UISegmentedControl alloc]initWithFrame:CGRectMake(0, 0, 120, 30)];
    titleSegment.tintColor = [UIColor colorWithRGB:0x134d8c];
    [titleSegment setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]} forState:UIControlStateSelected];
    [titleSegment setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRGB:0xa6abb3]} forState:UIControlStateNormal];
    [titleSegment insertSegmentWithTitle:@"红包" atIndex:0 animated:YES];
    [titleSegment insertSegmentWithTitle:@"免佣劵" atIndex:1 animated:YES];
    //titleSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    [titleSegment addTarget:self action:@selector(changeURL:) forControlEvents:UIControlEventValueChanged];
    titleSegment.selectedSegmentIndex = self.defaultTabIndex;
    self.navigationItem.titleView = titleSegment;
    
    [self changeURL:titleSegment];
}

- (void)changeURL: (UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self loadURL:[NSURL URLWithString:@"http://fa.163.com/t/account/mypackets.do"]];
            [LDPMUserEvent addEvent:EVENT_MINE_COUPON tag:@"红包"];
            break;
        case 1:
        {
            NSString *partnerID = [[NPMTradeSession sharedInstance] defaultOpenedPartnerId];
            partnerID = partnerID.length > 0 ? partnerID : NPMPartnerIDNanJiaoSuo;
            [self loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://fa.163.com/t/account/freecoupon/list/%@", partnerID]]];
            [LDPMUserEvent addEvent:EVENT_MINE_COUPON tag:@"免佣劵"];
        }
            break;
        default:
            break;
    }
}

@end
