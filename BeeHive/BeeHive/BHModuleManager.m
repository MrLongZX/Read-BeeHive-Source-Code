/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "BHModuleManager.h"
#import "BHModuleProtocol.h"
#import "BHContext.h"
#import "BHTimeProfiler.h"
#import "BHAnnotation.h"

#define kModuleArrayKey     @"moduleClasses"
#define kModuleInfoNameKey  @"moduleClass"
#define kModuleInfoLevelKey @"moduleLevel"
#define kModuleInfoPriorityKey @"modulePriority"
#define kModuleInfoHasInstantiatedKey @"moduleHasInstantiated"

static  NSString *kSetupSelector = @"modSetUp:";
static  NSString *kInitSelector = @"modInit:";
static  NSString *kSplashSeletor = @"modSplash:";
static  NSString *kTearDownSelector = @"modTearDown:";
static  NSString *kWillResignActiveSelector = @"modWillResignActive:";
static  NSString *kDidEnterBackgroundSelector = @"modDidEnterBackground:";
static  NSString *kWillEnterForegroundSelector = @"modWillEnterForeground:";
static  NSString *kDidBecomeActiveSelector = @"modDidBecomeActive:";
static  NSString *kWillTerminateSelector = @"modWillTerminate:";
static  NSString *kUnmountEventSelector = @"modUnmount:";
static  NSString *kQuickActionSelector = @"modQuickAction:";
static  NSString *kOpenURLSelector = @"modOpenURL:";
static  NSString *kDidReceiveMemoryWarningSelector = @"modDidReceiveMemoryWaring:";
static  NSString *kFailToRegisterForRemoteNotificationsSelector = @"modDidFailToRegisterForRemoteNotifications:";
static  NSString *kDidRegisterForRemoteNotificationsSelector = @"modDidRegisterForRemoteNotifications:";
static  NSString *kDidReceiveRemoteNotificationsSelector = @"modDidReceiveRemoteNotification:";
static  NSString *kDidReceiveLocalNotificationsSelector = @"modDidReceiveLocalNotification:";
static  NSString *kWillPresentNotificationSelector = @"modWillPresentNotification:";
static  NSString *kDidReceiveNotificationResponseSelector = @"modDidReceiveNotificationResponse:";
static  NSString *kWillContinueUserActivitySelector = @"modWillContinueUserActivity:";
static  NSString *kContinueUserActivitySelector = @"modContinueUserActivity:";
static  NSString *kDidUpdateContinueUserActivitySelector = @"modDidUpdateContinueUserActivity:";
static  NSString *kFailToContinueUserActivitySelector = @"modDidFailToContinueUserActivity:";
static  NSString *kHandleWatchKitExtensionRequestSelector = @"modHandleWatchKitExtensionRequest:";
static  NSString *kAppCustomSelector = @"modDidCustomEvent:";



@interface BHModuleManager()

@property(nonatomic, strong) NSMutableArray     *BHModuleDynamicClasses;

// 组件信息数组
@property(nonatomic, strong) NSMutableArray<NSDictionary *>     *BHModuleInfos;
@property(nonatomic, strong) NSMutableArray     *BHModules;

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<id<BHModuleProtocol>> *> *BHModulesByEvent;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *BHSelectorByEvent;

@end

@implementation BHModuleManager

#pragma mark - public

+ (instancetype)sharedManager
{
    static id sharedManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BHModuleManager alloc] init];
    });
    return sharedManager;
}

- (void)loadLocalModules
{
    // 组件配置plist路径
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:[BHContext shareInstance].moduleConfigName ofType:@"plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        // 文件不存在
        return;
    }
    
    // 组件配置字典数据
    NSDictionary *moduleList = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    // kModuleArrayKey：moduleClasses
    // 组件数组
    NSArray<NSDictionary *> *modulesArray = [moduleList objectForKey:kModuleArrayKey];
    // 组件类信息字典
    NSMutableDictionary<NSString *, NSNumber *> *moduleInfoByClass = @{}.mutableCopy;
    // kModuleInfoNameKey：moduleClass
    [self.BHModuleInfos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 保存组件信息中的moduleClass字段值 到 组件类信息字典
        [moduleInfoByClass setObject:@1 forKey:[obj objectForKey:kModuleInfoNameKey]];
    }];
    [modulesArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!moduleInfoByClass[[obj objectForKey:kModuleInfoNameKey]]) {
            // moduleInfoByClass中不存在modulesArray中的组件信息，也就是self.BHModuleInfos中不存在modulesArray中obj的信息
            // 则添加到self.BHModuleInfos中
            [self.BHModuleInfos addObject:obj];
        }
    }];
}

// 注册动态组件
- (void)registerDynamicModule:(Class)moduleClass
{
    [self registerDynamicModule:moduleClass shouldTriggerInitEvent:NO];
}

// 注册动态组件 是否触发初始化事件
- (void)registerDynamicModule:(Class)moduleClass
       shouldTriggerInitEvent:(BOOL)shouldTriggerInitEvent
{
    [self addModuleFromObject:moduleClass shouldTriggerInitEvent:shouldTriggerInitEvent];
}

- (void)unRegisterDynamicModule:(Class)moduleClass {
    if (!moduleClass) {
        return;
    }
    [self.BHModuleInfos filterUsingPredicate:[NSPredicate predicateWithFormat:@"%@!=%@", kModuleInfoNameKey, NSStringFromClass(moduleClass)]];
    __block NSInteger index = -1;
    [self.BHModules enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:moduleClass]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index >= 0) {
        [self.BHModules removeObjectAtIndex:index];
    }
    [self.BHModulesByEvent enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<id<BHModuleProtocol>> * _Nonnull obj, BOOL * _Nonnull stop) {
        __block NSInteger index = -1;
        [obj enumerateObjectsUsingBlock:^(id<BHModuleProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:moduleClass]) {
                index = idx;
                *stop = NO;
            }
        }];
        if (index >= 0) {
            [obj removeObjectAtIndex:index];
        }
    }];
}

// 注册所有组件
// 根据self.BHModuleInfos，实例化组件，添加到BHModules数组，再对组件实例注册系统事件
- (void)registedAllModules
{
    // 根据级别、优先级从大到小进行排序
    [self.BHModuleInfos sortUsingComparator:^NSComparisonResult(NSDictionary *module1, NSDictionary *module2) {
        // 组件级别
        NSNumber *module1Level = (NSNumber *)[module1 objectForKey:kModuleInfoLevelKey];
        NSNumber *module2Level =  (NSNumber *)[module2 objectForKey:kModuleInfoLevelKey];
        if (module1Level.integerValue != module2Level.integerValue) {
            return module1Level.integerValue > module2Level.integerValue;
        } else {
            // 组件优先级
            NSNumber *module1Priority = (NSNumber *)[module1 objectForKey:kModuleInfoPriorityKey];
            NSNumber *module2Priority = (NSNumber *)[module2 objectForKey:kModuleInfoPriorityKey];
            return module1Priority.integerValue < module2Priority.integerValue;
        }
    }];
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    //module init
    [self.BHModuleInfos enumerateObjectsUsingBlock:^(NSDictionary *module, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // 类名
        NSString *classStr = [module objectForKey:kModuleInfoNameKey];
        
        // 类
        Class moduleClass = NSClassFromString(classStr);
        // 已经实例化
        BOOL hasInstantiated = ((NSNumber *)[module objectForKey:kModuleInfoHasInstantiatedKey]).boolValue;
        if (NSStringFromClass(moduleClass) && !hasInstantiated) {
            // 初始化对象
            id<BHModuleProtocol> moduleInstance = [[moduleClass alloc] init];
            // 添加到临时数组
            [tmpArray addObject:moduleInstance];
        }
        
    }];
    
//    [self.BHModules removeAllObjects];

    // 添加到BHModules数组
    [self.BHModules addObjectsFromArray:tmpArray];
    
    // 对组件注册所有的系统事件
    [self registerAllSystemEvents];
}

- (void)registerCustomEvent:(NSInteger)eventType
   withModuleInstance:(id)moduleInstance
       andSelectorStr:(NSString *)selectorStr {
    if (eventType < 1000) {
        return;
    }
    [self registerEvent:eventType withModuleInstance:moduleInstance andSelectorStr:selectorStr];
}

- (void)triggerEvent:(NSInteger)eventType
{
    [self triggerEvent:eventType withCustomParam:nil];
    
}

- (void)triggerEvent:(NSInteger)eventType
     withCustomParam:(NSDictionary *)customParam {
    [self handleModuleEvent:eventType forTarget:nil withCustomParam:customParam];
}


#pragma mark - life loop

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.BHModuleDynamicClasses = [NSMutableArray array];
    }
    return self;
}


#pragma mark - private

- (BHModuleLevel)checkModuleLevel:(NSUInteger)level
{
    switch (level) {
        case 0:
            return BHModuleBasic;
            break;
        case 1:
            return BHModuleNormal;
            break;
        default:
            break;
    }
    //default normal
    return BHModuleNormal;
}

// 添加组件 是否触发初始化事件
- (void)addModuleFromObject:(id)object
     shouldTriggerInitEvent:(BOOL)shouldTriggerInitEvent
{
    Class class;
    NSString *moduleName = nil;
    
    if (object) {
        // 类
        class = object;
        // 组件名称
        moduleName = NSStringFromClass(class);
    } else {
        return ;
    }
    
    __block BOOL flag = YES;
    [self.BHModules enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // BHModules中的组件实例obj，是否是class的实例对象或子类的实例对象
        if ([obj isKindOfClass:class]) {
            // 是，说明组件已经注册过，设为NO
            flag = NO;
            *stop = YES;
        }
    }];
    if (!flag) {
        // 组件已经注册过
        return;
    }
    
    // 是否遵循BHModuleProtocol协议
    if ([class conformsToProtocol:@protocol(BHModuleProtocol)]) {
        // 组件信息字典
        NSMutableDictionary *moduleInfo = [NSMutableDictionary dictionary];
        
        // class是否实现basicModuleLevel方法
        BOOL responseBasicLevel = [class instancesRespondToSelector:@selector(basicModuleLevel)];

        int levelInt = 1;
        
        if (responseBasicLevel) {
            // 实现，级别为0
            levelInt = 0;
        }
        
        // 设置级别信息
        [moduleInfo setObject:@(levelInt) forKey:kModuleInfoLevelKey];
        if (moduleName) {
            // 设置组件名称信息
            [moduleInfo setObject:moduleName forKey:kModuleInfoNameKey];
        }

        // 添加到BHModuleInfos
        [self.BHModuleInfos addObject:moduleInfo];
        
        // 实例化组件对象
        id<BHModuleProtocol> moduleInstance = [[class alloc] init];
        // 添加到BHModules
        [self.BHModules addObject:moduleInstance];
        // 设置已经实例化key
        [moduleInfo setObject:@(YES) forKey:kModuleInfoHasInstantiatedKey];
        // 根据级别和优先级进行排序
        [self.BHModules sortUsingComparator:^NSComparisonResult(id<BHModuleProtocol> moduleInstance1, id<BHModuleProtocol> moduleInstance2) {
            // 默认级别
            NSNumber *module1Level = @(BHModuleNormal);
            NSNumber *module2Level = @(BHModuleNormal);
            if ([moduleInstance1 respondsToSelector:@selector(basicModuleLevel)]) {
                // 组件实例实现basicModuleLevel方法，则级别为basic
                module1Level = @(BHModuleBasic);
            }
            if ([moduleInstance2 respondsToSelector:@selector(basicModuleLevel)]) {
                // 组件实例实现basicModuleLevel方法，则级别为basic
                module2Level = @(BHModuleBasic);
            }
            if (module1Level.integerValue != module2Level.integerValue) {
                return module1Level.integerValue > module2Level.integerValue;
            } else {
                // 默认优先级
                NSInteger module1Priority = 0;
                NSInteger module2Priority = 0;
                if ([moduleInstance1 respondsToSelector:@selector(modulePriority)]) {
                    // 组件实例实现modulePriority方法，则获取组件实例的优先级
                    module1Priority = [moduleInstance1 modulePriority];
                }
                if ([moduleInstance2 respondsToSelector:@selector(modulePriority)]) {
                    // 组件实例实现modulePriority方法，则获取组件实例的优先级
                    module2Priority = [moduleInstance2 modulePriority];
                }
                return module1Priority < module2Priority;
            }
        }];
        // 对组件实例注册事件
        [self registerEventsByModuleInstance:moduleInstance];
        
        // 是否触发初始化事件
        if (shouldTriggerInitEvent) {
            // 调用BHMSetupEvent方法
            [self handleModuleEvent:BHMSetupEvent forTarget:moduleInstance withSeletorStr:nil andCustomParam:nil];
            // 调用BHMInitEvent方法
            [self handleModulesInitEventForTarget:moduleInstance withCustomParam:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                // 主线程调用BHMSplashEvent方法
                [self handleModuleEvent:BHMSplashEvent forTarget:moduleInstance withSeletorStr:nil andCustomParam:nil];
            });
        }
    }
}

// 注册所有系统事件
- (void)registerAllSystemEvents
{
    // 遍历组件
    [self.BHModules enumerateObjectsUsingBlock:^(id<BHModuleProtocol> moduleInstance, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerEventsByModuleInstance:moduleInstance];
    }];
}

// 对组件实例注册事件
- (void)registerEventsByModuleInstance:(id<BHModuleProtocol>)moduleInstance
{
    // 所有的事件类型
    NSArray<NSNumber *> *events = self.BHSelectorByEvent.allKeys;
    // 对组件实例注册系统事件
    [events enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerEvent:obj.integerValue withModuleInstance:moduleInstance andSelectorStr:self.BHSelectorByEvent[obj]];
    }];
}

// 对组件实例注册某个系统事件
// 就是将事件与组件实例添加到self.BHModulesByEvent字典中
- (void)registerEvent:(NSInteger)eventType
         withModuleInstance:(id)moduleInstance
             andSelectorStr:(NSString *)selectorStr {
    // 方法选择器
    SEL selector = NSSelectorFromString(selectorStr);
    if (!selector || ![moduleInstance respondsToSelector:selector]) {
        // 方法选择器为nil 或 组件实例没有实现改方法
        return;
    }
    NSNumber *eventTypeNumber = @(eventType);
    if (!self.BHSelectorByEvent[eventTypeNumber]) {
        // 事件方法字典 不包含 该事件类型，则添加进去
        [self.BHSelectorByEvent setObject:selectorStr forKey:eventTypeNumber];
    }
    if (!self.BHModulesByEvent[eventTypeNumber]) {
        // 组件事件字典 不包含 该事件类型，则添加进去
        [self.BHModulesByEvent setObject:@[].mutableCopy forKey:eventTypeNumber];
    }
    // 根据事件类型 从组件事件字典 取出注册了该事件类型的组件实例组成的数组
    NSMutableArray *eventModules = [self.BHModulesByEvent objectForKey:eventTypeNumber];
    // 注册了该事件类型的组件实例组成的数组 不包含 当前组件实例
    if (![eventModules containsObject:moduleInstance]) {
        // 则添加到 注册了该事件类型的组件实例组成的数组 中
        [eventModules addObject:moduleInstance];
        // 根据级别和优先级进行排序
        [eventModules sortUsingComparator:^NSComparisonResult(id<BHModuleProtocol> moduleInstance1, id<BHModuleProtocol> moduleInstance2) {
            // 默认级别
            NSNumber *module1Level = @(BHModuleNormal);
            NSNumber *module2Level = @(BHModuleNormal);
            if ([moduleInstance1 respondsToSelector:@selector(basicModuleLevel)]) {
                // 组件实例实现basicModuleLevel方法，则级别为basic
                module1Level = @(BHModuleBasic);
            }
            if ([moduleInstance2 respondsToSelector:@selector(basicModuleLevel)]) {
                // 组件实例实现basicModuleLevel方法，则级别为basic
                module2Level = @(BHModuleBasic);
            }
            if (module1Level.integerValue != module2Level.integerValue) {
                return module1Level.integerValue > module2Level.integerValue;
            } else {
                // 默认优先级
                NSInteger module1Priority = 0;
                NSInteger module2Priority = 0;
                if ([moduleInstance1 respondsToSelector:@selector(modulePriority)]) {
                    // 组件实例实现modulePriority方法，则获取组件实例的优先级
                    module1Priority = [moduleInstance1 modulePriority];
                }
                if ([moduleInstance2 respondsToSelector:@selector(modulePriority)]) {
                    // 组件实例实现modulePriority方法，则获取组件实例的优先级
                    module2Priority = [moduleInstance2 modulePriority];
                }
                return module1Priority < module2Priority;
            }
        }];
    }
}

#pragma mark - property setter or getter
- (NSMutableArray<NSDictionary *> *)BHModuleInfos {
    if (!_BHModuleInfos) {
        _BHModuleInfos = @[].mutableCopy;
    }
    return _BHModuleInfos;
}

- (NSMutableArray *)BHModules
{
    if (!_BHModules) {
        _BHModules = [NSMutableArray array];
    }
    return _BHModules;
}

- (NSMutableDictionary<NSNumber *, NSMutableArray<id<BHModuleProtocol>> *> *)BHModulesByEvent
{
    if (!_BHModulesByEvent) {
        _BHModulesByEvent = @{}.mutableCopy;
    }
    return _BHModulesByEvent;
}

// 事件方法
- (NSMutableDictionary<NSNumber *, NSString *> *)BHSelectorByEvent
{
    if (!_BHSelectorByEvent) {
        _BHSelectorByEvent = @{
                               @(BHMSetupEvent):kSetupSelector,
                               @(BHMInitEvent):kInitSelector,
                               @(BHMTearDownEvent):kTearDownSelector,
                               @(BHMSplashEvent):kSplashSeletor,
                               @(BHMWillResignActiveEvent):kWillResignActiveSelector,
                               @(BHMDidEnterBackgroundEvent):kDidEnterBackgroundSelector,
                               @(BHMWillEnterForegroundEvent):kWillEnterForegroundSelector,
                               @(BHMDidBecomeActiveEvent):kDidBecomeActiveSelector,
                               @(BHMWillTerminateEvent):kWillTerminateSelector,
                               @(BHMUnmountEvent):kUnmountEventSelector,
                               @(BHMOpenURLEvent):kOpenURLSelector,
                               @(BHMDidReceiveMemoryWarningEvent):kDidReceiveMemoryWarningSelector,
                               
                               @(BHMDidReceiveRemoteNotificationEvent):kDidReceiveRemoteNotificationsSelector,
                               @(BHMWillPresentNotificationEvent):kWillPresentNotificationSelector,
                               @(BHMDidReceiveNotificationResponseEvent):kDidReceiveNotificationResponseSelector,
                               
                               @(BHMDidFailToRegisterForRemoteNotificationsEvent):kFailToRegisterForRemoteNotificationsSelector,
                               @(BHMDidRegisterForRemoteNotificationsEvent):kDidRegisterForRemoteNotificationsSelector,
                               
                               @(BHMDidReceiveLocalNotificationEvent):kDidReceiveLocalNotificationsSelector,
                               
                               @(BHMWillContinueUserActivityEvent):kWillContinueUserActivitySelector,
                               
                               @(BHMContinueUserActivityEvent):kContinueUserActivitySelector,
                               
                               @(BHMDidFailToContinueUserActivityEvent):kFailToContinueUserActivitySelector,
                               
                               @(BHMDidUpdateUserActivityEvent):kDidUpdateContinueUserActivitySelector,
                               
                               @(BHMQuickActionEvent):kQuickActionSelector,
                               @(BHMHandleWatchKitExtensionRequestEvent):kHandleWatchKitExtensionRequestSelector,
                               @(BHMDidCustomEvent):kAppCustomSelector,
                               }.mutableCopy;
    }
    return _BHSelectorByEvent;
}

#pragma mark - module protocol
- (void)handleModuleEvent:(NSInteger)eventType
                forTarget:(id<BHModuleProtocol>)target
          withCustomParam:(NSDictionary *)customParam
{
    switch (eventType) {
        case BHMInitEvent:
            //special
            [self handleModulesInitEventForTarget:nil withCustomParam :customParam];
            break;
        case BHMTearDownEvent:
            //special
            [self handleModulesTearDownEventForTarget:nil withCustomParam:customParam];
            break;
        default: {
            NSString *selectorStr = [self.BHSelectorByEvent objectForKey:@(eventType)];
            [self handleModuleEvent:eventType forTarget:nil withSeletorStr:selectorStr andCustomParam:customParam];
        }
            break;
    }
    
}

// 处理组件初始化事件
- (void)handleModulesInitEventForTarget:(id<BHModuleProtocol>)target
                        withCustomParam:(NSDictionary *)customParam
{
    // 全局上下文保存参数等信息
    BHContext *context = [BHContext shareInstance].copy;
    context.customParam = customParam;
    context.customEvent = BHMInitEvent;
    
    NSArray<id<BHModuleProtocol>> *moduleInstances;
    if (target) {
        // 组件实例数组
        moduleInstances = @[target];
    } else {
        // 根据事件类型，从BHModulesByEvent获取注册了该事件类型的组件实例数组
        moduleInstances = [self.BHModulesByEvent objectForKey:@(BHMInitEvent)];
    }
    
    [moduleInstances enumerateObjectsUsingBlock:^(id<BHModuleProtocol> moduleInstance, NSUInteger idx, BOOL * _Nonnull stop) {
        __weak typeof(&*self) wself = self;
        void ( ^ bk )(void);
        bk = ^(){
            __strong typeof(&*self) sself = wself;
            if (sself) {
                if ([moduleInstance respondsToSelector:@selector(modInit:)]) {
                    // 组件实例实现了modInit方法，则进行调用
                    [moduleInstance modInit:context];
                }
            }
        };

        [[BHTimeProfiler sharedTimeProfiler] recordEventTime:[NSString stringWithFormat:@"%@ --- modInit:", [moduleInstance class]]];
        
        if ([moduleInstance respondsToSelector:@selector(async)]) {
            // 组件实例实现了async方法，则进行调用，获取是否需要异步调用modInit方法
            BOOL async = [moduleInstance async];
            
            if (async) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 异步调用
                    bk();
                });
                
            } else {
                // 同步调用
                bk();
            }
        } else {
            // 默认同步调用
            bk();
        }
    }];
}

- (void)handleModulesTearDownEventForTarget:(id<BHModuleProtocol>)target
                            withCustomParam:(NSDictionary *)customParam
{
    // 全局上下文保存参数等信息
    BHContext *context = [BHContext shareInstance].copy;
    context.customParam = customParam;
    context.customEvent = BHMTearDownEvent;
    
    NSArray<id<BHModuleProtocol>> *moduleInstances;
    if (target) {
        // 组件实例数组
        moduleInstances = @[target];
    } else {
        // 根据事件类型，从BHModulesByEvent获取注册了该事件类型的组件实例数组
        moduleInstances = [self.BHModulesByEvent objectForKey:@(BHMTearDownEvent)];
    }

    //Reverse Order to unload
    for (int i = (int)moduleInstances.count - 1; i >= 0; i--) {
        id<BHModuleProtocol> moduleInstance = [moduleInstances objectAtIndex:i];
        if (moduleInstance && [moduleInstance respondsToSelector:@selector(modTearDown:)]) {
            [moduleInstance modTearDown:context];
        }
    }
}

// 处理组件事件
- (void)handleModuleEvent:(NSInteger)eventType
                forTarget:(id<BHModuleProtocol>)target
           withSeletorStr:(NSString *)selectorStr
           andCustomParam:(NSDictionary *)customParam
{
    // 全局上下文保存参数等信息
    BHContext *context = [BHContext shareInstance].copy;
    context.customParam = customParam;
    context.customEvent = eventType;
    if (!selectorStr.length) {
        // 方法字符串为nil,则根据事件类型从BHSelectorByEvent获取
        selectorStr = [self.BHSelectorByEvent objectForKey:@(eventType)];
    }
    // 方法选择器
    SEL seletor = NSSelectorFromString(selectorStr);
    if (!seletor) {
        // selectorStr是错误的，所以NSSelectorFromString获取出现问题
        selectorStr = [self.BHSelectorByEvent objectForKey:@(eventType)];
        seletor = NSSelectorFromString(selectorStr);
    }
    NSArray<id<BHModuleProtocol>> *moduleInstances;
    if (target) {
        // 组件实例数组
        moduleInstances = @[target];
    } else {
        // 根据事件类型，从BHModulesByEvent获取注册了该事件类型的组件实例数组
        moduleInstances = [self.BHModulesByEvent objectForKey:@(eventType)];
    }
    [moduleInstances enumerateObjectsUsingBlock:^(id<BHModuleProtocol> moduleInstance, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([moduleInstance respondsToSelector:seletor]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            // 组件实例执行seletor方法，并传递全局上下文做参数
            [moduleInstance performSelector:seletor withObject:context];
#pragma clang diagnostic pop
            
            // 计算时间性能方面的分析器
            [[BHTimeProfiler sharedTimeProfiler] recordEventTime:[NSString stringWithFormat:@"%@ --- %@", [moduleInstance class], NSStringFromSelector(seletor)]];
            
        }
    }];
}

@end

