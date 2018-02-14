//
//  HDNetReciveParamCheck.h
//  HDUser
//
//  Created by Damon on 2017/7/19.
//  Copyright © 2017年 shuni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDNetToolDefConfig.h"

@interface HDNetReciveParamCheckTools : NSObject


/**
 初始化操作

 为了在检测出错的时候，将值传出来
 @param dic 要检测的返回的数据，需要是检测json层级的上一级，
 例如要检测l1_2_1，dic的传值就是l1["l1_2"]
 {
    "l1": {
        "l1_2": {
            "l1_2_1": 121
        }
    }
}
 @param url 发起请求的URL
 @param param 发起请求的参数
 @return 初始化完成
 */
-(instancetype)initWithDictionary:(NSDictionary*)dic withPostErrorWithUrl:(NSString*)url param:(NSDictionary*)param;


/**
 添加检测的字段

 @param name 字段key值
 @param paramType 字段指定的类型
 @param canNil 是否可空
 */
-(void)addCheckParamName:(NSString*)name withType:(HDNetErrorParamType)paramType canNil:(BOOL)canNil;


/**
 批量添加检测的字段，全部为空，或者全部不能为空

 @param nameArray 字段key值的数组
 @param paramTypeArray 类型数组
 @param canNil 是否全部可空
 */
-(void)addCheckParamNameArray:(NSArray*)nameArray withTypeArray:(NSArray*)paramTypeArray canNilTotal:(BOOL)canNil;


/**
 批量添加检测的字段

 @param nameArray 字段key值的数组
 @param paramTypeArray 类型数组
 @param canNilArray 是否可空数组
 */
-(void)addCheckParamNameArray:(NSArray*)nameArray withTypeArray:(NSArray*)paramTypeArray canNilArray:(NSArray*)canNilArray;


/**
 开始检测是否符合要求

 @param competionHandler 检测完成后发生的回调
 @return 是否符合要求
 */
-(BOOL)startCheckReciveParam:(HDNetToolReciveParamCheckCompetionHandler)competionHandler;

@end
