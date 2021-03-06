/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "BHContext.h"

@interface BHContext()

@property(nonatomic, strong) NSMutableDictionary *modulesByName;

//
@property(nonatomic, strong) NSMutableDictionary *servicesByName;

@end

@implementation BHContext

// 初始化单例
+ (instancetype)shareInstance
{
    static dispatch_once_t p;
    static id BHInstance = nil;
    
    dispatch_once(&p, ^{
        BHInstance = [[[self class] alloc] init];
        if ([BHInstance isKindOfClass:[BHContext class]]) {
            // 初始化全局配置
            ((BHContext *) BHInstance).config = [BHConfig shareInstance];
        }
    });
    
    return BHInstance;
}

- (void)addServiceWithImplInstance:(id)implInstance serviceName:(NSString *)serviceName
{
    // 服务名称 服务实现实例对象 添加到 服务名称字典
    [[BHContext shareInstance].servicesByName setObject:implInstance forKey:serviceName];
}

- (void)removeServiceWithServiceName:(NSString *)serviceName
{
    // 从 服务名称字典 中移除服务键值对
    [[BHContext shareInstance].servicesByName removeObjectForKey:serviceName];
}

- (id)getServiceInstanceFromServiceName:(NSString *)serviceName
{
    // 从 服务名称字典 中获取 服务实现实例对象
    return [[BHContext shareInstance].servicesByName objectForKey:serviceName];
}

// 初始化变量
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.modulesByName  = [[NSMutableDictionary alloc] initWithCapacity:1];
        self.servicesByName  = [[NSMutableDictionary alloc] initWithCapacity:1];
        // 默认模块配置名称
        self.moduleConfigName = @"BeeHive.bundle/BeeHive";
        // 默认服务配置名称
        self.serviceConfigName = @"BeeHive.bundle/BHService";
      
#if __IPHONE_OS_VERSION_MAX_ALLOWED > 80400
        self.touchShortcutItem = [BHShortcutItem new];
#endif

        self.openURLItem = [BHOpenURLItem new];
        self.notificationsItem = [BHNotificationsItem new];
        self.userActivityItem = [BHUserActivityItem new];
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    BHContext *context = [[self.class allocWithZone:zone] init];
    
    context.env = self.env;
    context.config = self.config;
    context.appkey = self.appkey;
    context.customEvent = self.customEvent;
    context.application = self.application;
    context.launchOptions = self.launchOptions;
    context.moduleConfigName = self.moduleConfigName;
    context.serviceConfigName = self.serviceConfigName;
#if __IPHONE_OS_VERSION_MAX_ALLOWED > 80400
    context.touchShortcutItem = self.touchShortcutItem;
#endif
    context.openURLItem = self.openURLItem;
    context.notificationsItem = self.notificationsItem;
    context.userActivityItem = self.userActivityItem;
    context.customParam = self.customParam;
    
    return context;
}

@end
