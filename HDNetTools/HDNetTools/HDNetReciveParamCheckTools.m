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
@property (strong, nonatomic) NSMutableArray *paramCheckArray;  //检测的字段数组
@property (strong, nonatomic) NSDictionary *paramCheckDic;     //检测的数据
@property (strong, nonatomic) HDNetToolConfig *netToolConfig;  //请求的数据
@end

@implementation HDNetReciveParamCheckTools
#pragma mark -
#pragma mark - Lazyload
- (NSMutableArray *)paramCheckArray {
    if (!_paramCheckArray) {
        _paramCheckArray = [NSMutableArray array];
    }
    return _paramCheckArray;
}

#pragma mark - 初始化
- (instancetype)init DEPRECATED_MSG_ATTRIBUTE("请使用initWithFatherDictionary:withRequestUrl:andRequestParam:进行初始化") {
    return nil;
}

- (instancetype)initWithFatherDictionary:(NSDictionary * _Nullable)dic withNetToolConfig:(HDNetToolConfig * _Nullable )netToolConfig {
    self = [super init];
    if (self) {
        self.paramCheckDic = dic;
        self.netToolConfig = netToolConfig;
    }
    return self;
}

- (void)addCheckParamName:(NSString *)name withType:(Class)paramType canNil:(BOOL)canNil {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:name,@"paramName",paramType,@"paramType",@(canNil),@"paramCannil", nil];
    [self.paramCheckArray addObject:dic];
}

- (void)addCheckParamNameArray:(NSArray *)nameArray withTypeArray:(NSArray *)paramTypeArray canNilTotal:(BOOL)canNil {
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
    NSString *errorStr = [NSString stringWithFormat:@"%@,%@",self.netToolConfig.url,@"检测的字段和类型数组数量不正确"];
    NSAssert(nameArray.count == paramTypeArray.count && paramTypeArray.count == canNilArray.count , errorStr);
    for (int i = 0; i<nameArray.count; i++) {
        [self addCheckParamName:nameArray[i] withType:paramTypeArray[i] canNil:canNilArray[i]];
    }
}

- (void)startCheckReciveParam:(_Nullable HDNetToolReciveParamCheckCompetionHandler)competionHandler {
    BOOL isAccord = YES;
    NSError *error = nil;
    for (int i = 0; i < self.paramCheckArray.count; i++) {
        NSDictionary *dic = [self.paramCheckArray objectAtIndex:i];
        NSString *paramName = [dic objectForKey:@"paramName"];
        Class paramType = [dic objectForKey:@"paramType"];
        BOOL canNil = [[dic objectForKey:@"paramCannil"] boolValue];
        
        for (int j = 0; j < self.paramCheckDic.allKeys.count; j++) {
            NSString* key = [self.paramCheckDic.allKeys objectAtIndex:j];
            if ([key isEqualToString:paramName]) {
                if ([self.paramCheckDic objectForKey:key]) {
                    //值不为空值
                    if (![[self.paramCheckDic objectForKey:key] isKindOfClass:paramType]) {
                        isAccord = NO;
                        error = [NSError errorWithDomain:NSURLErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"URL:%@ key:%@ Class error,Not:%@",self.netToolConfig.url,paramName,paramType],NSLocalizedDescriptionKey, nil]];
                    }
                } else if (!canNil) {
                    //值为空值，但是不允许为空时
                    isAccord = NO;
                    error = [NSError errorWithDomain:NSURLErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"URL:%@ key:%@ Value can not be Nil",self.netToolConfig.url,paramName],NSLocalizedDescriptionKey, nil]];
                }
                break;
            } else {
                //字典中不存在该值
                if (!canNil && j == self.paramCheckDic.allKeys.count - 1) {
                    isAccord = NO;
                    error = [NSError errorWithDomain:NSURLErrorDomain code:102 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"URL:%@ key:%@ Not Exit",self.netToolConfig.url,paramName],NSLocalizedDescriptionKey, nil]];
                }
            }
        }
        if (!isAccord) {
            break;
        }
    }
    if (competionHandler) {
        competionHandler(isAccord,self.netToolConfig,error);
    }
}

@end
