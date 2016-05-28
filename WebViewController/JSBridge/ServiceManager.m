//
//  ServiceManager.m
//  yixin_iphone
//
//  Created by Xuhui on 13-11-18.
//  Copyright (c) 2013年 Netease. All rights reserved.
//

#import "ServiceManager.h"
#import "BridgeService.h"

@implementation ExportDetail



@end

@implementation ServiceInfo

- (ExportDetail *)getDetailByShowName:(NSString *)name
{
    return [self.exports objectForKey:name];
}



@end

@interface ServiceManager ()

@property (strong, nonatomic) NSMutableDictionary *serviceMap;
@property (strong, nonatomic) NSMutableDictionary *showNameToDomainMap;

@end

@implementation ServiceManager

- (instancetype)init
{
    self = [super init];
    if(self) {
        _serviceMap = [[NSMutableDictionary alloc] init];
        _showNameToDomainMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithConfigFile:(NSString *)file
{
    self = [self init];
    if(self) {
        [self resetWithConfigFile:file];
    }
    return self;
}


- (void)resetWithConfigFile:(NSString *)file
{
    [_serviceMap removeAllObjects];
    NSString *path = [[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] ofType:[file pathExtension]];
    if(path) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *services = [dict objectForKey:@"services"];
        for (NSDictionary *service in services) {
            ServiceInfo *info = [[ServiceInfo alloc] init];
            info.domain = [service objectForKey:@"domain"];
            info.isLocal = [[service objectForKey:@"islocal"] boolValue];
            NSMutableDictionary *exports = [[NSMutableDictionary alloc] init];
            for (NSDictionary *exportInfo in [service objectForKey:@"exports"]) {
                ExportDetail *tmp = [[ExportDetail alloc] init];
                tmp.showName = [exportInfo objectForKey:@"showname"];
                tmp.realName = [exportInfo objectForKey:@"realname"];
                tmp.level = [[exportInfo objectForKey:@"level"] integerValue];
                [exports setObject:tmp forKey:tmp.showName];
                [_showNameToDomainMap setObject:info.domain forKey:tmp.showName];
            }
            info.exports = exports;
            if(info.isLocal) {
                id obj = [[NSClassFromString(info.domain) alloc] init];
                if(obj != nil) {
                    info.service = obj;
                    [info.service serviceInitialize];
                } else {
                    NSLog(@"Service class %@ does not exist.", info.domain);
                    
                }
            }
            [_serviceMap setObject:info forKey:info.domain];
        }
    }
}

- (ServiceInfo *)getServiceInfo:(NSString *)name
{
    NSString *domain = [self.showNameToDomainMap objectForKey:name];
    if(domain == nil) return nil;
    return [self.serviceMap objectForKey:domain];
}

- (BridgeService *)getServiceByDomain:(NSString *)domain
{
    return ((ServiceInfo *)[self.serviceMap objectForKey:domain]).service;
}

- (SEL)showNameToSelector:(NSString *)name
{
    ServiceInfo *serviceInfo = [self getServiceInfo:name];
    ExportDetail *detail = [serviceInfo getDetailByShowName:name];
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@:Callback:", detail.realName]);
    if([serviceInfo.service respondsToSelector:sel]) {
        return sel;
    } else {
        return nil;
    }
}

- (NSSet *)getExports
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [self.showNameToDomainMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [set addObject:key];
    }];
    return set;
}

@end
