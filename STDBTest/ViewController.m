//
//  ViewController.m
//  STDBTest
//
//  Created by StriEver on 16/9/25.
//  Copyright © 2016年 StriEver. All rights reserved.
//

#import "ViewController.h"
#import "STDBTool.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    dispatch_queue_t queue1 = dispatch_queue_create("com.dispatch.serial", DISPATCH_QUEUE_SERIAL);
//    dispatch_queue_t queue2 = dispatch_queue_create("com.dispatch.seria2", DISPATCH_QUEUE_SERIAL);
//    dispatch_sync(queue1, ^{
//        NSLog(@"执行1%@",[NSThread currentThread]);
//        dispatch_sync(queue2, ^{
//            NSLog(@"执行2%@",[NSThread currentThread]);
//            　　});
//        　});
    // Do any additional setup after loading the view, typically from a nib.
    [STDBTool shareInstance];
    //[self useTransactionInsertData];
    [self insertData];
    
    
}
//使用事务插入1000000数据
- (void)useTransactionInsertData{
    NSMutableArray * sqlList = @[].mutableCopy;
    for (int i = 0 ;i < 100;i ++) {
        NSString * sql = [NSString stringWithFormat:@"INSERT INTO %@ (bookId,file_version,hot_sort,pic,name,path,time) VALUES (%d,'%@','%@','%@','%@','%@',%f)",ST_TB_NAME_BOOKINFO,i,@"2",@"2.0.1",@"pic",@"网络小说",@"path",[[NSDate date]timeIntervalSince1970]];
        [sqlList addObject:sql];
    }
    NSLog(@"开始插入数据%@",[NSDate date]);
    [[STDBTool shareInstance]executeTransactionSqlList:sqlList withBlock:^(BOOL bRet, NSString *msg, BOOL *bRollback) {
       NSLog(@"插入数据成功%@",[NSDate date]);
    }];
}
- (void)insertData{
    NSMutableArray * sqlList = @[].mutableCopy;
    for (int i = 1000000 ;i < 2000000;i ++) {
        NSString * sql = [NSString stringWithFormat:@"INSERT INTO %@ (bookId,file_version,hot_sort,pic,name,path,time) VALUES (%d,'%@','%@','%@','%@','%@',%f)",ST_TB_NAME_BOOKINFO,i,@"2",@"2.0.1",@"pic",@"网络小说",@"path",[[NSDate date]timeIntervalSince1970]];
        [sqlList addObject:sql];
    }
    NSLog(@"无事务处理开始插入数据%@",[NSDate date]);
    [[STDBTool shareInstance]executeSQLList:sqlList withBlock:^(BOOL bRet, NSString *msg) {
      NSLog(@"无事务处理插入完成数据%@",[NSDate date]);
    }];;
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
