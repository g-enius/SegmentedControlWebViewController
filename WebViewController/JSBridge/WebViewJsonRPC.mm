//
//  WebViewJsonRPC.m
//  WebViewJsonRPC
//
//  Created by Xuhui on 13-10-27.
//  Copyright (c) 2013年 Xuhui. All rights reserved.
//

#include <objc/message.h>
#import "WebViewJsonRPC.h"
#import "ServiceManager.h"

NSString *JsonRPCScheme = @"jsonrpc";
NSString *JsonRPCData = @"rpcdata";
NSString *JsonRPCCall = @"rpccall";
#define JsonRPCVer @"2.0"
#define MethodTag @"method"
#define ParamsTag @"params"
#define IDTag @"id"
#define ResultTag @"result"
#define ErrorTag @"error"
#define ErrorCodeTag @"code"
#define ErrorMessageTag @"message"
#define ErrorDataTag @"data"

#define MethodNotFoundCode @"-32601"
#define MethodNotFoundMessage @"The method does not exist / is not available"

#define JsFileName @"WebViewJsonRPC.js"

#define JsCloseRPC @";if(window.jsonRPC) {window.jsonRPC.close()};"

#define MethodNotFoundError [NSDictionary dictionaryWithObjectsAndKeys:MethodNotFoundCode, ErrorCodeTag, MethodNotFoundMessage, ErrorMessageTag, nil]

static NSString *JsApiFile = @"JSApi.js";
static NSString *ConfigFile = @"ServiceConfig.json";

typedef void (^JsonRPCHandler)(NSDictionary *, JsonRPCCallback);


@interface WebViewJsonRPC () {
    NSInteger _loadCount;
}

@property (weak, nonatomic) id<UIWebViewDelegate> originDelegate;
@property (strong, nonatomic) NSMutableDictionary *handlers;
@property (strong, nonatomic) ServiceManager *serviceManager;

- (void)error:(NSDictionary *)error ID:(NSNumber *)rpcID;
- (void)respone:(id)res ID:(NSNumber *)rpcID;
- (void)callHandler:(NSString *)name Params:(NSDictionary *)params ID:(NSNumber *)ID Callback:(JsonRPCCallback)cb;

+ (BOOL)valid:(NSDictionary *)dict;

@end

@implementation WebViewJsonRPC

+ (void)setConfigFileName:(NSString *)configFileName
{
    ConfigFile = configFileName;
}

+ (void)setJsApiFileName:(NSString *)jsApiFileName
{
    if ([jsApiFileName hasSuffix:@".txt"]) {
        JsApiFile = [jsApiFileName substringToIndex:jsApiFileName.length - 4];
    } else {
        JsApiFile = jsApiFileName;
    }
}

- (instancetype)init
{
    self = [super init];
    if(self != nil) {
        _handlers = [[NSMutableDictionary alloc] init];
        _webView = nil;
        _controller = nil;
        _originDelegate = nil;
        _serviceManager = [[ServiceManager alloc] initWithConfigFile:ConfigFile];
        _loadCount = 0;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (UIViewController *)viewController
{
    return [self.controller viewControllerForJSBridge:self];
}

- (void)registerAllService
{
    NSSet *set = [self.serviceManager getExports];
    [set enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        JsonRPCHandler handler = [self selectorToBlock:obj];
        if(handler) {
          [self registerHandler:obj Handler:handler];
        }
    }];
}

- (JsonRPCHandler)selectorToBlock:(NSString *)name
{
    SEL sel = [self.serviceManager showNameToSelector:name];
    if(sel == nil) return NULL;
    ServiceInfo *serviceInfo = [self.serviceManager getServiceInfo:name];
    ExportDetail *detail = [serviceInfo getDetailByShowName:name];
    WebViewJsonRPCPermission permission = WebViewJsonRPCPermissionNormal;
    if([self.controller respondsToSelector:@selector(getPermission)]) {
        permission = [self.controller getPermission];
    }
    if(permission >= detail.level) {
        __weak id instance = serviceInfo.service;
        return [(^(NSDictionary *params, JsonRPCCallback cb) {
            // objc_msgSend在64位下的正确调用方式参见文档
            // https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaTouch64BitGuide/ConvertingYourAppto64-Bit/ConvertingYourAppto64-Bit.html#//apple_ref/doc/uid/TP40013501-CH3-SW22
            void (*handler)(id, SEL, NSDictionary *, JsonRPCCallback) = (void (*)(id, SEL, NSDictionary *, JsonRPCCallback)) objc_msgSend;
            handler(instance, sel, params, cb);
        }) copy];
    } else {
        return nil;
    }
    
}

#pragma mark KVO
- (void)registerKVO
{
    [_webView addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)unregisterKVO
{
    [_webView removeObserver:self forKeyPath:@"delegate"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newDelegate = change[@"new"];
    if(object == self.webView && [keyPath isEqualToString:@"delegate"] && newDelegate != self) {
        self.originDelegate = newDelegate;
        self.webView.delegate = self;
    }
}

- (void)connectWebView:(UIWebView *)webView controller:(id<WebViewJsonRPCController>)controller
{
    if(webView == self.webView) return;
    if(self.webView) {
        [self close];
    }
    self.controller = controller;
    self.webView = webView;
    self.originDelegate = webView.delegate;
    self.webView.delegate = self;
    [self registerAllService];
    [self registerKVO];
    [[NSNotificationCenter defaultCenter] postNotificationName:JsBridgeConnectNotification object:self userInfo: @{@"bridge":self}];
    
}

- (void)close
{
    [self unregisterKVO];
    if(self.webView == nil) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:JsBridgeCloseNotification object:self];
    [self jsEval:JsCloseRPC];
    self.webView.delegate = self.originDelegate;
    self.originDelegate = nil;
    self.webView = nil;
    self.controller = nil;
    [self.handlers removeAllObjects];
}

- (void)registerHandler:(NSString *)name Handler:(JsonRPCHandler)handler
{
    [self.handlers setObject:[handler copy] forKey:name];
}

- (void)unregisterHandler:(NSString *)name
{
    [self.handlers removeObjectForKey:name];
}

- (void)callHandler:(NSString *)name Params:(NSDictionary *)params ID:(NSNumber *)ID Callback:(JsonRPCCallback)cb
{
    JsonRPCHandler handler = [self.handlers objectForKey:name];
    if(!handler) {
        if(ID != nil) [self error:MethodNotFoundError ID:ID];
        return;
    }
    handler(params, cb);
}

- (void)error:(NSDictionary *)error ID:(NSNumber *)rpcID
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:JsonRPCVer, JsonRPCScheme, error, ErrorTag, rpcID, IDTag, nil];
    NSString *tmp = [WebViewJsonRPC jsonDictToString:dict];
    [self jsEval:[NSString stringWithFormat:@";window.jsonRPC.onMessage(%@);", tmp]];
}

- (void)respone:(id)res ID:(NSNumber *)rpcID
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:JsonRPCVer, JsonRPCScheme, res ? res : [NSNull null], ResultTag, rpcID, IDTag, nil];
    NSString *tmp = [WebViewJsonRPC jsonDictToString:dict];
    [self jsEval:[NSString stringWithFormat:@";window.jsonRPC.onMessage(%@);", tmp]];
}

+ (NSString *)jsonDictToString:(NSDictionary *)json
{
    if(json == nil) return @"null";
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)jsonDictArrayToString:(NSArray *)jsons
{
    NSMutableString *tmp = [NSMutableString stringWithString:@"["];
    [jsons enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        [tmp appendString:[WebViewJsonRPC jsonDictToString:obj]];
        [tmp appendString:@","];
    }];
    [tmp appendString:@"]"];
    return tmp;
}

+ (NSMutableDictionary *)stringToJsonDict:(NSString *)str
{
    if(str == nil || [str isEqual:[NSNull null]]) return nil;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

+ (BOOL)valid:(NSDictionary *)dict
{
    
    NSString *jsonRPCVer = [dict objectForKey:JsonRPCScheme];
    if(jsonRPCVer != nil && [jsonRPCVer isEqualToString:JsonRPCVer])
        return YES;
    else
        return NO;
}

- (NSString *)jsEvalIntrnal:(NSString *)js
{
    if(self.webView) {
        return [self.webView stringByEvaluatingJavaScriptFromString:js];
    } else {
        return nil;
    }
}

- (void)jsEval:(NSString *)js
{
        [self performSelectorOnMainThread:@selector(jsEvalIntrnal:) withObject:js waitUntilDone:YES];
}

- (NSString *)jsMainLoopEval:(NSString *)js
{
    return [self jsEvalIntrnal:js];
}

- (BridgeService *)getServiceByName:(NSString *)name
{
    return [self.serviceManager getServiceByDomain:name];
}

- (void)triggerEvent:(NSString *)type withDetail:(NSDictionary *)detail
{
    [self jsEval:[NSString stringWithFormat:@";window.jsonRPC.nativeEvent.trigger('%@', %@);", type, [WebViewJsonRPC jsonDictToString:detail]]];
}

- (BOOL)webRespondsToEvent:(NSString *)type
{
    NSString *js = [NSString stringWithFormat:@";window.jsonRPC.nativeEvent.respondsToEvent('%@').toString();", type];
    NSString *res = [self jsEvalIntrnal:js];
    return [res isEqualToString:@"true"];
}

- (NSDictionary *)webGlobalJsonData:(NSString *)key
{
    NSString *js = [NSString stringWithFormat:@";JSON.stringify(window.%@);", key];
    NSString *res = [self jsEvalIntrnal:js];
    return [WebViewJsonRPC stringToJsonDict:res];
}

- (void)ready:(BOOL)isTestMode
{
    if(isTestMode && [self.controller respondsToSelector:@selector(debugChannel)]) {
         [self jsEval:[NSString stringWithFormat:@";window.jsonRPC.setDebugChannel('%@');", [self.controller performSelector:@selector(debugChannel)]]];
    }
   
    [self jsEval:[NSString stringWithFormat:@";window.jsonRPC.ready(%@);", [NSNumber numberWithBool:isTestMode]]];
}

- (NSString *)fetchJsCommand
{
    return [self jsEvalIntrnal:@";window.jsonRPC.nativeFetchCommand();"];
}

- (void)webReady
{
    BOOL isDebug = NO;
    if([self.controller respondsToSelector:@selector(isDebugMode)]) {
        isDebug = [self.controller isDebugMode];
    }
    [self ready:isDebug];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if(webView != self.webView) return;
    if([self.originDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.originDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if(webView != self.webView) return;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:JsFileName ofType:@"txt"];
    NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self jsMainLoopEval:js];
    
    path = [[NSBundle mainBundle] pathForResource:JsApiFile ofType:@"txt"];
    js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self jsMainLoopEval:js];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JsBridgeWebFinishLoadNotification object:self];
    
    if([self.originDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.originDelegate webViewDidFinishLoad:webView];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if(webView != self.webView) return YES;
    BOOL res = NO;
    NSURL *url = [request URL];
    NSString *scheme = [[url scheme] lowercaseString];
    NSString *host = [[url host] lowercaseString];
    if([scheme isEqualToString:JsonRPCScheme] && [host isEqualToString:JsonRPCCall]) {
        NSDictionary *json = [WebViewJsonRPC stringToJsonDict:[self fetchJsCommand]];
        if([WebViewJsonRPC valid:json]) {
            NSString *method = [json objectForKey:MethodTag];
            id p = [json objectForKey:ParamsTag];
            NSDictionary *params = p != [NSNull null] ? p : nil;
            NSNumber *ID = [json objectForKey:IDTag];
            __weak WebViewJsonRPC *SELF = self;
            dispatch_async(dispatch_get_main_queue(), ^(){
                [SELF callHandler:method Params:params ID:(NSNumber *)ID Callback:^(id result) {
                    if(ID != nil) {
                        [SELF respone:result ID:ID];
                    }
                    
                }];
            });
        }
        [self triggerEvent:@"NativeReady" withDetail:nil];
        
        return NO;
    }
    
    if([scheme isEqualToString:@"about"]) return NO;
    
    if([self.originDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        res |= [self.originDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    } else {
        res = YES;
    }
    
    return res;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if(webView != self.webView) return;
   
    if([self.originDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.originDelegate webView:webView didFailLoadWithError:error];
    }
}

@end
