//
//  LDPMJSBridgeNavigationService.m
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/9.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "LDPMJSBridgeNavigationService.h"
#import "NPMPhotoBrowserViewController.h"
#import "NPMLoginViewController.h"
#import "UserSession.h"
#import "LDPMWebLoginStatusService.h"
#import "JLRoutes.h"

// 使用者请注意, 此service中与登录相关的代码皆为兼容老版本, 是不推荐的用法
@interface LDPMJSBridgeNavigationService ()

@property (nonatomic, copy) JsonRPCCallback pendingLoginCallback;

@end

@implementation LDPMJSBridgeNavigationService

- (void)openViewController:(NSDictionary *)params Callback:(JsonRPCCallback)cb
{
    NSString *name = params[@"name"];
    NSDictionary *options = params[@"options"];
    
    if ([name isEqualToString:@"ntesfa://showWebPics"]) { //不推荐的用法, 以后请勿再使用
        NSMutableArray *images = [NSMutableArray array];
        
        for (NSString *urlString in options[@"pictures"]) {
            NSURL *url = [NSURL URLWithString:urlString];
            
            if (url) {
                [images addObject:[MWPhoto photoWithURL:url]];
            }
        }
        
        NPMPhotoBrowserViewController *browser = [[NPMPhotoBrowserViewController alloc] initWithImages:images];
        [browser setCurrentPhotoIndex:[options[@"index"] integerValue]];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
        [[self.bridge viewController] presentViewController:nc animated:YES completion:nil];
    } else if ([name isEqualToString:@"ntesfa://login"]) { //不推荐的用法, 以后请勿再使用
        NPMLoginViewController *loginViewController = [NPMLoginViewController createViewController];
        
        [loginViewController setCompletionBlock:(LoginCompletionBlock) ^ (NSInteger code, NSError * error) {
            if (code == 1) { //登录成功, 执行exchange操作, exchange的js回调方法调用exchangeLoginStatusFinished, 完成回调
                self.pendingLoginCallback = cb;
                [LDPMWebLoginStatusService exchangeLoginStatusAfterLoginInWebView:[self.bridge webView]];
            } else { // 登录失败, 直接回调
                cb(@{@"loginStatus":@(code)});
            }
        }];
        UINavigationController *naviViewController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [[self.bridge viewController] presentViewController:naviViewController animated:YES completion:nil];
    } else {
        [JLRoutes routeURL:[NSURL URLWithString:name]];
    }
}

- (void)exchangeLoginStatusFinished:(NSDictionary *)params Callback:(JsonRPCCallback)cb
{
    NSDictionary *result = @{@"loginStatus":[NSNumber numberWithBool:[[UserSession sharedSession] hasLogin]]};
    self.pendingLoginCallback(result);
    self.pendingLoginCallback = nil;
}

@end
