//
//  LDPMWebLoginStatusService.m
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/10.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "LDPMWebLoginStatusService.h"
#import <CPFoundationCategory/NSString+Additions.h>
#import "UserSession.h"

@implementation LDPMWebLoginStatusService

+ (BOOL)shouldExchangeLoginStatusForRequest:(NSURLRequest *)request
{
    NSString *theURLString = request.URL.absoluteString;
    return ([theURLString rangeOfString:@".163.com"].length > 0) && ([theURLString rangeOfString:@"fa.163.com/t/redirectWapUrl.do"].length == 0);
}

+ (void)exchangeLoginStatusForURLRequest:(NSURLRequest *)request inWebView:(UIWebView *)webView
{
    NSString *originalURLString = request.URL.absoluteString;
    NSMutableString *exchangeURLString = [NSMutableString stringWithFormat:@"http://fa.163.com/t/redirectWapUrl.do?redirectUrl=%@", [originalURLString URLEncodedString]];
    if ([UserSession sharedSession].hasLogin) {
        [exchangeURLString appendFormat:@"&id=%@&token=%@", [UserSession sharedSession].loginID, [UserSession sharedSession].loginToken];
    }
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:exchangeURLString]]];
}

+ (void)exchangeLoginStatusAfterLoginInWebView:(UIWebView *)webView
{
    NSString *originalURLString = webView.request.URL.absoluteString;
    NSMutableString *exchangeURLString = [NSMutableString stringWithFormat:@"http://fa.163.com/t/redirectWapUrl.do?redirectUrl=%@&id=%@&token=%@", [originalURLString URLEncodedString], [UserSession sharedSession].loginID, [UserSession sharedSession].loginToken];
    NSString *js = [NSString stringWithFormat:@"var iframe = document.createElement('iframe'); iframe.id='__newsapp_loginredirect';iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);iframe.onload = iframe.onreadystatechange =function(){document.body.removeChild(iframe);mapp.account.exchangeLoginFinish();};",exchangeURLString];
    [webView stringByEvaluatingJavaScriptFromString:js];
}

@end
