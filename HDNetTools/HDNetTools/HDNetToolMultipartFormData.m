//
//  HDNetToolMultipartFormData.m
//  JianLiXiu
//
//  Created by Damon on 2017/3/6.
//  Copyright © 2017年 damon. All rights reserved.
//

#import "HDNetToolMultipartFormData.h"

@implementation HDNetToolMultipartFormData

//上传文件数据初始化
- (HDNetToolMultipartFormData*)initWithFilePath:(NSString*)filepath andFileName:(NSString*)fileName andPostKey:(NSString*)postKey andHDmimeType:(HDmimeType)mimeType {
    self = [super init];
    if (self) {
        self.filePath = filepath;
        self.fileName = fileName;
        self.postKey = postKey;
        self.mimeType = mimeType;
    }
    return self;
}

//通过文件类型获取mimetype的字符串
- (NSString*)getMimeTypeStr {
    switch (self.mimeType) {
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
