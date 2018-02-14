//
//  HDUIWindowsTools.m
//  HDUser
//
//  Created by Damon on 2017/12/15.
//  Copyright © 2017年 shuni. All rights reserved.
//

#import "HDUIWindowsTools.h"

#define kScreenWidth   [UIScreen mainScreen].bounds.size.width
#define kScreenHeight  [UIScreen mainScreen].bounds.size.height

@interface HDUIWindowsTools()
@property (strong,nonatomic) UIView * bgView;   //遮罩背景
@property (assign,nonatomic) BOOL hasTabbar;    //是否含有tabbar
@end

@implementation HDUIWindowsTools

+ (HDUIWindowsTools *)sharedHDUIWindowsTools
{
    static HDUIWindowsTools *sharedHDUIWindowsTools = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHDUIWindowsTools = [[HDUIWindowsTools alloc] init];
    });
    return sharedHDUIWindowsTools;
}
///获取当前的normalwindow
-(UIWindow*)getNormalWindow
{
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    return window;
}

///获取当前显示的VC
-(UIViewController*)getCurrentVC
{
    self.hasTabbar = NO;
    UIWindow * window = [self getNormalWindow];
    UIViewController *result = nil;
    if ([window subviews].count>0) {
        UIView *frontView = [[window subviews] objectAtIndex:0];
        id nextResponder = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
            result = nextResponder;
        else
            result = window.rootViewController;
    }
    else{
        result = window.rootViewController;
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        self.hasTabbar = !((UITabBarController*)result).tabBar.isHidden;
        result = [((UITabBarController*)result) selectedViewController];
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [((UINavigationController*)result) visibleViewController];
    }
    return result;
}

///该VC是否有tabbar
-(BOOL)hasTabbarVC
{
    [self getCurrentVC];
    return self.hasTabbar;
}

///获取当前显示VC的最前View
-(UIView*)getCurrentView
{
    return [self getCurrentVC].view;
}

///整个windows是否可点击
-(void)canTouchWindow:(BOOL)canTouch
{
    if (canTouch) {
        [self.bgView removeFromSuperview];
    }else{
        [[self getNormalWindow] addSubview:self.bgView];
    }
}

///设置遮罩层的背景颜色
-(void)setCoverBGViewColor:(UIColor*)color
{
    [self.bgView setBackgroundColor:color];
}

///阻止点击
-(void)tapGes{
    NSLog(@"忽略点击");
}

#pragma mark - lazy load
-(UIView*)bgView{
    if (!_bgView) {
        _bgView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGes)];
        [_bgView addGestureRecognizer:tap];
    }
    return _bgView;
}
@end
