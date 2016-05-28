//
//  LDPMBaseWebViewController.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LDPMBaseWebViewController : UIViewController

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *startupUrlString;

- (void)loadURL:(NSURL *)url;

//覆写已下方法，需要调用super方法
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)webViewDidStartLoad:(UIWebView *)webView;
- (void)webViewDidFinishLoad:(UIWebView *)webView;
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

@end
