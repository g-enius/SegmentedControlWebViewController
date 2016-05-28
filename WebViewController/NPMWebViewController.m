//
//  NPMWebViewController.m
//  PreciousMetals
//
//  Created by ypchen on 10/28/14.
//  Copyright (c) 2014 NetEase. All rights reserved.
//

#import "NPMWebViewController.h"
#import "LDPMWebViewShareData.h"
#import <LDShare/LDShareManager.h>
#import <LDShare/LDSinaWeiboContentItem.h>
#import <LDShare/LDWechatContentItem.h>
#import <LDShare/LDWechatTimelineContentItem.h>
#import <LDShare/LDYixinContentItem.h>
#import <LDShare/LDYixinTimelineContentItem.h>
#import <LDShare/LDShareDefine.h>
#import "LDPMJSBridgeServiceDelegate.h"
#import "LDPMUserEvent.h"
#import "MSWeakTimer.h"

@interface NPMWebViewController () <LDPMJSBridgeServiceDelegate>

@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *closeButton;

@property (nonatomic, strong) NSArray *shareContentArrayFromWeb;
@property (nonatomic, strong) UIBarButtonItem *shareButton;

@end

@implementation NPMWebViewController

#pragma mark - View Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateNaviLeftButtton];
    [self showShareButton:(_shareItem != nil)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareResultNotification:) name:LDShareMessageSendResultNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LDShareMessageSendResultNotification object:nil];
}

- (void)updateNaviLeftButtton
{
    NSMutableArray *itemsArray = [NSMutableArray array];
    [itemsArray addObject:self.backButton];
    if ([self.webView canGoBack]) {
        [itemsArray addObject:self.closeButton];
    }
    
    [self.navigationItem setLeftBarButtonItems:itemsArray];
}


#pragma mark - Setters & Getters

- (UIBarButtonItem *)backButton
{
    if (!_backButton) {
        UIButton *button = [NPMUIFactory naviBackButtonWithTarget:self selector:@selector(backButtonPressed:)];
        button.width = 30;
        _backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _backButton;
}

- (UIBarButtonItem *)closeButton
{
    if (!_closeButton) {
        _closeButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonPressed:)];
    }
    return _closeButton;
}

- (UIBarButtonItem *)shareButton
{
    if (!_shareButton) {
        UIButton *navButton = [NPMUIFactory naviButtonWithTitle:@"分享" target:self selector:@selector(shareButtonPressed:)];
        [navButton setTitleColor:[NPMColor whiteTextColor] forState:UIControlStateNormal];
        _shareButton = [[UIBarButtonItem alloc] initWithCustomView:navButton];
    }
    return _shareButton;
}



#pragma mark -

#pragma mark - Actions

- (void)backButtonPressed:(UIButton *)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self closeButtonPressed:nil];
    }
}

- (void)closeButtonPressed:(UIButton *)sender
{
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)shareButtonPressed:(id)sender
{
    NSArray *shareContentArray = self.shareContentArrayFromWeb;
    
    if (!shareContentArray) {
        UIImage *shareImage = [UIImage imageNamed:@"appIcon"];
        
        LDSinaWeiboContentItem *weiboItem = [LDSinaWeiboContentItem new];
        weiboItem.image = shareImage;
        weiboItem.text = [NSString stringWithFormat:@"分享《%@》%@", self.shareItem.title, self.shareItem.url];
        weiboItem.redirectURI = @"http://fa.163.com";
        
        
        LDWechatContentItem *wechatItem = [LDWechatContentItem new];
        wechatItem.title = self.shareItem.title;
        wechatItem.webpageUrl = self.shareItem.url;
        wechatItem.LDDescription = self.shareItem.content?:self.shareItem.title;
        wechatItem.image = shareImage;
        
        LDWechatTimelineContentItem *wechatTimelineItem = [LDWechatTimelineContentItem new];
        wechatTimelineItem.title = self.shareItem.title;
        wechatTimelineItem.webpageUrl = self.shareItem.url;
        wechatTimelineItem.LDDescription = self.shareItem.content?:self.shareItem.title;
        wechatTimelineItem.image = shareImage;
        
        LDYixinContentItem *yixinItem = [LDYixinContentItem new];
        yixinItem.title = self.shareItem.title;
        yixinItem.webpageUrl = self.shareItem.url;
        yixinItem.LDDescription = self.shareItem.content?:self.shareItem.title;
        yixinItem.image = shareImage;
        
        LDYixinTimelineContentItem *yixinTimelineItem = [LDYixinTimelineContentItem new];
        yixinTimelineItem.title = self.shareItem.title;
        yixinTimelineItem.webpageUrl = self.shareItem.url;
        yixinTimelineItem.LDDescription = self.shareItem.content?:self.shareItem.title;
        yixinTimelineItem.image = shareImage;
        
        shareContentArray = @[weiboItem, wechatItem, wechatTimelineItem, yixinItem, yixinTimelineItem];
    }
    
    if ([[LDShareManager sharedInstance] checkContentIsValid:shareContentArray]) {
        [[LDShareManager sharedInstance] displayActivitySheetWithTitle:@"分享到" content:shareContentArray presentingViewController:self];
        if (self.shareContentArrayFromWeb) {
            [LDPMUserEvent addEvent:EVENT_SHARE tag:@"活动"];// 活动分享统计
        } else {
            [LDPMUserEvent addEvent:EVENT_SHARE tag:@"资讯"];
        }
    }
}

#pragma mark - Notifications

- (void)shareResultNotification:(NSNotification *)notification
{
    NSInteger result = [notification.userInfo[LDShareResultKey] integerValue];
    if (result == LDShareMessageSendResultSent) {
        [self showToast:@"分享成功"];
    } else if (result == LDShareMessageSendResultCancelled) {
        [self showToast:@"分享取消"];
    } else {
        [self showToast:@"分享失败"];
    }
}

#pragma mark - private

- (UINavigationController *)parentNavigationController
{
    UINavigationController *navController = self.navigationController;
    if (!navController) {
        navController = [[UINavigationController alloc]initWithRootViewController:self];
    }
    return navController;
}

- (void)showShareButton:(BOOL)show
{
    self.navigationItem.rightBarButtonItem = show? self.shareButton : nil;
}

#pragma mark - LDPMJSBridgeServiceDelegate

- (void)bridgeService:(BridgeService *)service didReceiveShareData:(NSArray *)contentArray
{
    self.shareContentArrayFromWeb = contentArray;
}

- (void)bridgeService:(BridgeService *)service didChangeShareButtonShow:(BOOL)show
{
    [self showShareButton:show];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.shareContentArrayFromWeb) {
        self.shareContentArrayFromWeb = nil;
        [self showShareButton:NO];
    }
    
    [super webViewDidFinishLoad:webView];
    
    if (!self.forceLocalTitle) {
        NSString *titleStr = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];

        if (titleStr) {
            self.title = titleStr;
        }
    }
    
    [self updateNaviLeftButtton];
}

#pragma mark - 常驻页面统计

- (NSString *)pageEventParam
{
    return EMPTY_STRING_IF_NIL(self.title);
}


@end
