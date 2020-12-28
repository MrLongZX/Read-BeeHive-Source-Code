//
//  ShopTarget.h
//  BeeHive
//
//  Created by DP on 16/3/28.
//  Copyright © 2016年 一渡. All rights reserved.
//

#import <Foundation/Foundation.h>

// 本Demo中，注册服务都是以 服务（协议）：服务实现类（实现协议的视图控制器）来作为示例
// 如果注册注册服务以 服务（协议）：服务实现类（实现协议的service类（如本类））来作为示例
// 那么 实现协议的service类（如本类），可以作为一个模块给外部提供服务的实现
@interface ShopModuleService : NSObject

@end
