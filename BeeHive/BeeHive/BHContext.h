/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import "BHServiceProtocol.h"
#import "BHConfig.h"
#import "BHAppDelegate.h"

typedef enum
{
    BHEnvironmentDev = 0,
    BHEnvironmentTest,
    BHEnvironmentStage,
    BHEnvironmentProd
}BHEnvironmentType;


@interface BHContext : NSObject <NSCopying>

//global env
@property(nonatomic, assign) BHEnvironmentType env;

//global config
@property(nonatomic, strong) BHConfig *config;

//application appkey
@property(nonatomic, strong) NSString *appkey;
//customEvent>=1000 自定义事件
@property(nonatomic, assign) NSInteger customEvent;

// 应用对象
@property(nonatomic, strong) UIApplication *application;

// 启动选项
@property(nonatomic, strong) NSDictionary *launchOptions;

// 组件配置名称
@property(nonatomic, strong) NSString *moduleConfigName;

// 服务配置名称
@property(nonatomic, strong) NSString *serviceConfigName;

//3D-Touch model
#if __IPHONE_OS_VERSION_MAX_ALLOWED > 80400
@property (nonatomic, strong) BHShortcutItem *touchShortcutItem;
#endif

//OpenURL model
@property (nonatomic, strong) BHOpenURLItem *openURLItem;

//Notifications Remote or Local
@property (nonatomic, strong) BHNotificationsItem *notificationsItem;

//user Activity Model
@property (nonatomic, strong) BHUserActivityItem *userActivityItem;

//watch Model
@property (nonatomic, strong) BHWatchItem *watchItem;

//custom param 自定义参数
@property (nonatomic, copy) NSDictionary *customParam;

+ (instancetype)shareInstance;

- (void)addServiceWithImplInstance:(id)implInstance serviceName:(NSString *)serviceName;

- (void)removeServiceWithServiceName:(NSString *)serviceName;

- (id)getServiceInstanceFromServiceName:(NSString *)serviceName;

@end
