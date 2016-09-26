//
//  STDBTool.h
//  STReader
//
//  Created by StriEver on 16/8/15.
//  Copyright © 2016年 StriEver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDatabaseQueue.h>
#import "Table.h"
@class FMResultSet;
typedef enum ST_DB_ActionType
{
    ST_DB_SELECT = 0,//查询操作
    ST_DB_INSERT,	 //插入操作
    ST_DB_UPDATE,	 //更新操作
    ST_DB_DELETE,	 //删除操作
    ST_DB_ADDUPDATE	 //更新或者插入操作
} ST_DB_ActionType;
@interface STDBTool : NSObject
@property(nonatomic,strong) FMDatabaseQueue *dbQueue;
@property(nonatomic,strong) FMDatabaseQueue *dbQueue2;
@property(nonatomic,strong) FMDatabaseQueue *dbQueue3;
+ (STDBTool *)shareInstance;

/**
 *  @brief             执行单个sql语句 不需要使用事务处理 根据类型确定是否返回记录集
 *
 *  @param sqlStr      sql语句 select、update或者insert into语句
 *  @param actionType  表示操作的类型，ST_DB_SELECT：查询；ST_DB_INSERT：插入；ST_DB_UPDATE：更新；ST_DB_DELETE：删除；
 *  @param block       返回执行结果
 */
-(void)executeSQL:(NSString *)sqlStr actionType:(ST_DB_ActionType)actionType withBlock:(void(^)(BOOL bRet, FMResultSet *rs, NSString *msg))block;

/**
 *  @brief             执行单个sql语句 不需要使用事务处理 根据类型确定是否返回记录集 使用dbQueue3，用于直接调用（不是封装在其他方法中）
 *
 *  @param sqlStr      sql语句 select、update或者insert into语句
 *  @param actionType  表示操作的类型，ST_DB_SELECT：查询；ST_DB_INSERT：插入；ST_DB_UPDATE：更新；ST_DB_DELETE：删除；
 *  @param block       返回执行结果
 */
- (void)execcuteQueue3Sql:(NSString *)sqlStr actionType:(ST_DB_ActionType)actionType withBlock:(void(^)(BOOL bRet, FMResultSet *rs, NSString *msg))block;


/**
 *  @brief          根据查询结果 确定是更新还是新增操作，只需要知道是否操作成功，不关心结果集 只处理一 
                    个查询更新，不需要事务处理
 *
 *  @param sqlList  sql语句数组，sqlList[0]查询select语句 sqList[1]update更新语句 sqlList[2] insert into 插入语句
 *  @param block    返回执行结果block
 */
- (void)executeRelevanceSql:(NSArray *)sqlList withBlock:(void(^)(BOOL ret,NSString * errMsg))block;

/**
 *  @brief          sqlList 是一个二维数组，每一个成员包含三个sql语句，分别是查询，更新，插入，并且           
                    据查询结果返回是执行更新 还是 插入操 作。使用dbQueue2 用于直接调用。批量处理，使用事务
 *
 *  @param sqlList  sql语句数组，sqlArr[i][0]：查询语句；sqlArr[i][1]：update语句；sqlArr[i][2]：insert into语句
 *  @param block    返回执行结果的block
 */
- (void)executeDbQueue2RelevanceTransactionSqlList:(NSArray *)sqlList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block;

/*
 *   @brief                               sql语句数组中每个成员有2条语句，第一条是select语句，第二
                                          条是insert into语句，
                                          根据第一个sql的执行结果确定执行第二条语句是否执行。
                                          根据查询结果确定是否新增，批量处理，不需要返回记录集
                                          使用dbQueue2，用于程序中直接调用（非封装在其他方法中）
 *
 *  @param  sqlArray                      sql语句数组，sqlArr[i][0]：查询语句；sqlArr[i][1]：insert into语句
 *
 *  @param  block                         返回执行结果的block
 */
-(void)executeInsertTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block;


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
-(void)executeUpdateTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block;



/*
 *  @brief                              批量处理更新或者新增sql语句，并且不需要返回记录集，使用事务处理
 *
 *  @param  sqlStrList                  sql语句数组update或者insert into语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeTransactionSqlList:(NSArray *)sqlStrList withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block;


/*
 *  @brief                              批量处理更新或者新增sql语句，并且不需要返回记录集 使用dbQueue2 防止嵌套 死循环
 *
 *  @param  sqlStrArr                   sql语句数组update或者insert into语句
 *
 *  @param  block                       返回执行结果的block
 */
-(void)executeDbQueue2TransactionSqlList:(NSArray *)sqlStrArr withBlock:(void(^)(BOOL bRet, NSString *msg, BOOL *bRollback))block;
/**
 *  @brief                  批量处理更新或者新增sql语句，不需要返回记录集  无事务处理
 *
 *  @param sqlStrList       sql语句数组update或者insert into语句
 *  @param db               FMDatabase数据库对象
 *  @param block            返回执行结果的block
 */

- (void)executeSQLList:(NSArray *)sqlStrList db:(FMDatabase *)db withBlock:(void(^)(BOOL bRet, NSString *msg))block;

/**
 *  @brief                  批量处理更新或者新增sql语句，不需要返回记录集  无事务处理
 *
 *  @param sqlStrList       sql语句数组update或者insert into语句
 *  @param block            返回执行结果的block
 */
- (void)executeSQLList:(NSArray *)sqlStrList  withBlock:(void(^)(BOOL bRet, NSString *msg))block;
@end
