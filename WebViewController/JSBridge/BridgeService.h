//
//  BridgeService.h
//  yixin_iphone
//
//  Created by Xuhui on 13-11-17.
//  Copyright (c) 2013年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSBridgeDefine.h"

@protocol LDPMJSBridge <NSObject>

- (UIWebView *)webView;
- (UIViewController *)viewController;

@end

@interface BridgeService : NSObject

@property (weak, nonatomic) id<LDPMJSBridge> bridge;
@property (assign, nonatomic) BOOL isReady;

- (void)serviceInitialize;
- (void)stopService;

- (void)onConnect:(NSNotification*)notification;
- (void)onClose:(NSNotification*)notification;
- (void)onWebViewFinishLoad:(NSNotification*)notification;

- (NSDictionary *)generateErrorMessage:(NSString *)message;
- (NSDictionary *)generateSuccessMessage:(NSDictionary *)message;

@end
