//
//  LDPMJSBridgeShareService.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/16.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "BridgeService.h"

typedef NS_OPTIONS (NSInteger, LDPMJSShareChannel)
{
    LDPMJSShareChannelAll = 0,
    LDPMJSShareChannelCircle = 1 << 1,
    LDPMJSShareChannelWeibo = 1 << 2,
    LDPMJSShareChannelWechat = 1 << 3,
    LDPMJSShareChannelWechatTimeline = 1 << 4,
    LDPMJSShareChannelYixin = 1 << 5,
    LDPMJSShareChannelYixinTimeline = 1 << 6
};

@interface LDPMJSBridgeShareService : BridgeService

/**
 *  @param params channel:分享渠道 //无此值时调起所有渠道
 *             shareTitle:分享标题
 *                content:通用分享内容
 *                    url:通用跳转链接
 *               imageUrl:通用图片链接
 *           weiboContent:微博分享内容
 *          weiboImageUrl:微博图片链接
 *
 *  @param cb(result:0成功1失败2取消)
 */
- (void)share:(NSDictionary *)params Callback:(JsonRPCCallback)cb;

- (void)transShareData:(NSDictionary *)params Callback:(JsonRPCCallback)cb;

- (void)toggleShareButton:(NSDictionary *)params Callback:(JsonRPCCallback)cb;

@end
