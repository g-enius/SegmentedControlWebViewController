//
//  JSBridgeDefine.h
//  PreciousMetals
//
//  Created by LiuLiming on 15/9/9.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#ifndef JSBridgeDefine_h
#define JSBridgeDefine_h

static NSString * const JsBridgeConnectNotification = @"JsBridgeConnectNotification";
static NSString * const JsBridgeCloseNotification = @"JsBridgeCloseNotification";
static NSString * const JsBridgeWebFinishLoadNotification = @"JsBridgeWebFinishLoadNotification";

typedef void (^JsonRPCCallback)(id);

#endif
