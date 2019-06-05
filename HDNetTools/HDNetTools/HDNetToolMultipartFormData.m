//
//  HDNetToolMultipartFormData.m
//  JianLiXiu
//
//  Created by Damon on 2017/3/6.
//  Copyright © 2017年 damon. All rights reserved.
//

#import "HDNetToolMultipartFormData.h"

@interface HDNetToolMultipartFormData ()
@property (copy, nonatomic, readwrite) NSURL *filePath; //文件路径
@property (copy, nonatomic, readwrite) NSString *fileName; //文件名称
@property (copy, nonatomic, readwrite) NSString *postKey;  //上传的文件对应的key值
@property (copy, nonatomic, readwrite) NSString *mimeTypeString; //文件类型
@end

@implementation HDNetToolMultipartFormData

//上传文件数据初始化
- (instancetype)initWithFilePath:(NSURL *)filePath andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andHDmimeType:(HDmimeType)mimeType {
    return [self initWithFilePath:filePath andFileName:fileName andPostKey:postKey andMimeTypeString:[self p_getMimeTypeStrWithType:mimeType]];
}

- (instancetype)initWithFilePath:(NSURL *)filePath andFileName:(NSString *)fileName andPostKey:(NSString *)postKey andMimeTypeString:(NSString *)mimeTypeString {
    self = [super init];
    if (self) {
        self.filePath = filePath;
        self.fileName = fileName;
        self.postKey = postKey;
        self.mimeTypeString = mimeTypeString;
    }
    return self;
}

#pragma mark -
#pragma mark - Private Method
//通过文件类型获取mimetype的字符串
- (NSString *)p_getMimeTypeStrWithType:(HDmimeType)mimeType {
    switch (mimeType) {
        case kHDmimeTypeImgPng:
            return @"image/png";
            break;
        case kHDmimeTypeImgJpg:
            return @"image/jpeg";
            break;
        case kHDmimeTypeVideoMov:
            return @"video/quicktime";
            break;
        case kHDmimeTypeVideoMp4:
            return @"video/mp4";
            break;
        default:
            break;
    }
}

@end
