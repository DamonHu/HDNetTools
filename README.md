![](./HDNetTools.png)

# 已全力支持swift。该库不再维护更新！！！

# HDNetTools

对AFNetworking的3.x版本的一个封装，已集成到`cocoapods`，提供了请求悬浮窗显示于隐藏、延迟显示悬浮窗、请求时屏幕点击响应、网络超时设置和重试次数设置。封装了多种请求处理，一句话即可完成网络请求，很适合中小项目的使用。

HDNetTools, based on AFNetworking encapsulation, provides request suspending windows to hide, delay display suspension windows, request screen click response, network timeout settings and retry times settings.


## 一、HDNetTool使用说明

该工具是对AFNetworking的3.x版本的一个封装，提供了返回json格式检测、请求悬浮窗显示于隐藏、延迟显示悬浮窗、请求时屏幕点击响应、网络超时设置和重试次数设置等。

为了使用方便，提供了下面的几个请求方式用作不同的用途。

```
typedef NS_ENUM(NSUInteger, HDNetToolRequestType) {
    HDNetToolRequestTypePost = 0,           //POST: 普通post请求，返回jsonData
    HDNetToolRequestTypeGet,                //GET:  普通get请求，返回jsonData
    HDNetToolRequestTypeUploadFileAndData,  //POST: 上传文件和数据，返回jsonData
    HDNetToolRequestTypePostDownLoadFile,   //POST: 带参数post下载数据或文件
    HDNetToolRequestTypeGetDownLoadFile,    //GET:  不带参数get下载数据或文件
    HDNetToolRequestTypeUploadAndDownLoad   //POST: 上传文件之后返回的数据是需要下载的文件流类型
};
```
## 二、可配置选项

该工具在请求时提供了HDNetToolConfig用来配置请求信息，下面几个可选择的配置项

```
///请求时屏幕是否可以点击，默认为YES:可以点击
@property (assign, nonatomic) BOOL canTouchWhenRequest;
///设置旋转的标识的显示文字，默认为旋转不带文字，显示请求标识时有效
@property (copy, nonatomic) NSString *progressHUDText;
///请求屏幕是否立即显示旋转标识,默认为NO:不显示请求标识
@property (assign, nonatomic) BOOL showProgressHUD;
///发起请求之后多少秒没回调才开始显示旋转标识
@property (assign, nonatomic) float delayShowProgressHUDTimeInterval;
///设置网络超时时间，默认为10s
@property (assign, nonatomic) float timeoutInterval;
///设置请求失败之后的重试次数，默认为3次
@property (assign, nonatomic) int retryCount;
///设置请求失败之后重试的时间间隔，默认为3s
@property (assign, nonatomic) float retryTimeInterval;
///设置是否显示debug输出数据，默认为NO，不显示
@property (assign, nonatomic) BOOL showDebugLog;
```

## 三、发送请求

发送请求就是统一的一个函数，参数就是配置项和发送请求的类型

```
+ (void)startRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig WithType:(HDNetToolRequestType)requestType andCompleteCallBack:(HDNetToolCompetionHandler)completion;
```

## 四、取消请求
可以通过url取消请求，也可以取消所有正在进行的请求

```
///取消对应的HDNetToolConfig请求
+ (void)cancelRequestByConfig:(HDNetToolConfig *)netToolConfig;

///取消所有对应URL取消请求
+ (void)cancelRequestByURL:(NSString *)url;

///取消所有请求
+ (void)cancelAllNetRequest;
```

## 五、网络状态
监听网络状态

```
///实时监测网络状态，检测完毕之后回调
+ (void)startNetMonitoringComplete:(_Nullable HDNetToolMonitoringCompetionHandler)completion;

///停止监测网络状态
+ (void)stopNetMonitoring;
```
## 六、返回json参数检测
YZNetReciveParamCheckTools用来检测返回参数的类型和值是否符合规则。dic是要检测的内容，url和param是请求的url和参数，用来记录发生异常的参数。

```
- (instancetype)initWithFatherDictionary:(NSDictionary *)dic withNetToolConfig:(HDNetToolConfig * _Nullable )netToolConfig;
```
添加要检测的字段

```
/**
 添加检测的字段

 @param name 字段key值
 @param paramType 字段指定的类型
 @param canNil 是否可空
 */
- (void)addCheckParamName:(NSString *)name withType:(Class)paramType canNil:(BOOL)canNil;
```

开始检测接受的参数是否符合要求

```
/**
 开始检测是否符合要求

 @param competionHandler 检测完成后发生的回调
 */
- (void)startCheckReciveParam:(_Nullable HDNetToolReciveParamCheckCompetionHandler)competionHandler;
```

## 七、接受数据输出开关

请求数据可以设置显示/隐藏接受数据的输出信息

```
netconfig.showDebugLog = false;
```

## 八、导入使用

### 文件导入

将HDNetTool文件夹的内容导入到项目即可

### cocoapods安装

```
pod 'HDNetTools'
```

## 九、使用方法

### 导入头文件

```
#import "HDNetTools.h"
```

### 监测网络状态的变化通知

```
//添加网络变化的通知
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netChange:) name:HDNetworkingReachabilityDidChangeNotification object:nil];
///检测网络状态
[HDNetTools startNetMonitoring];


///网络状态变化的通知
- (void)netChange:(NSNotification *)notification {
    HDNetReachabilityStatus status = [[notification.userInfo objectForKey:HDNetworkingReachabilityNotificationStatusItem] integerValue];
    NSLog(@"%ld",(long)status);
}
```
### 发送请求

```
//普通post请求
- (void)testPostRequst {
    //普通post请求
    NSString *url=[NSString stringWithFormat:@"https://api.tianapi.com/wxnew/?key=c9c06e42004367180cd41f5ca34297f5&num=%ld&rand=1&page=%ld",(long)2,(long)1];
    HDNetToolConfig *netToolsConfig = [[HDNetToolConfig alloc] initWithUrl:url];
    [HDNetToolS startRequestWithHDNetToolConfig:netToolsConfig CompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        NSLog(@"%@",responseObject);
    }];
}
```

### 接受数据的检测

```
-(void)testPostReciveParamCheck{
    NSString *url=[NSString stringWithFormat:@"https://api.tianapi.com/wxnew/?key=c9c06e42004367180cd41f5ca34297f5&num=%ld&rand=1&page=%ld",(long)2,(long)1];
    HDNetToolConfig *netToolsConfig = [[HDNetToolConfig alloc] initWithUrl:url];
    
    [HDNetTools startRequestWithHDNetToolConfig:netToolsConfig WithType:HDNetToolRequestTypeGet andCompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        //检测返回的类型是不是指定类型
        HDNetReciveParamCheckTools *checkTools = [[HDNetReciveParamCheckTools alloc] initWithFatherDictionary:[[responseObject objectForKey:@"newslist"] objectAtIndex:0] withNetToolConfig:netToolsConfig];
        //设置检测title是否是数字，并且不可空
        [checkTools addCheckParamName:@"title" withType:[NSNumber class] canNil:NO];
        //可以在block里面回调，直接写逻辑
        [checkTools startCheckReciveParam:^(BOOL isAccord, HDNetToolConfig *netConfig, NSError *error) {
            if (isAccord) {
                NSLog(@"1111检测通过");
            }else{
                NSLog(@"1111检测不通过,不通过的参数是:url:%@,errorStr:%@",url,error.localizedDescription);
            }
        }];
    }];
}
```

### 文件的get下载

```
- (void)testFileDownload {
    NSString *urlStr = @"https://app.huaimayi.com/qian/2018-01-01.jpg";
    HDNetToolConfig *netToolConfig = [[HDNetToolConfig alloc] initWithUrl:urlStr];
    WEAKSELF
    [HDNetTools startRequestWithHDNetToolConfig:netToolConfig WithType:HDNetToolRequestTypeGetDownLoadFile andCompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        else{
            NSURL *filePath = responseObject;
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:[HDNetTool conVertToStr:filePath]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 300, 300)];
            [imageView setImage:image];
            [weakSelf.view addSubview:imageView];
        }
    }];
    
}
```
## 十、文件说明

|文件名|文件作用说明|
|----|----|
|HDNetTools|HDNetTools库主文件，请求全部在该文件|
|HDNetToolDefConfig|HDNetTools库的配置选项和枚举列表|
|HDNetToolMultipartFormData|上传下载的多媒体数据格式|
|HDNetReciveParamCheckTools|返回json格式的检查函数|

## 十一、其他说明

飘窗提示使用默认样式的`SVProgressHUD`，可以使用`SVProgressHUD`自定义弹窗样式。

## 十二、文件链接

[HDNetTools的说明-胡东东博客](http://www.hudongdong.com/ios/758.html)

gitHub：[https://github.com/DamonHu/HDNetTools](https://github.com/DamonHu/HDNetTools)

希望可以多提建议，觉得好用给个star

## 重要fix记录

### 2019-10-10 v2.4.0

优化代码，优化`SVProgressHUD`的显示冲突

### 2019-06-04 v2.3.2

1. 遮罩层移除自定义`HDUIWindowsTools`，使用`SVProgressHUD`样式
2. 清理冗余代码，精简使用

### 2019-04-24 v2.2.0

增加内容：

1. 增加网络状态获取停止函数
2. 增加当前请求的task任务
3. 增加当前请求的状态

删除内容：

1. 删除过时的网络状态获取

修改优化内容

1. 修改通过netToolConfig停止请求的方案
2. 设置延迟显示旋转图标时不用再重复设置showProgressHUD
3. 完善通过url取消时屏幕点击操作
4. 完善网络请求任务处理，通过netconfig的task处理，不再单独返回请求
5. 修正取消网络请求时，以前网络请求的残留


### 2019-04-04 v2.0.0

修改项目结构，移除无用设置

### 2018-02-16 v1.3.0

增加管理头文件

### 2018-01-20 v1.2.0

1. 增加网络检测的回调
2. 修改网络返回参数的检测方式
3. 完善demo

### 2018-01-07 v1.0.3

1. 修正了内存重复创建的问题,现在请求内存平稳

![](http://cdn.juhuati.com/369154b02e0b1f7805fea0eb880b535f.png)
