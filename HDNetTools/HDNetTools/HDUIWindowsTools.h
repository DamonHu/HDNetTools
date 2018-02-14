//
//  HDUIWindowsTools.h
//  HDUser
//
//  Created by Damon on 2017/12/15.
//  Copyright © 2017年 shuni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HDUIWindowsTools : NSObject
+ (HDUIWindowsTools *)sharedHDUIWindowsTools;

///获取当前的normalwindow
-(UIWindow*)getNormalWindow;

///获取当前显示的VC，如果是navigation，就是top
-(UIViewController*)getCurrentVC;

///该VC是否有tabbar
-(BOOL)hasTabbarVC;

///获取当前显示VC的View
-(UIView*)getCurrentView;

///整个windows是否可点击
-(void)canTouchWindow:(BOOL)canTouch;

///设置遮罩层的背景颜色
-(void)setCoverBGViewColor:(UIColor*)color;
@end
