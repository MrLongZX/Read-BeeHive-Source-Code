//
//  TradeModule.m
//  BeeHive
//
//  Created by 一渡 on 7/14/15.
//  Copyright (c) 2015 一渡. All rights reserved.
//

#import "TradeModule.h"
#import "BeeHive.h"
#import "BHTradeViewController.h"

@interface TradeModule()<BHModuleProtocol>

@end

@implementation TradeModule

+ (void)load
{
    // 注册动态模块
    [BeeHive registerDynamicModule:[self class]];
}

- (id)init{
    if (self = [super init])
    {
        NSLog(@"TradeModule init");
    }
    return self;
}

// 下面的两个方法，是BHAppDelegate类中application:didFinishLaunchingWithOptions:方法中调用BHModuleManager类的triggerEvent方法而触发
- (void)modSetUp:(BHContext *)context {
    // 注册服务
    [[BeeHive shareInstance] registerService:@protocol(TradeServiceProtocol) service:[BHTradeViewController class]];
    NSLog(@"TradeModule setup");
}

-(void)modInit:(BHContext *)context {
    NSLog(@"模块初始化中");
    NSLog(@"%@",context.moduleConfigName);
    // 创建服务实例对象
    id<TradeServiceProtocol> service = [[BeeHive shareInstance] createService:@protocol(TradeServiceProtocol)];
    service.itemId = @"我是单例";
}

- (void)basicModuleLevel {}

@end
