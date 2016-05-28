//
//  LDPMBaseWebViewController.m
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "LDPMBaseWebViewController.h"
#import "WebViewJsonRPC.h"
#import "LDPMWebLoginStatusService.h"
#import "LDRoutes.h"
#import "MSWeakTimer.h"

@interface LDPMBaseWebViewController () <UIWebViewDelegate, WebViewJsonRPCController>

@property (nonatomic, strong) WebViewJsonRPC *JSBridge;

@property (nonatomic, strong) NSURL *cachedURL;//缓存过早load的url

@property (nonatomic, assign) BOOL shouldExchangeLoginStatus;

@property (nonatomic, strong) UIView *loadFailView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) BOOL loadFinish;
@property (nonatomic, strong) MSWeakTimer *timer;

@property (nonatomic, strong) NSURL *currentUrl;

@end

@implementation LDPMBaseWebViewController

#pragma mark - View Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        [WebViewJsonRPC setJsApiFileName:@"LDPMJSApi.js.txt"];
        [WebViewJsonRPC setConfigFileName:@"ServiceConfig.json"];
        _shouldExchangeLoginStatus = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.webView.scalesPageToFit = YES;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    self.JSBridge = [[WebViewJsonRPC alloc] init];
    [self.JSBridge connectWebView:self.webView controller:self];
    
    if (self.cachedURL) {
        [self loadURL:self.cachedURL];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (_timer) {
        [self endTimer];
    }
    
    _webView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - URLs

- (void)loadURL:(NSURL *)url
{
    if (self.isViewLoaded) { //如果view已经被load, 直接打开url, 并清除url缓存. 否则缓存url, 待viewDidLoad最后调用
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        self.cachedURL = nil;
    }else{
        self.cachedURL = url;
    }
}

- (void)setStartupUrlString:(NSString *)startupUrlString
{
    [self loadURL:[NSURL URLWithString:startupUrlString]];
}

#pragma mark - WebViewJsonRPCController

- (WebViewJsonRPCPermission)getPermission
{
    return WebViewJsonRPCPermissionTrustedPay;
}

- (BOOL)isDebugMode
{
    return NO;
}

- (UIViewController *)viewControllerForJSBridge:(WebViewJsonRPC *)bridge
{
    return self;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //应用内链接使用JLRoutes处理
    NSURL *URL = request.URL;
    self.currentUrl = request.URL;
    
    if ([URL.scheme isEqualToString:@"ntesfa"]) {
        [JLRoutes routeURL:URL withParameters:@{kLDRouteViewControllerKey:self}];
        return NO;
    }
    
    if (self.shouldExchangeLoginStatus && [LDPMWebLoginStatusService shouldExchangeLoginStatusForRequest:request]) {
        self.shouldExchangeLoginStatus = NO;
        [LDPMWebLoginStatusService exchangeLoginStatusForURLRequest:request inWebView:webView];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self startActivity:NSLocalizedString(@"Wait For Loading", @"努力加载中，请稍候...")];
    
    self.loadFinish = NO;
    self.progressView.progress = 0;
    [self.webView addSubview:self.progressView];
    
    [self startTimer];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loadFinish = YES;
    
    [self stopActivity];
    
    [self.JSBridge webReady];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.loadFinish = YES;
    
    [self stopActivity];
    
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self showLoadFailView];
    });
}

#pragma mark - 进度条

- (void)startTimer
{
    self.timer = [MSWeakTimer scheduledTimerWithTimeInterval:1/60.0f
                                                      target:self
                                                    selector:@selector(progressUpdate)
                                                    userInfo:nil
                                                     repeats:YES
                                               dispatchQueue:dispatch_get_main_queue()];
}

- (void)endTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)progressUpdate
{
    if (self.loadFinish) {
        if (self.progressView.progress >= 1) {
            [self.progressView removeFromSuperview];
            [self endTimer];
        } else {
            self.progressView.progress += 0.1;
        }
    } else {
        CGFloat step = 0.01f;
        if (self.progressView.progress >= 0.7) {
            step = 0.001;
        }
        
        self.progressView.progress += step;
        if (self.progressView.progress >= 0.9) {
            self.progressView.progress = 0.9;
        }
    }
}

#pragma mark - 加载失败后重新加载

- (void)showLoadFailView
{
    if (!self.loadFailView.superview) {
        [self.webView addSubview:self.loadFailView];
        [self.webView bringSubviewToFront:self.loadFailView];
    }
}

- (void)removeLoadFailView
{
    if (_loadFailView && _loadFailView.superview) {
        [_loadFailView removeAllSubviews];
        [_loadFailView removeFromSuperview];
        _loadFailView = nil;
    }
}

- (void)reload:(id)sender
{
    if (self.currentUrl) {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.currentUrl];
        [self.webView loadRequest:request];
        
        self.currentUrl = nil;
        [self removeLoadFailView];
    }
}

#pragma mark - getter & setter

- (UIProgressView *)progressView
{
    if (_progressView == nil) {
        CGFloat progressViewHeight = 2.5f;
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.webView.width, progressViewHeight)];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _progressView.progressTintColor = [UIColor colorWithRGB:0x3c8aea];
        _progressView.trackTintColor = [UIColor clearColor];
    }
    
    return _progressView;
}

- (UIView *)loadFailView
{
    if (_loadFailView == nil) {
        _loadFailView = [[UIView alloc] initWithFrame:self.webView.frame];
        _loadFailView.userInteractionEnabled = YES;
        _loadFailView.backgroundColor = [UIColor colorWithRGB:0xf4f4f4];
        _loadFailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"webView_failLoad"]];
        CGPoint center = _loadFailView.center;
        center.y = 250.0f ;
        imageView.center = center;
        [_loadFailView addSubview:imageView];
        
        UITapGestureRecognizer *_tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reload:)];
        [_loadFailView addGestureRecognizer:_tapGest];
    }
    
    return _loadFailView;
}


@end
