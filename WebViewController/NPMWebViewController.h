//
//  NPMWebViewController.h
//  PreciousMetals
//
//  Created by ypchen on 10/28/14.
//  Copyright (c) 2014 NetEase. All rights reserved.
//

#import "LDPMBaseWebViewController.h"

@class LDPMWebViewShareData;

@interface NPMWebViewController : LDPMBaseWebViewController

@property (nonatomic, strong) LDPMWebViewShareData *shareItem;
@property (nonatomic, assign) BOOL forceLocalTitle;

- (UINavigationController*)parentNavigationController;

@end
