/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class BHContext;

@interface BHServiceManager : NSObject

// 启动异常
@property (nonatomic, assign) BOOL  enableException;

+ (instancetype)sharedManager;

// 注册所有的本地服务
- (void)registerLocalServices;

// 通过服务（协议）、服务实现类，注册服务
- (void)registerService:(Protocol *)service implClass:(Class)implClass;

- (id)createService:(Protocol *)service;
- (id)createService:(Protocol *)service withServiceName:(NSString *)serviceName;
// 通过服务（协议）、服务名称、是否缓存服务，创建服务
- (id)createService:(Protocol *)service withServiceName:(NSString *)serviceName shouldCache:(BOOL)shouldCache;

// 获取服务实例对象
- (id)getServiceInstanceFromServiceName:(NSString *)serviceName;
// 移除服务
- (void)removeServiceWithServiceName:(NSString *)serviceName;

@end
