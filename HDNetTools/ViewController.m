//
//  ViewController.m
//  netTools
//
//  Created by Damon on 2018/1/6.
//  Copyright © 2018年 damon. All rights reserved.
//

#import "ViewController.h"
#import "HDNetTools/HDNetTools.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //添加网络状态变化时的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netChange:) name:HDNetworkingReachabilityDidChangeNotification object:nil];
    ///开始检测网络状态
    [HDNetTools startNetMonitoring];
    //发送请求的按钮
    NSArray *titleArray = [NSArray arrayWithObjects:@"发起post请求",@"检测返回数据格式",@"下载文件", nil];
    for (int i=0; i<titleArray.count; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 100+i*100, 200, 50)];
        [button setBackgroundColor:[UIColor redColor]];
        [button setTitle:[titleArray objectAtIndex:i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTag:i];
        [button addTarget:self action:@selector(startTest:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

-(void)startTest:(UIButton*)button{
    int tag = (int)button.tag;
    switch (tag) {
        case 0:{
            [self testPostRequst];
        }
            break;
        case 1:{
            [self testPostReciveParamCheck];
        }
            break;
        case 2:{
            [self testFileDownload];
        }
            break;
        default:
            break;
    }
}

-(void)testPostRequst{
    //普通post请求
    NSString *url=[NSString stringWithFormat:@"https://api.tianapi.com/wxnew/?key=c9c06e42004367180cd41f5ca34297f5&num=%ld&rand=1&page=%ld",(long)2,(long)1];
    HDNetToolConfig *netToolsConfig = [[HDNetToolConfig alloc] initWithUrl:url];
    netToolsConfig.showProgressHUD = true;
    netToolsConfig.canTouchWhenRequest = false;
    netToolsConfig.maskColor = [UIColor redColor];
    netToolsConfig.retryTimeInterval = 5;
    netToolsConfig.retryCount = 10;
    NSURLSessionTask *task = [HDNetTools startRequestWithHDNetToolConfig:netToolsConfig CompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        NSLog(@"%@",responseObject);
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"%p",task);
    }];
}

-(void)testPostReciveParamCheck{
    NSString *url=[NSString stringWithFormat:@"https://api.tianapi.com/wxnew/?key=c9c06e42004367180cd41f5ca34297f5&num=%ld&rand=1&page=%ld",(long)2,(long)1];
    HDNetToolConfig *netToolsConfig = [[HDNetToolConfig alloc] initWithUrl:url];
    
    [HDNetTools startRequestWithHDNetToolConfig:netToolsConfig WithType:HDNetToolRequestTypeGet andCompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        //检测返回的类型是不是指定类型
        HDNetReciveParamCheckTools *checkTools = [[HDNetReciveParamCheckTools alloc] initWithDictionary:[[responseObject objectForKey:@"newslist"] objectAtIndex:0] withPostErrorWithUrl:netToolsConfig.url param:netToolsConfig.requestData];
        //设置检测title是否是数字，并且不可空
        [checkTools addCheckParamName:@"title" withType:kHDNetErrorParamNumber canNil:NO];
        //判断可以用下面三种方式
        //1、可以在block里面回调，直接写逻辑
        [checkTools startCheckReciveParam:^(BOOL isAccord, NSString *url, NSString *param, NSString *value, NSString *errorStr) {
            if (isAccord) {
                NSLog(@"1111检测通过");
            }else{
                NSLog(@"1111检测不通过,不通过的参数是:url:%@,param:%@,value:%@,errorStr:%@",url,param,value,errorStr);
            }
        }];
        //2、也可以不使用block，只判断返回值写逻辑
        if ([checkTools startCheckReciveParam:nil]) {
            NSLog(@"2222检测通过");
        }
        else{
            NSLog(@"2222检测不通过");
        }
        //3、或者使用回调和判断返回值同时执行
        if ([checkTools startCheckReciveParam:^(BOOL isAccord, NSString *url, NSString *param, NSString *value, NSString *errorStr) {
            if (isAccord) {
                NSLog(@"33333检测通过");
            }else{
                NSLog(@"3333检测不通过,不通过的参数是:url:%@,param:%@,value:%@,errorStr:%@",url,param,value,errorStr);
            }
        }]) {
            NSLog(@"3333检测不通过,不通过的参数是");
        }
        else{
            NSLog(@"3333检测不通过");
        }
    }];
}

-(void)testFileDownload{
    NSString *urlStr = @"https://app.huaimayi.com/qian/2018-01-01.jpg";
    HDNetToolConfig *netToolConfig = [[HDNetToolConfig alloc] initWithUrl:urlStr];
    WEAKSELF
    [HDNetTools startRequestWithHDNetToolConfig:netToolConfig WithType:HDNetToolRequestTypeGetDownLoadFile andCompleteCallBack:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        else{
            NSURL *filePath = responseObject;
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:[HDNetTools conVertToStr:filePath]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 300, 300)];
            [imageView setImage:image];
            [weakSelf.view addSubview:imageView];
        }
    }];
    
}

///网络状态变化的通知
-(void)netChange:(NSNotification*)notification{
    HDNetReachabilityStatus status = [[notification.userInfo objectForKey:HDNetworkingReachabilityNotificationStatusItem] integerValue];
    NSLog(@"%ld",(long)status);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

