//
//  WZZExceptionManager.h
//  WZZExcptionDemo
//
//  Created by 王泽众 on 2017/9/25.
//  Copyright © 2017年 王泽众. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WZZExceptionModel;

@interface WZZExceptionManager : NSObject

/**
 异常数组
 */
@property (nonatomic, strong) NSMutableArray <WZZExceptionModel *>* expArr;

/**
 异常回调
 */
@property (nonatomic, strong) void(^getExceptionBlock)(WZZExceptionModel * model, NSException * orgException);

/**
 扩展字段
 */
@property (nonatomic, strong) NSString * extStr;

/**
 单例
 */
+ (instancetype)shareInstance;

/**
 初始化
 */
- (void)setupManager;

/**
 手动保存异常
 */
- (void)saveException:(NSException *)exception;

/**
 清除异常表数据
 */
- (void)cleanExcTableData;

/**
 删除数据

 @param eid 异常id
 */
- (void)removeExcDataWithId:(NSString *)eid;

/**
 删除数据

 @param index 第几个
 */
- (void)removeExcDataWithIndex:(NSInteger)index;

/**
 获取异常数据
 */
- (NSArray <WZZExceptionModel *>*)loadExcData;

@end

@interface WZZExceptionModel :NSObject<NSCoding>

/**
 id
 */
@property (nonatomic, strong) NSString * eid;

/**
 时间
 */
@property (nonatomic, strong) NSString * time;

/**
 名字
 */
@property (nonatomic, strong) NSString * name;

/**
 原因
 */
@property (nonatomic, strong) NSString * reason;

/**
 堆栈
 */
@property (nonatomic, strong) NSString * stack;

/**
 堆栈json
 */
@property (nonatomic, strong) NSString * stackJson;

/**
 扩展字段
 */
@property (nonatomic, strong) NSString * externStr;

/**
 转换成字典

 @return 字典
 */
- (NSDictionary *)toDic;

/**
 转换成json

 @return json
 */
- (NSString *)toJson;

/**
 转换自己为data

 @return 转换自己为data
 */
- (NSData *)archiveSelf;

@end
