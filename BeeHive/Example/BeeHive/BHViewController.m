//
//  BHViewController.m
//  BeeHive
//
//  Created by 一渡 on 07/10/2015.
//  Copyright (c) 2015 一渡. All rights reserved.
//

#import "BHViewController.h"
#import "BeeHive.h"
#import "BHService.h"

// 注册服务
@BeeHiveService(HomeServiceProtocol,BHViewController)

@interface BHViewController ()<HomeServiceProtocol>

@property(nonatomic,strong) NSMutableArray *registerViewControllers;

@end

@interface demoTableViewController : UIViewController

@end


@implementation BHViewController

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.registerViewControllers = [[NSMutableArray alloc] initWithCapacity:1];
        
        demoTableViewController *v1 = [[demoTableViewController alloc] init];
        if ([v1 isKindOfClass:[UIViewController class]]) {
            [self registerViewController:v1 title:@"埋点1" iconName:nil];
        }
        
        id<UserTrackServiceProtocol> v4 = [[BeeHive shareInstance] createService:@protocol(UserTrackServiceProtocol)];
        if ([v4 isKindOfClass:[UIViewController class]]) {
            [self registerViewController:(UIViewController *)v4 title:@"埋点2" iconName:nil];
        }
        
        id<TradeServiceProtocol> v2 = [[BeeHive shareInstance] createService:@protocol(TradeServiceProtocol)];
        if ([v2 isKindOfClass:[UIViewController class]]) {
            v2.itemId = @"sdfsdfsfasf";
            [self registerViewController:(UIViewController *)v2 title:@"交易1" iconName:nil];
        }
        
        id<TradeServiceProtocol> s2 = (id<TradeServiceProtocol>)[[BeeHive shareInstance] createService:@protocol(TradeServiceProtocol)];
        if ([s2 isKindOfClass:[UIViewController class]]) {
            s2.itemId = @"例子222222";
            [self registerViewController:(UIViewController *)s2 title:@"交易2" iconName:nil];
        }
        
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    sleep(1);
}

-(void)registerViewController:(UIViewController *)vc title:(NSString *)title iconName:(NSString *)iconName
{
    // 设置tabBarItem
    vc.tabBarItem.image = [UIImage imageNamed:[NSString stringWithFormat:@"Home.bundle/%@", iconName]];
    vc.tabBarItem.title = title;
    
    // 设置tabbar展示视图
    [self.registerViewControllers addObject:vc];
    self.viewControllers = self.registerViewControllers;
}


-(void)click:(UIButton *)btn
{
    id<TradeServiceProtocol> obj = [[BeeHive shareInstance] createService:@protocol(TradeServiceProtocol)];
    if ([obj isKindOfClass:[UIViewController class]]) {
        obj.itemId = @"12313231231";
        [self.navigationController pushViewController:(UIViewController *)obj animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


@implementation demoTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame)-50,
                                                               200,
                                                               100,
                                                               80)];
    btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    btn.backgroundColor = [UIColor blackColor];
    [btn setTitle:@"点我" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)click:(UIButton *)btn
{
    id<ShopModuleServiceProtocol> obj = [[BeeHive shareInstance] createService:@protocol(ShopModuleServiceProtocol)];
    if ([obj isKindOfClass:[NSObject class]]) {
        [obj nativePresentImage:@{@"image":[UIImage imageNamed:@"image1"]}];
    }
}
@end
