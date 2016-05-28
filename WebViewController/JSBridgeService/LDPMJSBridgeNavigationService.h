//
//  LDPMJSBridgeNavigationService.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/9.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "BridgeService.h"

@interface LDPMJSBridgeNavigationService : BridgeService

- (void)openViewController:(NSDictionary *)params Callback:(JsonRPCCallback)cb;
- (void)exchangeLoginStatusFinished:(NSDictionary *)params Callback:(JsonRPCCallback)cb;

@end
