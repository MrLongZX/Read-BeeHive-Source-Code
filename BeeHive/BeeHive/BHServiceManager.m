/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */
#import "BHServiceManager.h"
#import "BHContext.h"
#import "BHAnnotation.h"
#import <objc/runtime.h>

static const NSString *kService = @"service";
static const NSString *kImpl = @"impl";

@interface BHServiceManager()

@property (nonatomic, strong) NSMutableDictionary *allServicesDict;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation BHServiceManager

+ (instancetype)sharedManager
{
    static id sharedManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)registerLocalServices
{
    NSString *serviceConfigName = [BHContext shareInstance].serviceConfigName;
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:serviceConfigName ofType:@"plist"];
    if (!plistPath) {
        return;
    }
    
    NSArray *serviceList = [[NSArray alloc] initWithContentsOfFile:plistPath];
    
    [self.lock lock];
    for (NSDictionary *dict in serviceList) {
        NSString *protocolKey = [dict objectForKey:@"service"];
        NSString *protocolImplClass = [dict objectForKey:@"impl"];
        if (protocolKey.length > 0 && protocolImplClass.length > 0) {
            [self.allServicesDict addEntriesFromDictionary:@{protocolKey:protocolImplClass}];
        }
    }
    [self.lock unlock];
}

- (void)registerService:(Protocol *)service implClass:(Class)implClass
{
    NSParameterAssert(service != nil);
    NSParameterAssert(implClass != nil);
    
    if (![implClass conformsToProtocol:service]) {
        if (self.enableException) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ module does not comply with %@ protocol", NSStringFromClass(implClass), NSStringFromProtocol(service)] userInfo:nil];
        }
        return;
    }
    
    // 检查是否已经是有效的服务（有无对应的实现类）
    if ([self checkValidService:service]) {
        if (self.enableException) {
            // 启动异常，则抛出异常，服务协议已经存在
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ protocol has been registed", NSStringFromProtocol(service)] userInfo:nil];
        }
        return;
    }
    
    // 服务（协议）类
    NSString *key = NSStringFromProtocol(service);
    // 服务实现类
    NSString *value = NSStringFromClass(implClass);
    
    if (key.length > 0 && value.length > 0) {
        // 加锁
        [self.lock lock];
        // 将服务与对应的实现类，添加到全局服务字典中
        [self.allServicesDict addEntriesFromDictionary:@{key:value}];
        // 解锁
        [self.lock unlock];
    }
   
}

- (id)createService:(Protocol *)service
{
    return [self createService:service withServiceName:nil];
}

- (id)createService:(Protocol *)service withServiceName:(NSString *)serviceName {
    return [self createService:service withServiceName:serviceName shouldCache:YES];
}

- (id)createService:(Protocol *)service withServiceName:(NSString *)serviceName shouldCache:(BOOL)shouldCache {
    if (!serviceName.length) {
        // 服务协议名称 作 服务名称
        serviceName = NSStringFromProtocol(service);
    }
    id implInstance = nil;
    
    // 检查是否已经是有效的服务（有无对应的实现类）
    if (![self checkValidService:service]) {
        if (self.enableException) {
            // 服务与协议没有注册，抛出异常
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ protocol does not been registed", NSStringFromProtocol(service)] userInfo:nil];
        }
        
    }
    
    NSString *serviceStr = serviceName;
    if (shouldCache) {
        // 从全局上下文中 获取服务实现实例对象
        id protocolImpl = [[BHContext shareInstance] getServiceInstanceFromServiceName:serviceStr];
        if (protocolImpl) {
            // 已经存在，则返回怒
            return protocolImpl;
        }
    }
    
    // 服务的实现类
    Class implClass = [self serviceImplClass:service];
    // 是否遵循 singleton 协议
    if ([[implClass class] respondsToSelector:@selector(singleton)]) {
        // 调用 singleton 方法，查看是否是单例
        if ([[implClass class] singleton]) {
            // 是否遵循 shareInstance 协议
            if ([[implClass class] respondsToSelector:@selector(shareInstance)])
                // 调用 shareInstance 方法，生成实现单例对象
                implInstance = [[implClass class] shareInstance];
            else
                // 生成实现实例对象
                implInstance = [[implClass alloc] init];
            if (shouldCache) {
                // 通过 全局上下文，缓存服务对象与服务
                [[BHContext shareInstance] addServiceWithImplInstance:implInstance serviceName:serviceStr];
                // 返回服务对象
                return implInstance;
            } else {
                // 返回服务对象
                return implInstance;
            }
        }
    }
    // 不是单例，返回服务对象
    return [[implClass alloc] init];
}

// 获取服务实例对象
- (id)getServiceInstanceFromServiceName:(NSString *)serviceName
{
    // 从全局上下文中 获取服务实现实例对象
    return [[BHContext shareInstance] getServiceInstanceFromServiceName:serviceName];
}

// 移除服务
- (void)removeServiceWithServiceName:(NSString *)serviceName
{
    [[BHContext shareInstance] removeServiceWithServiceName:serviceName];
}


#pragma mark - private
// 返回服务的实现类
- (Class)serviceImplClass:(Protocol *)service
{
    // 获取服务对应的实现类
    NSString *serviceImpl = [[self servicesDict] objectForKey:NSStringFromProtocol(service)];
    if (serviceImpl.length > 0) {
        // 返回服务实现
        return NSClassFromString(serviceImpl);
    }
    return nil;
}

// 检查是否是有效的服务（有无对应的实现类）
- (BOOL)checkValidService:(Protocol *)service
{
    // 获取服务对应的实现类
    NSString *serviceImpl = [[self servicesDict] objectForKey:NSStringFromProtocol(service)];
    if (serviceImpl.length > 0) {
        return YES;
    }
    return NO;
}

- (NSMutableDictionary *)allServicesDict
{
    if (!_allServicesDict) {
        _allServicesDict = [NSMutableDictionary dictionary];
    }
    return _allServicesDict;
}

- (NSRecursiveLock *)lock
{
    if (!_lock) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return _lock;
}

- (NSDictionary *)servicesDict
{
    // 加锁
    [self.lock lock];
    // 拷贝全局所有服务的字典
    NSDictionary *dict = [self.allServicesDict copy];
    // 解锁
    [self.lock unlock];
    return dict;
}


@end
