//
//  STDBTool.m
//  STReader
//
//  Created by StriEver on 16/8/15.
//  Copyright © 2016年 StriEver. All rights reserved.
//

#import "STDBTool.h"
#import "DBDefine.h"
#import <FMDB.h>
@implementation STDBTool
static STDBTool *sharedManager=nil;
+ (STDBTool *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[STDBTool alloc]init];
    });
    return sharedManager;
}
- (instancetype)init{
    if (self = [super init]) {
        NSFileManager * fmManger = [NSFileManager defaultManager];
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * dbPath = [NSString stringWithFormat:@"%@/BookData.db",[paths count] > 0 ? paths.firstObject : nil];
//        dbPath = [dbPath stringByAppendingPathComponent:ST_DB_NAME];
        if (![fmManger fileExistsAtPath:dbPath]) {
            [fmManger createFileAtPath:dbPath contents:nil attributes:nil];
        }
        self.dbQueue  = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        self.dbQueue2 = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        self.dbQueue3 = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        [self updateDbVersion:ST_DB_NEWVERSION];
    }
    return self;
}
//更新数据库
- (void)updateDbVersion:(NSInteger)newVersion{
    //执行数据库更新
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [self getCurrentDbVersion:db withBlock:^(BOOL bRet, int version) {
            if (bRet && (newVersion > version || newVersion == 0) ) {
                //如果本地数据库版本需要升级
                [self executeSQLList:[self setSqliArray] db:db withBlock:^(BOOL bRet, NSString *msg) {
                    if (bRet) {
                        //设置数据库版本号
                        [self setNewDbVersion:newVersion db:db withBlock:^(BOOL bRet) {
                            if (bRet)
                            {
                                NSLog(@"set new db version successfully!");
                            }
                        }];
                    }
                }];
            }
        }];
    }];
    
}
- (void)getCurrentDbVersion:(FMDatabase *)db withBlock:(void(^)(BOOL bRet,int version))block{
    NSString * sql = [NSString stringWithFormat:@"PRAGMA user_version"];
    FMResultSet * rs = [db executeQuery:sql];
    int nVersion = 0;
    while ([rs next]) {
        nVersion = [rs intForColumn:@"user_version"];
    }
    [rs close];
    if ([db hadError]) {
        NSLog(@"get db version Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        block(NO,-1);
        return;
    }
    block(YES,nVersion);
}
-(void)setNewDbVersion:(NSInteger)newVersion withBlock:(void(^)(BOOL bRet))block
{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %ld",(long)newVersion];
        
        BOOL ret = [db executeUpdate:sql];
        
        if ([db hadError])
        {
            NSLog(@"get db version Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        block(ret);
    }];
}

-(void)setNewDbVersion:(NSInteger)newVersion db:(FMDatabase *)db withBlock:(void(^)(BOOL bRet))block
{
    NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %ld",(long)newVersion];
    
    BOOL ret = [db executeUpdate:sql];
    
    if ([db hadError])
    {
        NSLog(@"get db version Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    block(ret);
}


/**
 *  @brief             执行单个sql语句 不需要使用事务处理 根据类型确定是否返回记录集
 *
 *  @param sqlStr      sql语句 select、update或者insert into语句
 *  @param actionType  表示操作的类型，ST_DB_SELECT：查询；ST_DB_INSERT：插入；ST_DB_UPDATE：更新；ST_DB_DELETE：删除；
 *  @param block       返回执行结果
 */
-(void)executeSQL:(NSString *)sqlStr actionType:(ST_DB_ActionType)actionType withBlock:(void(^)(BOOL bRet, FMResultSet *rs, NSString *msg))block{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (actionType == ST_DB_SELECT) {
            //查询语句 需要返回记录集
          FMResultSet * rs = [db executeQuery:sqlStr];
            if ([db hadError]) {
                block(NO,rs,[db lastErrorMessage]);
                NSLog(@"executeSQL error %d:  %@",[db lastErrorCode],[db lastErrorMessage]);
            }else{
                block(YES,rs,nil);
            }
        }else{
            //更新操作 只关心操作是否执行成功，不关心记录集  返回布尔值  无执行结果
            BOOL ret = [db executeUpdate:sqlStr];
            if ([db hadError]) {
                block(NO,nil,[db lastErrorMessage]);
                NSLog(@"executeSQL error %d:  %@",[db lastErrorCode],[db lastErrorMessage]);
            }else{
                block(ret,nil,nil);
            }
        }
    }];
}
/**
 *  @brief             执行单个sql语句 不需要使用事务处理 根据类型确定是否返回记录集 使用dbQueue3，用于直接调用（不是封装在其他方法中）
 *
 *  @param sqlStr      sql语句 select、update或者insert into语句
 *  @param actionType  表示操作的类型，ST_DB_SELECT：查询；ST_DB_INSERT：插入；ST_DB_UPDATE：更新；ST_DB_DELETE：删除；
 *  @param block       返回执行结果
 */
- (void)execcuteQueue3Sql:(NSString *)sqlStr actionType:(ST_DB_ActionType)actionType withBlock:(void(^)(BOOL bRet, FMResultSet *rs, NSString *msg))block{
    [_dbQueue3 inDatabase:^(FMDatabase *db) {
        if (actionType == ST_DB_SELECT) {
            FMResultSet * rs = [db executeQuery:sqlStr];
            if ([db hadError]) {
                block(NO,nil,[db lastErrorMessage]);
                NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }else{
                block(YES,rs,nil);
            }
        }else{
            BOOL ret  = [db executeUpdate:sqlStr];
            if ([db hadError]) {
                block(NO,nil,[db lastErrorMessage]);
                NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }else{
                block(ret,nil,nil);
            }
        }
    }];
}

/**
 *  @brief          根据查询结果 确定是更新还是新增操作，只需要知道是否操作成功，不关心结果集 只处理一个查询更新，不需要事务处理
 *
 *  @param sqlList  sql语句数组，sqlList[0]查询select语句 sqList[1]update更新语句 sqlList[2] insert into 插入语句
 *  @param block    返回执行结果block
 */
- (void)executeRelevanceSql:(NSArray *)sqlList withBlock:(void(^)(BOOL ret,NSString * errMsg))block{
    __block BOOL ret;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sqlList[0]];
        if ([db hadError]) {
            block(NO,[db lastErrorMessage]);
            NSLog(@"da_error_%@",[db lastErrorMessage]);
        }
        int nCount = 0;
        if ([rs next]) {
            //获取查询数据的个数
            nCount = [rs intForColumnIndex:0];
        }
        [rs close];
        
        NSString * nextSqlString = nil;
        if (nCount > 0) {
            //查询到了结果  执行update操作
            nextSqlString = sqlList[1];
        }else{
            //查询无结果  执行 insert into 操作
            nextSqlString = sqlList[2];
        }
        
        ret = [db executeUpdate:nextSqlString];
        if ([db hadError]) {
            block(NO,[db lastErrorMessage]);
            NSLog(@"da_error_%@",[db lastErrorMessage]);
        }else{
            block(ret, nil);
        }
    }];

}
/**
 *  @brief          sqlList 是一个二维数组，每一个成员包含三个sql语句，分别是查询，更新，插入，并且根据查询结果返回是执行更新 还是 插入操
                    作。使用dbQueue2 用于直接调用。批量处理，使用事务
 *
 *  @param sqlList  sql语句数组，sqlArr[i][0]：查询语句；sqlArr[i][1]：update语句；sqlArr[i][2]：insert into语句
 *  @param block    返回执行结果的block
 */
- (void)executeDbQueue2RelevanceTransactionSqlList:(NSArray *)sqlList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block{
    __block BOOL ret = NO;
    [_dbQueue2 inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSArray * singleSqlList in sqlList ) {
            FMResultSet * rs = [db executeQuery:singleSqlList[0]];
            if ([db hadError]) {
                block(NO,[db lastErrorMessage],rollback);
                NSLog(@"da_error_%@",[db lastErrorMessage]);
            }else{
                int nCount = 0;
                while ([rs next]){
                    nCount  = [rs intForColumnIndex:0];
                }
                [rs close];
                
                NSString * nextSqlString = nil;
                if (nCount > 0){
                    //执行更新
                    nextSqlString = singleSqlList[1];
                }
                else{
                    //执行插入
                    nextSqlString = singleSqlList[2];
                }
                
                 ret = [db executeUpdate:nextSqlString];
                if ([db hadError])
                {
                    block(NO, [db lastErrorMessage], rollback);
                    NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                }
            }
        }
         block(ret, nil, rollback);
    }];
}

/*
 *  @brief                              sql语句数组中每个成员有2条语句，第一条是select语句，第二条是insert into语句，
 *                                      根据第一个sql的执行结果确定执行第二条语句是否执行。
 *                                      根据查询结果确定是否新增，批量处理，不需要返回记录集
 *                                      使用dbQueue2，用于程序中直接调用（非封装在其他方法中）
 *
 *  @param  sqlArray                    sql语句数组，sqlArr[i][0]：查询语句；sqlArr[i][1]：insert into语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeInsertTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block
{
    __block BOOL ret = NO;
     NSLog(@"开始啦---");
    [_dbQueue2  inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        for (NSArray *sqlArray in sqlStrList){
            FMResultSet *rs = [db executeQuery:[sqlArray objectAtIndex:0]];
            if ([db hadError]){
                block(NO, [db lastErrorMessage], rollback);
                NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
            
            int nCount = 0;
            while ([rs next]){
                nCount = [rs intForColumnIndex:0];
            }
            [rs close];
            
            if (nCount <= 0){
                ret = [db executeUpdate:[sqlArray objectAtIndex:1]];
                if ([db hadError])
                {
                    block(NO, [db lastErrorMessage], rollback);
                    NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                }
            }
        }
        block(ret, nil, rollback);
    }];
}

/*
 *  @brief                              sql语句数组中每个成员有2条语句，第一条是select语句，第二条是update语句，
 *                                      根据第一个sql的执行结果确定执行第二条语句是否执行。
 *                                      根据查询结果确定是否更新，批量处理，不需要返回记录集
 *                                      使用dbQueue2，用于程序中直接调用（非封装在其他方法中）
 *
 *  @param  sqlArray                    sql语句数组，sqlArr[i][0]：查询语句；sqlArr[i][1]：update语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeUpdateTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block
{
    __block BOOL ret = NO;
    [_dbQueue2  inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        for (NSArray *sqlArray in sqlStrList){
            FMResultSet *rs = [db executeQuery:[sqlArray objectAtIndex:0]];
            if ([db hadError]){
                block(NO, [db lastErrorMessage], rollback);
                NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
            
            int nCount = 0;
            while ([rs next]){
                nCount = [[rs objectForColumnName:@"numbers"] intValue];
            }
            [rs close];
            
            if (nCount > 0){
                ret = [db executeUpdate:[sqlArray objectAtIndex:1]];
                if ([db hadError]){
                    block(NO, [db lastErrorMessage], rollback);
                    NSLog(@"executeSql Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                }
            }
        }
        block(ret, nil, rollback);
    }];
}

/*
 *  @brief                              批量处理更新或者新增sql语句，并且不需要返回记录集，使用事务处理
 *
 *  @param  sqlStrList                  sql语句数组update或者insert into语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block
{
    __block BOOL bRet = NO;
    [_dbQueue  inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        for (NSString *sqlStr in sqlStrList)
        {
            bRet = [db executeUpdate:sqlStr];
            if ([db hadError])
            {
                block(bRet, [db lastErrorMessage], rollback);
                NSLog(@"executeSQLList Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                break;
            }
        }
        block(bRet, nil, rollback);
    }];
}

/*
 *  @brief                              批量处理更新或者新增sql语句，并且不需要返回记录集 使用dbQueue2 防止嵌套 死循环
 *
 *  @param  sqlStrArr                   sql语句数组update或者insert into语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeDbQueue2TransactionSqlList:(NSArray *)sqlStrArr withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block
{
    __block BOOL bRet = NO;
    NSLog(@"开始插入啦---");
    [_dbQueue2  inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        for (NSString *sqlStr in sqlStrArr)
        {
            bRet = [db executeUpdate:sqlStr];
            if ([db hadError])
            {
                block(bRet, [db lastErrorMessage], rollback);
                NSLog(@"executeSQLList Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                break;
            }
        }
        block(bRet, nil, rollback);
    }];
}

/**
 *  @brief                  批量处理更新或者新增sql语句，不需要返回记录集  无事务处理
 *
 *  @param sqlStrList       sql语句数组update或者insert into语句
 *  @param db               FMDatabase数据库对象
 *  @param block            返回执行结果的block
 */
- (void)executeSQLList:(NSArray *)sqlStrList db:(FMDatabase *)db withBlock:(void(^)(BOOL bRet, NSString *msg))block{
    __block BOOL bRet = NO;
    for (NSString * sqlString in sqlStrList) {
        bRet = [db executeUpdate:sqlString];
        if ([db hadError]) {
            block(bRet,[db lastErrorMessage]);
            NSLog(@"executeSQLList Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            break;
        }
    }
    block(bRet,nil);
    
}


/**
 *  @brief                  批量处理更新或者新增sql语句，不需要返回记录集  无事务处理
 *
 *  @param sqlStrList       sql语句数组update或者insert into语句
 *  @param block            返回执行结果的block
 */
- (void)executeSQLList:(NSArray *)sqlStrList  withBlock:(void(^)(BOOL bRet, NSString *msg))block{
    __block BOOL bRet = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        for (NSString * sql in sqlStrList) {
           bRet = [db executeUpdate:sql];
            if ([db hadError]) {
                block(bRet,[db lastErrorMessage]);
                NSLog(@"executeSQLList Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                break;
            }
        }
    }];
     block(bRet,nil);
}
//插入创建表数组
- (NSArray *)setSqliArray{
    NSMutableArray * sqlList = @[].mutableCopy;
    [sqlList addObject:ST_TB_CREATE_BOOKINFO];
    [sqlList addObject:ST_DB_CREATE_BOOKCHAPTERINFO];
    [sqlList addObject:ST_TB_CREATE_CFG];
    return sqlList;
}
- (void)clearDb{
    
}
@end
