//
//  LDPMJSBridgeServiceDelegate.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/10/15.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BridgeService;

@protocol LDPMJSBridgeServiceDelegate <NSObject>

@optional

- (void)bridgeService:(BridgeService *)service didReceiveShareData:(NSArray *)contentArray;

- (void)bridgeService:(BridgeService *)service didChangeShareButtonShow:(BOOL)show;

@end
