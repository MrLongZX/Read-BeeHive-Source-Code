/**
 * Created by BeeHive.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the GNU GENERAL PUBLIC LICENSE.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

// 注册模块方式1：通过Annotation方式注册

#import <Foundation/Foundation.h>
#import "BeeHive.h"

#ifndef BeehiveModSectName

#define BeehiveModSectName "BeehiveMods"

#endif

#ifndef BeehiveServiceSectName

#define BeehiveServiceSectName "BeehiveServices"

#endif

/*
 知识：
 used修饰，即使函数没有被引用，在Release下也不会被优化。
 如果不加这个修饰，那么Release环境链接器下会去掉没有被引用的段
 
 Static静态变量会按照他们申明的顺序，放到一个单独的段中。
 我们通过使用__attribute__((section("name")))来指明哪个段。
 数据则用__attribute__((used))来标记，防止链接器会优化删除未被使用的段
 
 数据指定存在data数据段里面的"BeehiveMods"段中
 */
#define BeeHiveDATA(sectname) __attribute((used, section("__DATA,"#sectname" ")))


/*
 BeeHiveMod(ShopModule)
 
 class BeeHive; char * kShopModule_mod __attribute((used, section("__DATA,""BeehiveMods"" "))) = """ShopModule""";
 相当于下面：
 char * kShopModule_mod = """ShopModule""";
 只不过是把kShopModule_mod字符串放到了特殊的段（BeehiveMods段）里面
 */
#define BeeHiveMod(name) \
class BeeHive; char * k##name##_mod BeeHiveDATA(BeehiveMods) = ""#name"";

#define BeeHiveService(servicename,impl) \
class BeeHive; char * k##servicename##_service BeeHiveDATA(BeehiveServices) = "{ \""#servicename"\" : \""#impl"\"}";

@interface BHAnnotation : NSObject

@end
