//
//  WZZExceptionManager.h
//  WZZExcptionDemo
//
//  Created by 王泽众 on 2017/9/25.
//  Copyright © 2017年 王泽众. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMDatabase;

@interface WZZExceptionManager : NSObject
{
    @public
    //一般用不到，防止滥用所以写在这里
    FMDatabase * fmdb;//数据库
    void (^_getExceptionBlock)(NSString *, NSString *, NSString *, NSString *, NSArray *, NSException *);//异常回调
    NSString * _uid;//用户id
    NSString * _phone;//手机
    NSString * _version;//app版本
}

/**
 单例
 */
+ (instancetype)shareInstance;

/**
 初始化
 */
- (void)setupManager;

/**
 配置用户id和手机号
 */
- (void)setUserId:(NSString *)uid
            phone:(NSString *)phone;

/**
 设置版本号
 */
- (void)setVersion:(NSString *)version;

/**
 异常回调
 一般不用实现
 */
- (void)getExceptionBlock:(void(^)(NSString * etime, NSString * ename, NSString * ereason, NSString * estack, NSArray * callStackArray, NSException * exception))aBlock;

/**
 手动保存异常
 */
- (void)saveException:(NSException *)exception;

/**
 清除异常表数据
 */
- (void)cleanExcTableData;

/**
 删除某条数据
 */
- (void)removeExcDataWithId:(NSString *)eid;

/**
 获取异常数据
 */
- (NSArray *)loadExcData;

/**
 json转对象
 */
+ (id)jsonToObject:(NSString *)jsonString;

/**
 对象转json字符串
 */
+ (NSString *)objectToJson:(id)object;

@end
