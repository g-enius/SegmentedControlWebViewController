//
//  LDPMJSBridgeShareService.m
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/16.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "LDPMJSBridgeShareService.h"
#import <LDShare/LDShareManager.h>
#import <LDShare/LDSinaWeiboContentItem.h>
#import <LDShare/LDWechatContentItem.h>
#import <LDShare/LDWechatTimelineContentItem.h>
#import <LDShare/LDYixinContentItem.h>
#import <LDShare/LDYixinTimelineContentItem.h>
#import <LDShare/LDShareDefine.h>
#import "LDShareCircleContentItem.h"
#import "LDPMJSBridgeServiceDelegate.h"

@interface LDPMJSBridgeShareService ()

@property (nonatomic, copy) JsonRPCCallback pendingShareCallback;
@property (nonatomic, weak) id<LDPMJSBridgeServiceDelegate> delegate;

@end

@implementation LDPMJSBridgeShareService

- (void)share:(NSDictionary *)params Callback:(JsonRPCCallback)cb
{
    NSArray *contentArray = [self contentArrayFromShareParams:params];
    
    if ([[LDShareManager sharedInstance] checkContentIsValid:contentArray]) {
        [[LDShareManager sharedInstance] displayActivitySheetWithTitle:@"分享到" content:contentArray presentingViewController:[self.bridge viewController]];
        self.pendingShareCallback = cb;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareResultNotification:) name:LDShareMessageSendResultNotification object:nil];
    }
}

- (void)shareResultNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LDShareMessageSendResultNotification object:nil];
    if (self.pendingShareCallback) {
        self.pendingShareCallback(@{@"result":notification.userInfo[LDShareResultKey]});
        self.pendingShareCallback = nil;
    }
}

- (void)transShareData:(NSDictionary *)params Callback:(JsonRPCCallback)cb
{
    NSArray *contentArray = [self contentArrayFromShareParams:params];
    if ([[self.bridge viewController] respondsToSelector:@selector(bridgeService:didReceiveShareData:)]) {
        [(id<LDPMJSBridgeServiceDelegate>)[self.bridge viewController] bridgeService:self didReceiveShareData:contentArray];
        cb(@{@"result":@"0"});
    } else {
        cb(@{@"result":@"1"});
    }
}

- (void)toggleShareButton:(NSDictionary *)params Callback:(JsonRPCCallback)cb
{
    BOOL show = ([params[@"show"] integerValue] == 1);
    if ([[self.bridge viewController] respondsToSelector:@selector(bridgeService:didChangeShareButtonShow:)]) {
        [(id<LDPMJSBridgeServiceDelegate>)[self.bridge viewController] bridgeService:self didChangeShareButtonShow:show];
        cb(@{@"result":@"0"});
    } else {
        cb(@{@"result":@"1"});
    }
}

- (NSArray *)contentArrayFromShareParams:(NSDictionary *)params
{
    NSMutableArray *contentArray = [NSMutableArray array];
    LDPMJSShareChannel channel = [params[@"channel"] integerValue];
    NSString *url = params[@"url"];
    NSString *title = params[@"shareTitle"];
    NSString *content = params[@"content"];
    NSString *imageUrl = params[@"imageUrl"];
    if (channel == 0 || channel & LDPMJSShareChannelCircle) {
        LDShareCircleContentItem *circleItem = [LDShareCircleContentItem new];
        circleItem.text = content;
        [contentArray addObject:circleItem];
    }
    if (channel == 0 || channel & LDPMJSShareChannelWeibo) {
        NSString *weiboContent = params[@"weiboContent"];
        NSString *weiboImageUrl = params[@"weiboImageUrl"];
        LDSinaWeiboContentItem *weiboItem = [LDSinaWeiboContentItem new];
        weiboItem.text = weiboContent? : content;
        weiboItem.imageUrl = weiboImageUrl? : imageUrl;
        weiboItem.redirectURI = @"http://fa.163.com";
        [contentArray addObject:weiboItem];
    }
    if (channel == 0 || channel & LDPMJSShareChannelWechat) {
        LDWechatContentItem *wechatItem = [LDWechatContentItem new];
        wechatItem.title = title;
        wechatItem.LDDescription = content;
        wechatItem.imageUrl = imageUrl;
        wechatItem.webpageUrl = url;
        [contentArray addObject:wechatItem];
    }
    if (channel == 0 || channel & LDPMJSShareChannelWechatTimeline) {
        LDWechatTimelineContentItem *wechatTimeLineItem = [LDWechatTimelineContentItem new];
        wechatTimeLineItem.title = title;
        wechatTimeLineItem.LDDescription = content;
        wechatTimeLineItem.imageUrl = imageUrl;
        wechatTimeLineItem.webpageUrl = url;
        [contentArray addObject:wechatTimeLineItem];
    }
    if (channel == 0 || channel & LDPMJSShareChannelYixin) {
        LDYixinContentItem *yixinItem = [LDYixinContentItem new];
        yixinItem.title = title;
        yixinItem.LDDescription = content;
        yixinItem.imageUrl = imageUrl;
        yixinItem.webpageUrl = url;
        [contentArray addObject:yixinItem];
    }
    if (channel == 0 || channel & LDPMJSShareChannelYixinTimeline) {
        LDYixinTimelineContentItem *yixinTimelineItem = [LDYixinTimelineContentItem new];
        yixinTimelineItem.title = title;
        yixinTimelineItem.LDDescription = content;
        yixinTimelineItem.imageUrl = imageUrl;
        yixinTimelineItem.webpageUrl = url;
        [contentArray addObject:yixinTimelineItem];
    }
    return contentArray;
}

@end
