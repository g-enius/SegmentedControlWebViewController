//
//  NPMWebViewController+Route.m
//  PreciousMetals
//
//  Created by xuguoxing on 8/10/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NPMWebViewController+Route.h"
#import "ECLaunch.h"

@implementation NPMWebViewController (Route)

+(void)registerRoutes
{
    BOOL (^ processBlock)(NSDictionary *) = ^(NSDictionary *parameters) {
        NSURL *URL = parameters[kJLRouteURLKey];
        
        [ECLaunch launchSingleTopViewControllerWithStyle:ECLaunchStyleStandard
                                              equalBlock:^BOOL(UIViewController *viewController) {
                                                  return [viewController isKindOfClass:self];
                                              } configBlock:^UIViewController *(NPMWebViewController *viewController) {
                                                  if (!viewController) {
                                                      viewController = [self new];
                                                  }
                                                  [viewController loadURL:URL];
                                                  return viewController;
                                              }];
        
        return YES;
    };
    [[JLRoutes routesForScheme:@"http"] addRoute:@"/*" handler:processBlock];
    [[JLRoutes routesForScheme:@"https"] addRoute:@"/*" handler:processBlock];
    [[JLRoutes routesForScheme:@"file"] addRoute:@"/*" handler:processBlock];
    
    [JLRoutes addRoute:@"/open" handler:^BOOL(NSDictionary *parameters) {
        NSString *urlString = parameters[@"url"];
        if (urlString.length == 0) {
            return YES;
        }
        
        NSURL *URL = [NSURL URLWithString:urlString];
        if (URL && ([URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"] || [URL.scheme isEqualToString:@"file"])) {
            [JLRoutes routeURL:URL];
        }
        
        return YES;
    }];
}

@end
