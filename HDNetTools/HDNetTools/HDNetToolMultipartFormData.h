//
//  HDNetToolMultipartFormData.h
//  JianLiXiu
//
//  Created by Damon on 2017/3/6.
//  Copyright © 2017年 damon. All rights reserved.
//
//图片@"image/png"
//视频@"video/quicktime"
#import <Foundation/Foundation.h>
#import "HDNetToolDefConfig.h"

@interface HDNetToolMultipartFormData : NSObject
@property (strong,nonatomic)NSString *filePath; //文件本地路径
@property (strong,nonatomic)NSString *fileName; //文件名称
@property (strong,nonatomic)NSString *postKey;  //上传的文件对应的key值
@property (assign,nonatomic)HDmimeType mimeType; //文件类型，获取需要使用getMimeTypeStr

///上传文件数据初始化
- (HDNetToolMultipartFormData*)initWithFilePath:(NSString*)filepath andFileName:(NSString*)fileName andPostKey:(NSString*)postKey andHDmimeType:(HDmimeType)mimeType;

///通过文件类型获取mimetype的字符串
- (NSString*)getMimeTypeStr;
@end
