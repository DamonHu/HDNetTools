//
//  HDNetToolMultipartFormData.h
//  JianLiXiu
//
//  Created by Damon on 2017/3/6.
//  Copyright © 2017年 damon. All rights reserved.

// 多媒体类型的data

#import <Foundation/Foundation.h>
#import "HDNetToolDefConfig.h"

@interface HDNetToolMultipartFormData : NSObject
@property (strong, nonatomic, readonly) NSURL *filePath; //文件路径
@property (strong, nonatomic, readonly) NSData *fileData;   //文件内容
@property (copy, nonatomic, readonly) NSString *fileName; //文件名称
@property (copy, nonatomic, readonly) NSString *postKey;  //上传的文件对应的key值
@property (copy, nonatomic, readonly) NSString *mimeTypeString; //文件类型

/**
 通过内置的常见格式初始化对象

 @param filePath 文件路径
 @param fileName 文件的名称
 @param postKey 上传给服务器的key值
 @param mimeType 上传的文件的类型
 @return 初始化之后的对象
 */
- (instancetype)initWithFilePath:(NSURL *)filePath andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andHDmimeType:(HDmimeType)mimeType;

- (instancetype)initWithData:(NSData *)fileData andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andHDmimeType:(HDmimeType)mimeType;


/**
 通过自定义的文件类型去格式化对象

 @param filePath 文件路径
 @param fileName 文件名称
 @param postKey 上传给服务器的key值
 @param mimeTypeString 上传的文件的类型
 @return 初始化之后的对象
 */
- (instancetype)initWithFilePath:(NSURL *)filePath andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andMimeTypeString:(NSString *)mimeTypeString;

- (instancetype)initWithData:(NSData *)fileData andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andMimeTypeString:(NSString *)mimeTypeString;
@end
