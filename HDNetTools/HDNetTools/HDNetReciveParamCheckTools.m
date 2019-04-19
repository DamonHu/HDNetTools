//
//  HDNetReciveParamCheck.m
//  HDUser
//
//  Created by Damon on 2017/7/19.
//  Copyright © 2017年 shuni. All rights reserved.
//

#import "HDNetReciveParamCheckTools.h"
#import "HDNetTools.h"

@interface HDNetReciveParamCheckTools ()
@property (strong,nonatomic)NSMutableArray *paramCheckArray;  //检测的字段数组
@property (strong,nonatomic)NSDictionary *paramCheckDic;     //检测的数据

@property (strong,nonatomic)NSString *postUrl;          //请求的url
@property (strong,nonatomic)NSString *paramStr;         //请求的参数
@property (strong,nonatomic)NSString *reciveStr;        //请求的接受数据
@end

@implementation HDNetReciveParamCheckTools
- (instancetype)init DEPRECATED_MSG_ATTRIBUTE("请使用initWithFatherDictionary:withRequestUrl:andRequestParam:进行初始化") {
    return nil;
}

- (instancetype)initWithFatherDictionary:(NSDictionary *)dic withNetToolConfig:(HDNetToolConfig * _Nullable )netToolConfig {
    self = [super init];
    if (self) {
        if (dic && dic.allKeys.count > 0) {
            self.paramCheckDic = [NSDictionary dictionaryWithDictionary:dic];
            self.reciveStr = [self toJSONStr:dic];
        }
        else{
            self.paramCheckDic = nil;
            self.reciveStr = @"";
        }
        self.postUrl = netToolConfig.url;
        if (netToolConfig.requestData) {
           self.paramStr = [self toJSONStr:netToolConfig.requestData];
        }
    }
    return self;
}

- (void)addCheckParamName:(NSString *)name withType:(HDNetErrorParamType)paramType canNil:(BOOL)canNil {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:name,@"paramName",[self getClassNameByType:paramType],@"paramType",@(canNil),@"paramCannil", nil];
    [self.paramCheckArray addObject:dic];
}

- (void)addCheckParamNameArray:(NSArray *)nameArray withTypeArray:(NSArray *)paramTypeArray canNilTotal:(BOOL)canNil {
    NSString *errorStr = [NSString stringWithFormat:@"%@,%@",self.postUrl,@"数组数量不正确"];
    NSAssert(nameArray.count == paramTypeArray.count, errorStr);
    NSMutableArray *canNilArray = [NSMutableArray array];
    for (int i=0; i<nameArray.count; i++) {
        if (canNil) {
            [canNilArray addObject:@(1)];
        }
        else{
            [canNilArray addObject:@(0)];
        }
    }
    [self addCheckParamNameArray:nameArray withTypeArray:paramTypeArray canNilArray:canNilArray];
}

- (void)addCheckParamNameArray:(NSArray*)nameArray withTypeArray:(NSArray*)paramTypeArray canNilArray:(NSArray*)canNilArray
{
    NSString *errorStr = [NSString stringWithFormat:@"%@,%@",self.postUrl,@"数组数量不正确"];
    NSAssert(nameArray.count == paramTypeArray.count && paramTypeArray.count == canNilArray.count , errorStr);
    for (int i = 0; i<nameArray.count; i++) {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[nameArray objectAtIndex:i],@"paramName",[self getClassNameByType:[[paramTypeArray objectAtIndex:i] integerValue]],@"paramType",[canNilArray objectAtIndex:i],@"paramCannil", nil];
        [self.paramCheckArray addObject:dic];
    }
}

- (BOOL)startCheckReciveParam:(_Nullable HDNetToolReciveParamCheckCompetionHandler)competionHandler {
    BOOL isAccord = YES;
    NSError *error;
    WEAKSELF
    for (int i = 0; i<self.paramCheckArray.count; i++) {
        NSDictionary *dic = [self.paramCheckArray objectAtIndex:i];
        NSString *paramName = [dic objectForKey:@"paramName"];
        NSString *paramType = [dic objectForKey:@"paramType"];
        BOOL canNil = [[dic objectForKey:@"paramCannil"] boolValue];
        for (int i = 0; i<self.paramCheckDic.allKeys.count; i++) {
            NSString* key = [self.paramCheckDic.allKeys objectAtIndex:i];
            if ([key isEqualToString:paramName]) {
                if ([paramType isEqualToString:@"ParamNone"] || [[self.paramCheckDic objectForKey:key] isKindOfClass:NSClassFromString(paramType)]) {
                    if (!canNil && ![self.paramCheckDic objectForKey:key]) {
                        isAccord = NO;
                        error = [NSError errorWithDomain:NSURLErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"URL:%@ key:%@ Value can not be Nil",self.postUrl,paramName],NSLocalizedDescriptionKey, nil]];
                    }
                }
                else{
                    isAccord = NO;
                    error = [NSError errorWithDomain:NSURLErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"URL:%@ key:%@ Class error,Not:%@",self.postUrl,paramName,paramType],NSLocalizedDescriptionKey, nil]];
                }
                break;
            }
            else{
                if (!canNil && i == self.paramCheckDic.allKeys.count - 1) {
                    isAccord = NO;
                    error = [NSError errorWithDomain:NSURLErrorDomain code:102 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"URL:%@ key:%@ Not Exit",self.postUrl,paramName],NSLocalizedDescriptionKey, nil]];
                }
            }
        }
        if (!isAccord) {
            break;
        }
    }
    if (competionHandler) {
        competionHandler(isAccord,weakSelf.postUrl,weakSelf.paramStr,weakSelf.reciveStr,error);
    }
    return isAccord;
}

-(NSString*)getClassNameByType:(HDNetErrorParamType)type{
    
    switch (type) {
        case kHDNetErrorParamNone:
            return @"ParamNone";
            break;
        case kHDNetErrorParamString:
            return @"NSString";
            break;
        case kHDNetErrorParamDic:
            return @"NSDictionary";
            break;
        case kHDNetErrorParamArray:
            return @"NSArray";
            break;
        case kHDNetErrorParamNumber:
            return @"NSNumber";
            break;
        default:
            break;
    }
    return @"";
}

#pragma private methord
// 将字典或者数组转化为Data数据
- (NSData *)toJSONData:(id)theData{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData options:NSJSONWritingPrettyPrinted error:&error];
    if ([jsonData length] > 0 && error == nil){
        return jsonData;
    }else{
        return nil;
    }
}

/// 将字典或者数组转化为json字符串数据
- (NSString *)toJSONStr:(id)theData {
    NSData *jsonData = [self toJSONData:theData];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

#pragma mark -
#pragma mark - Lazyload
- (NSMutableArray *)paramCheckArray {
    if (!_paramCheckArray) {
        _paramCheckArray = [NSMutableArray array];
    }
    return _paramCheckArray;
}
@end
