//
//  HDNetTools.h
//  AFNetworkingDemo
//
//  Created by Damon on 2017/12/20.
//  Copyright © 2017年 damon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDNetToolDefConfig.h"
#import "HDNetToolMultipartFormData.h"
#import "HDNetReciveParamCheckTools.h"

///网络变化通知
FOUNDATION_EXPORT NSString * const HDNetworkingReachabilityDidChangeNotification;
///网络变化通知中的userinfo的key
FOUNDATION_EXPORT NSString * const HDNetworkingReachabilityNotificationStatusItem;

//网络请求配置
@interface HDNetToolConfig : NSObject
///请求的url
@property (strong,nonatomic)NSString *url;
///请求的数据
@property (strong,nonatomic)NSDictionary *requestData;
///要上传的文件数组
@property (strong,nonatomic)NSMutableArray *multipartFormData;
///请求时屏幕是否可以点击，默认为NO:不可点击
@property (assign,nonatomic)BOOL canTouchWhenRequest;
///屏幕是否隐藏请求的旋转标识,默认为NO:显示请求标识
@property (assign,nonatomic)BOOL hiddenProgressHUD;
///设置旋转的标识的显示文字，默认为旋转不带文字，显示请求标识时有效
@property (strong,nonatomic)NSString *progressHUDText;
///发起请求之后多少秒之后没回调才开始显示旋转标识,不设置的话，请求时会立即显示旋转标识
@property (assign,nonatomic)float delayShowProgressHUD;
///设置网络超时时间，默认为10s
@property (assign,nonatomic)float timeoutInterval;
///设置请求失败之后的重试次数，默认为3次
@property (assign,nonatomic)int retryCount;
///是否异步发起请求,默认为NO
@property (assign,nonatomic)BOOL shouldAsyn;
///通过url初始化
-(instancetype)initWithUrl:(NSString*)url;
///请求时在请求的Header中加自己设置的标识，设置为空或者nil时不会添加
-(void)setAddUAHeaderStr:(NSString*)addHeaderStr withHeaderName:(NSString*)headerName;
///添加要上传的文件，可以一个一个加
-(void)addMultipartFormData:(HDNetToolMultipartFormData*)formData;
@end


@interface HDNetTools : NSObject
///使用HDNetToolRequestTypePost普通post请求，返回jsonData请求网络
+(void)startRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig CompleteCallBack:(HDNetToolCompetionHandler)completion;

///开始请求网络
+(void)startRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig WithType:(HDNetToolRequestType)requestType andCompleteCallBack:(HDNetToolCompetionHandler)completion;

///通过URL取消请求
+(void)cancelRequestByURL:(NSString*)url;

///通过HDNetToolConfig取消请求
+(void)cancelRequestByConfig:(HDNetToolConfig*)netToolConfig;

///取消所有请求
+(void)cancelAllNetRequest;

#pragma mark - Tools
///开始检测网络状态，只需调用一次每次网络变化都会发送网络变化通知
+(void)startNetMonitoring;

///调用一次检测网络状态，检测完毕之后回调
+(void)startNetMonitoringComplete:(HDNetToolMonitoringCompetionHandler)completion;

///检测完毕之后当前的网络状态，会自动更改，需要调用过startNetMonitoring或者startNetMonitoringComplete才生效
+(HDNetReachabilityStatus)currentNetStatue;

///判断字符串本地链接还是网络链接
+(BOOL)isLocalUrl:(NSString*)urlStr;

///字符串转化为url
+(NSURL*)conVertToURL:(NSString*)urlStr;

///url转字符串
+(NSString*)conVertToStr:(NSURL*)url;

@end
