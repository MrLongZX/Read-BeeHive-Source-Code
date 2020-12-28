//
//  ShopModuleServiceProtocol.h
//  BeeHive_Example
//
//  Created by Citicbank on 2020/12/28.
//  Copyright © 2020 一渡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHServiceProtocol.h"

@protocol ShopModuleServiceProtocol <NSObject,BHServiceProtocol>

- (UIViewController *)nativeFetchDetailViewController:(NSDictionary *)params;
- (id)nativePresentImage:(NSDictionary *)params;
- (id)showAlert:(NSDictionary *)params;

// 容错
- (id)nativeNoImage:(NSDictionary *)params;
- (id)notFound:(NSDictionary *)params;

@end
