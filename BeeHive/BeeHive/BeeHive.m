/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "BeeHive.h"

@implementation BeeHive

#pragma mark - public

+ (instancetype)shareInstance
{
    static dispatch_once_t p;
    static id BHInstance = nil;
    
    dispatch_once(&p, ^{
        BHInstance = [[self alloc] init];
    });
    
    return BHInstance;
}

// 注册动态组件
+ (void)registerDynamicModule:(Class)moduleClass
{
    [[BHModuleManager sharedManager] registerDynamicModule:moduleClass];
}

- (id)createService:(Protocol *)proto;
{
    return [[BHServiceManager sharedManager] createService:proto];
}

- (void)registerService:(Protocol *)proto service:(Class) serviceClass
{
    [[BHServiceManager sharedManager] registerService:proto implClass:serviceClass];
}
    
+ (void)triggerCustomEvent:(NSInteger)eventType
{
    if(eventType < 1000) {
        return;
    }
    
    [[BHModuleManager sharedManager] triggerEvent:eventType];
}

#pragma mark - Private

// 保存应用全局上下文
-(void)setContext:(BHContext *)context
{
    _context = context;
    
    // 只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadStaticServices];
        [self loadStaticModules];
    });
}


- (void)loadStaticModules
{
    
    // 读取本地组件配置plist文件里面的Module，并注册到BHModuleManager的BHModuleInfos数组中
    [[BHModuleManager sharedManager] loadLocalModules];
    
    // 根据BHModuleInfos，实例化组件，添加到BHModules数组，再对组件实例注册系统事件
    [[BHModuleManager sharedManager] registedAllModules];
    
}

-(void)loadStaticServices
{
    [BHServiceManager sharedManager].enableException = self.enableException;
    
    [[BHServiceManager sharedManager] registerLocalServices];
    
}

@end
