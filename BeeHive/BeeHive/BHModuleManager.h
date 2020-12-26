/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BHModuleLevel)
{
    BHModuleBasic  = 0,
    BHModuleNormal = 1
};

typedef NS_ENUM(NSInteger, BHModuleEventType)
{
    BHMSetupEvent = 0,
    BHMInitEvent,
    BHMTearDownEvent,
    BHMSplashEvent,
    BHMQuickActionEvent,
    BHMWillResignActiveEvent,
    BHMDidEnterBackgroundEvent,
    BHMWillEnterForegroundEvent,
    BHMDidBecomeActiveEvent,
    BHMWillTerminateEvent,
    BHMUnmountEvent,
    BHMOpenURLEvent,
    BHMDidReceiveMemoryWarningEvent,
    BHMDidFailToRegisterForRemoteNotificationsEvent,
    BHMDidRegisterForRemoteNotificationsEvent,
    BHMDidReceiveRemoteNotificationEvent,
    BHMDidReceiveLocalNotificationEvent,
    BHMWillPresentNotificationEvent,
    BHMDidReceiveNotificationResponseEvent,
    BHMWillContinueUserActivityEvent,
    BHMContinueUserActivityEvent,
    BHMDidFailToContinueUserActivityEvent,
    BHMDidUpdateUserActivityEvent,
    BHMHandleWatchKitExtensionRequestEvent,
    BHMDidCustomEvent = 1000
    
};


@class BHModule;

@interface BHModuleManager : NSObject

+ (instancetype)sharedManager;

// If you do not comply with set Level protocol, the default Normal
// 如果您不遵守设置级别协议，则默认为“正常”
// 注册动态模块
- (void)registerDynamicModule:(Class)moduleClass;

// 注册动态模块 是否触发初始化事件
- (void)registerDynamicModule:(Class)moduleClass
       shouldTriggerInitEvent:(BOOL)shouldTriggerInitEvent;

// 移除注册的动态组建
- (void)unRegisterDynamicModule:(Class)moduleClass;

// 加载本地模块信息到self.BHModuleInfos
- (void)loadLocalModules;

// 注册所有的模块，将BHModuleInfos中的模块信息实例化，保存到self.BHModules
- (void)registedAllModules;

// 对模块实例注册自定义事件
- (void)registerCustomEvent:(NSInteger)eventType
         withModuleInstance:(id)moduleInstance
             andSelectorStr:(NSString *)selectorStr;

// 触发某个事件
- (void)triggerEvent:(NSInteger)eventType;

// 触发某个事件 传递自定义参数
- (void)triggerEvent:(NSInteger)eventType
     withCustomParam:(NSDictionary *)customParam;



@end

