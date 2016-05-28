//
//  LDPMWebLoginStatusService.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/10.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDPMWebLoginStatusService : NSObject

+ (BOOL)shouldExchangeLoginStatusForRequest:(NSURLRequest *)request;
+ (void)exchangeLoginStatusForURLRequest:(NSURLRequest *)request inWebView:(UIWebView *)webView;
+ (void)exchangeLoginStatusAfterLoginInWebView:(UIWebView *)webView;

@end
