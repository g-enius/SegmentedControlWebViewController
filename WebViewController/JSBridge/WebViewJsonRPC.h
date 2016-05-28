//
//  WebViewJsonRPC.h
//  WebViewJsonRPC
//
//  Created by Xuhui on 13-10-27.
//  Copyright (c) 2013年 Xuhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JSBridgeDefine.h"

typedef NS_ENUM(NSInteger, WebViewJsonRPCPermission)
{
    WebViewJsonRPCPermissionNormal        = 0,
    WebViewJsonRPCPermissionTrustedPay    = 1,
    WebViewJsonRPCPermissionOfficial      = 10
};

@class WebViewJsonRPC;

@protocol WebViewJsonRPCController <NSObject>

- (WebViewJsonRPCPermission)getPermission;
- (BOOL)isDebugMode;
- (UIViewController *)viewControllerForJSBridge:(WebViewJsonRPC *)bridge;

@optional
- (NSString *)debugChannel;
- (void)onHashChange;

@end


@interface WebViewJsonRPC : NSObject <UIWebViewDelegate>

@property (weak, nonatomic) UIWebView *webView;
@property (weak, nonatomic) id<WebViewJsonRPCController> controller;

/** [必须！]
 *  设置配置文件名带后缀，指定后缀为json。
 *  默认读取 MainBundle -> "ServiceConfig.json"
 */
+ (void)setConfigFileName:(NSString *)configFileName;

/** [必须！]
 *  设置JSApi文件名带后缀，指定后缀为txt。
 *  默认读取 MainBundle -> "JSApi.js.txt"
 */
+ (void)setJsApiFileName:(NSString *)jsApiFileName;

- (void)connectWebView:(UIWebView *)webView controller:(id<WebViewJsonRPCController>)controller;
- (void)close;
- (void)webReady;

- (UIViewController *)viewController;

@end
