//
//  HDNetTool.m
//  AFNetworkingDemo
//
//  Created by Damon on 2017/12/20.
//  Copyright © 2017年 damon. All rights reserved.
//

#import "HDNetTools.h"
#import "HDUIWindowsTools.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"

NSString * const HDNetworkingReachabilityDidChangeNotification = @"HDNetworkingReachabilityDidChangeNotification";
NSString * const HDNetworkingReachabilityNotificationStatusItem = @"HDNetworkingReachabilityNotificationStatusItem";

@interface HDNetToolConfig()
@property (strong, nonatomic) NSString *addHeaderStr; //添加到header里面的字符串
@property (strong, nonatomic) NSString *headerName;   //添加到header的标识name
@property (strong, nonatomic) NSTimer *requestTimer;  //请求定时显示
@end

@implementation HDNetToolConfig

#pragma mark - Lazy load
- (NSMutableArray *)multipartFormData {
    if (!_multipartFormData) {
        _multipartFormData = [NSMutableArray array];
    }
    return _multipartFormData;
}

- (NSDictionary *)requestData {
    if (!_requestData) {
        _requestData = [NSDictionary dictionary];
    }
    return _requestData;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _canTouchWhenRequest = YES;
        _showProgressHUD = NO;
        _progressHUDText = nil;
        _delayShowProgressHUDTimeInterval = 0.0f;
        _timeoutInterval = 10.0f;
        _retryCount = 3;
        _retryTimeInterval = 3;
        _maskColor = [UIColor clearColor];
        _showDebugLog = NO;
    }
    return self;
}

///通过url初始化
- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _url = url;
        _canTouchWhenRequest = YES;
        _showProgressHUD = NO;
        _progressHUDText = nil;
        _delayShowProgressHUDTimeInterval = 0.0f;
        _timeoutInterval = 10.0f;
        _retryCount = 3;
        _retryTimeInterval = 3;
        _maskColor = [UIColor clearColor];
        _showDebugLog = NO;
    }
    return self;
}

///是否请求时在Header中加自己的标识，默认为YES，加自定义header
- (void)setAddUAHeaderStr:(NSString *)addHeaderStr withHeaderName:(NSString *)headerName
{
    _addHeaderStr = addHeaderStr;
    _headerName = headerName;
}

///添加要上传的文件，可以一个一个加
- (void)addMultipartFormData:(HDNetToolMultipartFormData *)formData
{
    [self.multipartFormData addObject:formData];
}

@end


static NSMutableArray *taskArray;     //请求任务列表
static HDNetReachabilityStatus netStatus = kHDNetReachabilityStatusUnknown;  //当前网络状态
@implementation HDNetTools

+ (NSMutableArray *)taskArray
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskArray = [[NSMutableArray alloc] init];
    });
    return taskArray;
}

#pragma mark -
#pragma mark - Load
///通过task取消
+ (void)cancelRequestByURLSessionTask:(NSURLSessionTask *)urlSessionTask {
    if (urlSessionTask) {
        [urlSessionTask cancel];
        [[self taskArray] removeObject:urlSessionTask];
    }
    
}


///通过URL取消请求
+(void)cancelRequestByURL:(NSString*)url
{
    if (!url){
        return;
    }
    @synchronized (self){
        [[self taskArray] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:url]){
                [task cancel];
                [[self taskArray] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

///通过HDNetToolConfig取消请求
+(void)cancelRequestByConfig:(HDNetToolConfig*)netToolConfig
{
    [HDNetTools cancelRequestByURL:netToolConfig.url];
}

///取消所有请求
+(void)cancelAllNetRequest
{
    [SVProgressHUD dismiss];
    [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
    // 锁操作
    @synchronized(self){
        [[self taskArray] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self taskArray] removeAllObjects];
    }
}

#pragma mark - private method
+(void)startShowProgress:(NSTimer*)timer{
    BOOL showProgressHUD = [[timer.userInfo objectForKey:@"showProgressHUD"] boolValue];
    NSString *progressHUDText = [timer.userInfo objectForKey:@"progressHUDText"];
    if (showProgressHUD) {
        if (progressHUDText) {
            [SVProgressHUD showWithStatus:progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
}

#pragma mark - Tools
///开始检测网络状态，只需调用一次每次网络变化都会发送网络变化通知
+ (void)startNetMonitoring
{
    [self startNetMonitoringComplete:nil];
}

///调用一次检测网络状态，检测完毕之后回调
+ (void)startNetMonitoringComplete:(_Nullable HDNetToolMonitoringCompetionHandler)completion {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        // 当网络状态改变时调用
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:{
                HDNetTool_DebugLog(@"未知网络");
                netStatus = kHDNetReachabilityStatusUnknown;
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:{
                HDNetTool_DebugLog(@"没有网络");
                netStatus = kHDNetReachabilityStatusNotReachable;
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:{
                HDNetTool_DebugLog(@"手机自带网络");
                netStatus = kHDNetReachabilityStatusReachableViaWWAN;
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:{
                HDNetTool_DebugLog(@"WIFI");
                netStatus = kHDNetReachabilityStatusReachableViaWiFi;
            }
                break;
            default:{
                HDNetTool_DebugLog(@"未知网络");
                netStatus = kHDNetReachabilityStatusUnknown;
            }
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HDNetworkingReachabilityDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@(netStatus),HDNetworkingReachabilityNotificationStatusItem, nil]];
        if (completion) {
            completion(netStatus);
        }
    }];
    //开始监控
    [manager startMonitoring];
}

///获取当前网络状态
+ (HDNetReachabilityStatus)currentNetStatue {
    return netStatus;
}

///判断字符串本地链接还是网络链接
+ (BOOL)isLocalUrl:(NSString*)urlStr {
    return ![urlStr hasPrefix:@"http://"] && ![urlStr hasPrefix:@"https://"];
}

///字符串转化为url
+ (NSURL *)conVertToURL:(NSString*)urlStr {
    if ([HDNetTools isLocalUrl:urlStr]) {
        return [NSURL fileURLWithPath:urlStr];
    }
    else{
        return [NSURL URLWithString:urlStr];
    }
}

///url转字符串
+ (NSString *)conVertToStr:(NSURL*)url {
    if ([HDNetTools isLocalUrl:url.absoluteString]) {
        return url.path;
    }
    else{
        return url.absoluteString;
    }
}

///使用HDNetToolRequestTypePost普通post请求，返回jsonData请求网络
+ (NSURLSessionTask *)startRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig CompleteCallBack:(_Nullable HDNetToolCompetionHandler)completion {
    return [self startRequestWithHDNetToolConfig:netToolConfig WithType:HDNetToolRequestTypePost andCompleteCallBack:completion];
}

///开始请求网络
+ (NSURLSessionTask *)startRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig WithType:(HDNetToolRequestType)requestType andCompleteCallBack:(_Nullable HDNetToolCompetionHandler)completion {
    if (netToolConfig.delayShowProgressHUDTimeInterval > 0.0f) {
        if (!netToolConfig.requestTimer) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@(netToolConfig.showProgressHUD),@"showProgressHUD", netToolConfig.progressHUDText,@"progressHUDText",nil];
            netToolConfig.requestTimer = [NSTimer scheduledTimerWithTimeInterval:netToolConfig.delayShowProgressHUDTimeInterval target:self selector:@selector(startShowProgress:) userInfo:userInfo repeats:NO];
        }
    }
    
    switch (requestType) {
        case HDNetToolRequestTypePost:{
             return [HDNetTools p_startHDNetPostRequestWithHDNetToolConfig:netToolConfig  andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeGet:{
            return [HDNetTools p_startHDNetGetRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeUploadFileAndData:{
           return [HDNetTools p_startHDNETUploadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypePostDownLoadFile:{
            return [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeGetDownLoadFile:{
            return [HDNetTools p_startHDNetGetDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeUploadAndDownLoad:{
            return [HDNetTools p_startHDNETDownloadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark - Private method
+ (NSURLSessionDataTask *)p_startHDNetPostRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completion {
    __block int retryCount = count;
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    [configuration setTimeoutIntervalForRequest:_timeoutInterval];
//    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    // 设置超时时间
    [[AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSError *errors;
    NSMutableURLRequest *req = [[ AFHTTPSessionManager manager].requestSerializer requestWithMethod:@"POST" URLString:netToolConfig.url parameters:netToolConfig.requestData error:&errors];
    
    if (netToolConfig.addHeaderStr.length>0) {
       [req setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText.length>0) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:netToolConfig.canTouchWhenRequest];
    [[HDUIWindowsTools sharedHDUIWindowsTools] setCoverBGViewColor:netToolConfig.maskColor];
    __block NSURLSessionDataTask *dataTask = nil;
    WEAKSELF;
    dataTask = [[ AFHTTPSessionManager manager] dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [dataTask cancel];
                [[weakSelf taskArray] removeObject:dataTask];
                [HDNetTools p_startHDNetPostRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completion];
            });
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completion) {
            completion(response,responseObject,error);
        }
        [[weakSelf taskArray] removeObject:dataTask];
    }];
    [dataTask resume];
    [[self taskArray] addObject:dataTask];
    return dataTask;
}

+ (NSURLSessionDataTask *)p_startHDNetGetRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completion
{
    __block int retryCount = count;
    // 设置超时时间
    [[ AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    NSError *errors;
    NSMutableURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:netToolConfig.url parameters:nil error:&errors];
    if (netToolConfig.addHeaderStr.length>0) {
        [req setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:netToolConfig.canTouchWhenRequest];
    [[HDUIWindowsTools sharedHDUIWindowsTools] setCoverBGViewColor:netToolConfig.maskColor];
    __block NSURLSessionDataTask *dataTask = nil;
    WEAKSELF;
    dataTask = [[ AFHTTPSessionManager manager] dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [dataTask cancel];
                [[weakSelf taskArray] removeObject:dataTask];
                [HDNetTools p_startHDNetGetRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completion];
            });
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completion) {
            completion(response,responseObject,error);
        }
        [[weakSelf taskArray] removeObject:dataTask];
    }];
    [dataTask resume];
    [[self taskArray] addObject:dataTask];
    return dataTask;
}

+ (NSURLSessionUploadTask *)p_startHDNETUploadRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completion {
    __block int retryCount = count;
    // 设置超时时间
    [[ AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:netToolConfig.url parameters:[[NSMutableDictionary alloc] initWithDictionary:netToolConfig.requestData] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (int i=0; i<netToolConfig.multipartFormData.count; i++) {
            HDNetToolMultipartFormData *form = [netToolConfig.multipartFormData objectAtIndex:i];
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:form.filePath] name:form.postKey fileName:form.fileName mimeType:[form getMimeTypeStr] error:nil];
        }
    } error:nil];
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:netToolConfig.canTouchWhenRequest];
    [[HDUIWindowsTools sharedHDUIWindowsTools] setCoverBGViewColor:netToolConfig.maskColor];
    __block NSURLSessionUploadTask * uploadTask = nil;
    WEAKSELF;
    uploadTask = [[ AFHTTPSessionManager manager] uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (netToolConfig.showProgressHUD) {
                if (!netToolConfig.progressHUDText) {
                   [SVProgressHUD showProgress:uploadProgress.fractionCompleted];
                }
            }
        });
    }
    completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [uploadTask cancel];
                [[weakSelf taskArray] removeObject:uploadTask];
                uploadTask = [HDNetTools p_startHDNETUploadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completion];
            });
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completion) {
            completion(response, responseObject, error);
        }
        [[weakSelf taskArray] removeObject:uploadTask];
    }];
    [uploadTask resume];
    [[self taskArray] addObject:uploadTask];
    return uploadTask;
}

///普通的带参数DownLoad下载接口,网址填写完整的，有可能是外网,返回系统报错，自定义报错后的处理
+ (NSURLSessionDownloadTask *)p_startHDNetPostDownLoadRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    // 设置超时时间
    [[ AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:netToolConfig.url parameters:netToolConfig.requestData error:&errors];
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:netToolConfig.canTouchWhenRequest];
    [[HDUIWindowsTools sharedHDUIWindowsTools] setCoverBGViewColor:netToolConfig.maskColor];
    __block NSURLSessionDownloadTask *downloadTask = nil;
    WEAKSELF;
    downloadTask = [[ AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (netToolConfig.showProgressHUD) {
            if (!netToolConfig.progressHUDText) {
                [SVProgressHUD showProgress:downloadProgress.fractionCompleted];
            }
        }
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *fileUrl =[documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileUrl.path error:nil];
        }
        return fileUrl;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,response);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [downloadTask cancel];
                [[weakSelf taskArray] removeObject:downloadTask];
                downloadTask = [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completionHandler];
            });
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completionHandler) {
            completionHandler(response,filePath,error);
        }
        [[weakSelf taskArray] removeObject:downloadTask];
    }];
    
    [downloadTask resume];
    [[self taskArray] addObject:downloadTask];
    return downloadTask;
}

///不带参数单独下载的GET下载接口,网址填写完整的，有可能是外网,返回系统报错，自定义报错后的处理
+ (NSURLSessionDownloadTask *)p_startHDNetGetDownLoadRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    // 设置超时时间
    [[ AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:netToolConfig.url parameters:nil error:&errors];
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    __block NSURLSessionDownloadTask *downloadTask;
    WEAKSELF;
    downloadTask = [[ AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (netToolConfig.showProgressHUD) {
            if (!netToolConfig.progressHUDText) {
                [SVProgressHUD showProgress:downloadProgress.fractionCompleted];
            }
        }
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        
        NSURL *fileUrl =[documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileUrl.path error:nil];
        }
        return fileUrl;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,response);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [downloadTask cancel];
                [[weakSelf taskArray] removeObject:downloadTask];
                downloadTask = [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completionHandler];
            });
            
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completionHandler) {
            completionHandler(response,filePath,error);
        }
        [[weakSelf taskArray] removeObject:downloadTask];
    }];
    [downloadTask resume];
    [[self taskArray] addObject:downloadTask];
    return downloadTask;
}

///上传文件之后下载数据流
+ (NSURLSessionDownloadTask *)p_startHDNETDownloadRequestWithHDNetToolConfig:(HDNetToolConfig*)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    // 设置超时时间
    [[ AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [ AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[ AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:netToolConfig.url parameters:[[NSMutableDictionary alloc] initWithDictionary:netToolConfig.requestData] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (int i=0; i<netToolConfig.multipartFormData.count; i++) {
            HDNetToolMultipartFormData *form = [netToolConfig.multipartFormData objectAtIndex:i];
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:form.filePath] name:form.postKey fileName:form.fileName mimeType:[form getMimeTypeStr] error:nil];
        }
    } error:nil];
    
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    if (netToolConfig.showProgressHUD && netToolConfig.delayShowProgressHUDTimeInterval ==0) {
        if (netToolConfig.progressHUDText) {
            [SVProgressHUD showWithStatus:netToolConfig.progressHUDText];
        }
        else{
            [SVProgressHUD show];
        }
    }
    __block NSURLSessionDownloadTask *downloadTask;
    WEAKSELF;
    downloadTask = [[ AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (netToolConfig.showProgressHUD) {
            if (!netToolConfig.progressHUDText) {
                [SVProgressHUD showProgress:downloadProgress.fractionCompleted];
            }
        }
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        
        NSURL *fileUrl =[documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileUrl.path error:nil];
        }
        return fileUrl;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,response);
        }
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [downloadTask cancel];
                [[weakSelf taskArray] removeObject:downloadTask];
                downloadTask = [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:completionHandler];
            });
            return;
        }
        if (netToolConfig.requestTimer) {
            [netToolConfig.requestTimer invalidate];
            netToolConfig.requestTimer = nil;
        }
        else if (error){
            [SVProgressHUD showErrorWithStatus:@"网络错误，请稍后再试"];
        }
        //关闭hud和防触碰
        if (netToolConfig.showProgressHUD) {
            [SVProgressHUD dismiss];
        }
        if (!netToolConfig.canTouchWhenRequest) {
            [[HDUIWindowsTools sharedHDUIWindowsTools] canTouchWindow:YES];
        }
        if (completionHandler) {
            completionHandler(response,filePath,error);
        }
        [[self taskArray] removeObject:downloadTask];
    }];
    [downloadTask resume];
    [[self taskArray] addObject:downloadTask];
    return downloadTask;
}



@end
