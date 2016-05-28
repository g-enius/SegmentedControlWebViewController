//
//  BridgeService.m
//  yixin_iphone
//
//  Created by Xuhui on 13-11-17.
//  Copyright (c) 2013年 Netease. All rights reserved.
//

#import "BridgeService.h"

@interface BridgeService ()

@end

@implementation BridgeService

- (instancetype)init
{
    self = [super init];
    if(self) {
        _bridge = nil;
        _isReady = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnect:) name:JsBridgeConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClose:) name:JsBridgeCloseNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWebViewFinishLoad:) name:JsBridgeWebFinishLoadNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)serviceInitialize
{
    
}

- (void)stopService
{
    self.bridge = nil;
    self.isReady= NO;
}

- (void)onConnect:(NSNotification *)notification
{
    if(!self.bridge) self.bridge = [notification.userInfo objectForKey:@"bridge"];
}

- (void)onClose:(NSNotification *)notification
{
    if(self.bridge && self.bridge == notification.object) {
        [self stopService];
    }
}

- (void)onWebViewFinishLoad:(NSNotification *)notification
{
    if(self.bridge && self.bridge == notification.object) {
        self.isReady = YES;
    }
}

- (NSDictionary *)generateErrorMessage:(NSString *)message
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@400, @"code", message, @"message", nil];
}

- (NSDictionary *)generateSuccessMessage:(NSDictionary *)message
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@200, @"code", message, @"message", nil];
}


@end
