//
//  HDNetToolDefConfig.h
//  AFNetworkingDemo
//
//  Created by Damon on 2017/12/20.
//  Copyright © 2017年 damon. All rights reserved.
//

#ifndef HDNetToolDefConfig_h
#define HDNetToolDefConfig_h

#define WEAKSELF __weak typeof(self) weakSelf = self
#define STRONGSELF __strong typeof(weakSelf) strongSelf = weakSelf
#define HDNetTool_DebugLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

@class HDNetToolConfig;

#pragma mark -
#pragma mark - 网络类型等美剧
///网络请求类型
typedef NS_ENUM(NSUInteger, HDNetToolRequestType) {
    HDNetToolRequestTypePost = 0,           //POST: 普通post请求，返回jsonData
    HDNetToolRequestTypeGet,                //GET:  普通get请求，返回jsonData
    HDNetToolRequestTypeUploadFileAndData,  //POST: 上传文件和数据，返回jsonData
    HDNetToolRequestTypePostDownLoadFile,   //POST: 带参数post下载数据或文件
    HDNetToolRequestTypeGetDownLoadFile,    //GET:  不带参数get下载数据或文件
    HDNetToolRequestTypeUploadAndDownLoad   //POST: 上传文件之后返回的数据是需要下载的文件流类型
};

///网络上传时常见的文件的mimeType
typedef NS_ENUM(NSUInteger, HDmimeType) {
    kHDmimeTypeImgPng = 1,  //png格式
    kHDmimeTypeImgJpg,      //jpg格式
    kHDmimeTypeVideoMov,    //mov格式
    kHDmimeTypeVideoMp4     //mp4格式
};

//网络状态
typedef NS_ENUM(NSInteger, HDNetReachabilityStatus) {
    kHDNetReachabilityStatusUnknown = -1,           //未知
    kHDNetReachabilityStatusNotReachable = 0,       //无网络
    kHDNetReachabilityStatusReachableViaWWAN =1,    //流量
    kHDNetReachabilityStatusReachableViaWiFi = 2,   //Wifi
};

///当前网络请求任务的状态
typedef NS_ENUM(NSUInteger, HDNetToolConfigRequestStatus) {
    kHDNetToolConfigRequestStatusNone = 0,      //未开始
    HDNetToolConfigRequestStatusExecuting = 1,  //请求中
    HDNetToolConfigRequestStatusStop = 2,       //已完成
    HDNetToolConfigRequestStatusCancel = 3,     //已取消同时停止
};

#pragma mark -
#pragma mark - 回调block

/**
 网络请求完成的回调
 @param response NSURLResponse
 @param responseObject 如果是HDNetToolRequestTypeDownLoadFile和HDNetToolRequestTypeUploadAndDownLoad，返回的是NSURL *filePath文件路径，其他返回是jsonData
 @param error 错误信息
 */
typedef void(^HDNetToolCompetionHandler)(NSURLResponse *response, id responseObject, NSError *error);


/**
 网络检测完成之后的回调
 @param status 网络检测完成之后返回网络状态
 */
typedef void(^HDNetToolMonitoringCompetionHandler)(HDNetReachabilityStatus status);

/**
 网络参数检查HDNetReciveParamCheckTools完成的回调

 @param isAccord 是否通过指定的参数检测，只有检测不通过时后面的参数才会有数据
 @param url 检测的请求的网址
 @param param 检测的发起请求的参数
 @param value 检测的请求接受到数据,json字符串
 @param error 错误信息
 */
typedef void(^HDNetToolReciveParamCheckCompetionHandler)(BOOL isAccord,HDNetToolConfig *netConfig,NSError *error);

#endif
