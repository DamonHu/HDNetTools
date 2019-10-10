//
//  HDNetTool.m
//  AFNetworkingDemo
//
//  Created by Damon on 2017/12/20.
//  Copyright © 2017年 damon. All rights reserved.
//

#import "HDNetTools.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"

NSString * const HDNetworkingReachabilityDidChangeNotification = @"HDNetworkingReachabilityDidChangeNotification";
NSString * const HDNetworkingReachabilityNotificationStatusItem = @"HDNetworkingReachabilityNotificationStatusItem";

@interface HDNetToolConfig()
@property (copy, nonatomic) NSString *addHeaderStr;     //添加到header里面的字符串
@property (copy, nonatomic) NSString *headerName;       //添加到header的标识name
@property (assign, nonatomic) BOOL mIsShowingProgress;  //是否已经显示progress
@property (copy, nonatomic) HDNetToolCompetionHandler mNetToolCompetionHandler;     //请求的回调
@property (strong, nonatomic, readwrite) NSURLSessionTask * task;                   //当前的task任务状态
@property (assign, nonatomic, readwrite) HDNetToolConfigRequestStatus requestStatus;    //请求任务进行状态

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

#pragma mark -
#pragma mark - init dealloc
- (void)dealloc {
    [self cancelShowProgress];
}

- (instancetype)init {
    return [self initWithUrl:@""];
}

///通过url初始化
- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _url = url;
        _canTouchWhenRequest = YES;
        _showProgressHUD = NO;
        _progressHUDText = nil;
        _mIsShowingProgress = NO;
        _delayShowProgressHUDTimeInterval = 0.0f;
        _timeoutInterval = 10.0f;
        _retryCount = 3;
        _retryTimeInterval = 3;
        _showDebugLog = NO;
        _requestStatus = kHDNetToolConfigRequestStatusNone;
    }
    return self;
}

///是否请求时在Header中加自己的标识，默认为YES，加自定义header
- (void)setAddUAHeaderStr:(NSString *)addHeaderStr withHeaderName:(NSString *)headerName {
    _addHeaderStr = addHeaderStr;
    _headerName = headerName;
}

///添加要上传的文件，可以一个一个加
- (void)addMultipartFormData:(HDNetToolMultipartFormData *)formData {
    [self.multipartFormData addObject:formData];
}

///设置任务状态
- (void)setRequestStatus:(HDNetToolConfigRequestStatus)requestStatus {
    _requestStatus = requestStatus;
    if (requestStatus == HDNetToolConfigRequestStatusStop || requestStatus == HDNetToolConfigRequestStatusCancel) {
        //取消和停止状态时，取消显示弹窗hud
        [self cancelShowProgress];
    }
    if (requestStatus == HDNetToolConfigRequestStatusCancel) {
        //取消停止任务
        [self.task cancel];
    }
}

///开始显示弹窗hud
- (void)startShowProgress {
    if (self.showProgressHUD || self.delayShowProgressHUDTimeInterval > 0) {
        self.mIsShowingProgress = true;
        if (self.progressHUDText) {
            [SVProgressHUD showWithStatus:self.progressHUDText];
        } else {
            [SVProgressHUD show];
        }
    }
    if (!self.canTouchWhenRequest) {
        //有不能点击的就设置不可点击
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    }
}

///取消弹窗hud
- (void)cancelShowProgress {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startShowProgress) object:nil];
    if (self.mIsShowingProgress) {
        [SVProgressHUD popActivity];
        self.mIsShowingProgress = false;
    }
}

@end



@implementation HDNetTools

+ (NSMutableArray *)netConfigArray {
    static NSMutableArray *netConfigArray;     //请求的配置数组
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        netConfigArray = [[NSMutableArray alloc] init];
    });
    return netConfigArray;
}

#pragma mark -
#pragma mark - Load
///通过HDNetToolConfig取消请求
+ (void)cancelRequestByConfig:(HDNetToolConfig *)netToolConfig {
    netToolConfig.requestStatus = HDNetToolConfigRequestStatusCancel;
    [[HDNetTools netConfigArray] removeObject:netToolConfig];
    //遍历请求，是否需要取消不可点击
    BOOL shouldCancelTouch = true;
    for (netToolConfig in [HDNetTools netConfigArray]) {
        if (netToolConfig.mIsShowingProgress && !netToolConfig.canTouchWhenRequest) {
            shouldCancelTouch = false;
            break;
        }
    }
    if (shouldCancelTouch) {
        //没有不能点击的请求，可以恢复点击
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    }
}

///通过URL取消请求
+ (void)cancelRequestByURL:(NSString *)url {
    if (!url){
        return;
    }
    @synchronized (self){
        NSArray *netConfigArray = [NSArray arrayWithArray:[HDNetTools netConfigArray]];
        [netConfigArray enumerateObjectsUsingBlock:^(HDNetToolConfig  *_Nonnull netConfig, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([netConfig.url hasPrefix:url]){
                [HDNetTools cancelRequestByConfig:netConfig];
            }
        }];
    }
}

///取消所有请求
+ (void)cancelAllNetRequest {
    // 锁操作
    @synchronized(self){
        NSArray *netConfigArray = [NSArray arrayWithArray:[HDNetTools netConfigArray]];
        [netConfigArray enumerateObjectsUsingBlock:^(HDNetToolConfig  *_Nonnull netConfig, NSUInteger idx, BOOL * _Nonnull stop) {
            [HDNetTools cancelRequestByConfig:netConfig];
        }];
    }
}

#pragma mark - Tools
///调用一次检测网络状态，检测完毕之后回调
+ (void)startNetMonitoringComplete:(_Nullable HDNetToolMonitoringCompetionHandler)completion {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        HDNetReachabilityStatus netStatus = kHDNetReachabilityStatusUnknown;
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
+ (void)stopNetMonitoring {
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

///使用HDNetToolRequestTypePost普通post请求，返回jsonData请求网络
+ (void)startRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig CompleteCallBack:(_Nullable HDNetToolCompetionHandler)completion {
    [self startRequestWithHDNetToolConfig:netToolConfig WithType:HDNetToolRequestTypePost andCompleteCallBack:completion];
}

///开始请求网络
+ (void)startRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig WithType:(HDNetToolRequestType)requestType andCompleteCallBack:(_Nullable HDNetToolCompetionHandler)completion {
    //请求立即显示弹窗
    if (netToolConfig.showProgressHUD) {
        [netToolConfig startShowProgress];
    }
    //延时显示弹窗
    if (netToolConfig.delayShowProgressHUDTimeInterval > 0.0f) {
        [netToolConfig performSelector:@selector(startShowProgress) withObject:nil afterDelay:netToolConfig.delayShowProgressHUDTimeInterval];
    }
    // 设置超时时间
    [[AFHTTPSessionManager manager].requestSerializer willChangeValueForKey:@"timeoutInterval"];
    [AFHTTPSessionManager manager].requestSerializer.timeoutInterval = netToolConfig.timeoutInterval;
    [[AFHTTPSessionManager manager].requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    switch (requestType) {
        case HDNetToolRequestTypePost: {
            [HDNetTools p_startHDNetPostRequestWithHDNetToolConfig:netToolConfig  andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeGet: {
            [HDNetTools p_startHDNetGetRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeUploadFileAndData: {
            [HDNetTools p_startHDNETUploadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypePostDownLoadFile: {
            [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeGetDownLoadFile: {
            [HDNetTools p_startHDNetGetDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        case HDNetToolRequestTypeUploadAndDownLoad: {
            [HDNetTools p_startHDNETDownloadRequestWithHDNetToolConfig:netToolConfig andRetryCount:netToolConfig.retryCount andCallBack:completion];
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark - Private method
+ (void)p_startHDNetPostRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completion {
    __block int retryCount = count;
    //回调函数
    netToolConfig.mNetToolCompetionHandler = completion;
    NSError *errors;
    NSMutableURLRequest *req = [[ AFHTTPSessionManager manager].requestSerializer requestWithMethod:@"POST" URLString:netToolConfig.url parameters:netToolConfig.requestData error:&errors];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    
    if (netToolConfig.addHeaderStr.length > 0) {
       [req setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [[ AFHTTPSessionManager manager] dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [dataTask cancel];
                [HDNetTools p_startHDNetPostRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response,responseObject,error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = dataTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [dataTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}

+ (void)p_startHDNetGetRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completion {
    __block int retryCount = count;
    netToolConfig.mNetToolCompetionHandler = completion;
    NSError *errors;
    NSMutableURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:netToolConfig.url parameters:nil error:&errors];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    if (netToolConfig.addHeaderStr.length>0) {
        [req setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [[ AFHTTPSessionManager manager] dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [dataTask cancel];
                [HDNetTools p_startHDNetGetRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response,responseObject,error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = dataTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [dataTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}

+ (void)p_startHDNETUploadRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completion {
    __block int retryCount = count;
    netToolConfig.mNetToolCompetionHandler = completion;

    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:netToolConfig.url parameters:[[NSMutableDictionary alloc] initWithDictionary:netToolConfig.requestData] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (int i=0; i<netToolConfig.multipartFormData.count; i++) {
            HDNetToolMultipartFormData *formItem = [netToolConfig.multipartFormData objectAtIndex:i];
            [formData appendPartWithFileURL:formItem.filePath name:formItem.postKey fileName:formItem.fileName mimeType:formItem.mimeTypeString error:nil];
        }
    } error:nil];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionUploadTask * uploadTask = nil;
    uploadTask = [[ AFHTTPSessionManager manager] uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HDNetTool_DebugLog(@"\nURL:\n%@ Progress:%f",netToolConfig.url,uploadProgress.fractionCompleted);
        });
    }
    completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (netToolConfig.showDebugLog) {
            HDNetTool_DebugLog(@"\nURL:\n%@\nResponse:\n%@",netToolConfig.url,responseObject);
        }
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [uploadTask cancel];
                [HDNetTools p_startHDNETUploadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response, responseObject, error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = uploadTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [uploadTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}

///普通的带参数DownLoad下载接口,网址填写完整的，有可能是外网,返回系统报错，自定义报错后的处理
+ (void)p_startHDNetPostDownLoadRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    netToolConfig.mNetToolCompetionHandler = completionHandler;
    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:netToolConfig.url parameters:netToolConfig.requestData error:&errors];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    if (netToolConfig.addHeaderStr.length > 0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionDownloadTask *downloadTask = nil;
    downloadTask = [[ AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        HDNetTool_DebugLog(@"\nURL:\n%@ Progress:%f",netToolConfig.url,downloadProgress.fractionCompleted);
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
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [downloadTask cancel];
                [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response,filePath,error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = downloadTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [downloadTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}

///不带参数单独下载的GET下载接口,网址填写完整的，有可能是外网,返回系统报错，自定义报错后的处理
+ (void)p_startHDNetGetDownLoadRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    netToolConfig.mNetToolCompetionHandler = completionHandler;
    
    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:netToolConfig.url parameters:nil error:&errors];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionDownloadTask *downloadTask;
    downloadTask = [[AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        HDNetTool_DebugLog(@"\nURL:\n%@ Progress:%f",netToolConfig.url,downloadProgress.fractionCompleted);
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
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [downloadTask cancel];
                [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response,filePath,error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = downloadTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [downloadTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}

///上传文件之后下载数据流
+ (void)p_startHDNETDownloadRequestWithHDNetToolConfig:(HDNetToolConfig *)netToolConfig andRetryCount:(int)count  andCallBack:(HDNetToolCompetionHandler)completionHandler {
    __block int retryCount = count;
    netToolConfig.mNetToolCompetionHandler = completionHandler;
    NSError *errors;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:netToolConfig.url parameters:[[NSMutableDictionary alloc] initWithDictionary:netToolConfig.requestData] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (int i=0; i<netToolConfig.multipartFormData.count; i++) {
            HDNetToolMultipartFormData *formItem = [netToolConfig.multipartFormData objectAtIndex:i];
            [formData appendPartWithFileURL:formItem.filePath name:formItem.postKey fileName:formItem.fileName mimeType:formItem.mimeTypeString error:nil];
        }
    } error:&errors];
    if (errors) {
        NSAssert(NO, errors.localizedDescription);
    }
    if (netToolConfig.addHeaderStr.length>0) {
        [request setValue:netToolConfig.addHeaderStr forHTTPHeaderField:netToolConfig.headerName];
    }
    __block NSURLSessionDownloadTask *downloadTask;
    downloadTask = [[ AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        HDNetTool_DebugLog(@"\nURL:\n%@ Progress:%f",netToolConfig.url,downloadProgress.fractionCompleted);
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
        [[HDNetTools netConfigArray] removeObject:netToolConfig];
        if (error && retryCount>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(netToolConfig.retryTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (netToolConfig.requestStatus == HDNetToolConfigRequestStatusCancel) {
                    return;
                }
                [downloadTask cancel];
                [HDNetTools p_startHDNetPostDownLoadRequestWithHDNetToolConfig:netToolConfig andRetryCount:--retryCount andCallBack:netToolConfig.mNetToolCompetionHandler];
            });
            return;
        }
        HDNetTool_DebugLog(@"网络错误,%@",error.localizedDescription);
        if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
            netToolConfig.requestStatus = HDNetToolConfigRequestStatusStop;
        }
        if (netToolConfig.mNetToolCompetionHandler) {
            netToolConfig.mNetToolCompetionHandler(response,filePath,error);
            netToolConfig.mNetToolCompetionHandler = nil;
        }
    }];
    netToolConfig.task = downloadTask;
    if (netToolConfig.requestStatus != HDNetToolConfigRequestStatusCancel) {
        netToolConfig.requestStatus = HDNetToolConfigRequestStatusExecuting;
    }
    [downloadTask resume];
    [[HDNetTools netConfigArray] addObject:netToolConfig];
}
@end
