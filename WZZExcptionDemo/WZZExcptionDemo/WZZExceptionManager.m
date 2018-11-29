//
//  WZZExceptionManager.m
//  WZZExcptionDemo
//
//  Created by 王泽众 on 2017/9/25.
//  Copyright © 2017年 王泽众. All rights reserved.
//

#import "WZZExceptionManager.h"

//崩溃时的回调函数
void wzz_UncaughtExceptionHandler(NSException * exception) {
    //插入数据
    WZZExceptionManager * man = [WZZExceptionManager shareInstance];
    [man saveException:exception];
}

static WZZExceptionManager * wzzExceptionManager;

@interface WZZExceptionManager ()

/**
 最大id
 */
@property (nonatomic, strong) NSString * maxEid;

@end

@implementation WZZExceptionManager

//MARK:单例
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wzzExceptionManager = [[WZZExceptionManager alloc] init];
        [wzzExceptionManager loadExcData];
        wzzExceptionManager.maxEid = [[NSUserDefaults standardUserDefaults] objectForKey:@"WZZExceptionManager_maxEid"];
        if (!wzzExceptionManager.maxEid) {
            wzzExceptionManager.maxEid = @"0";
            [[NSUserDefaults standardUserDefaults] setObject:wzzExceptionManager.maxEid forKey:@"WZZExceptionManager_maxEid"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
    return wzzExceptionManager;
}

//MARK:初始化
- (void)setupManager {
    NSSetUncaughtExceptionHandler(&wzz_UncaughtExceptionHandler);
}

//MARK:保存异常
- (void)saveException:(NSException *)exception {
    //调用堆栈
    NSArray * callStackArr = [exception callStackSymbols];
    //调用堆栈字符串
    NSString * callStackStr = @"CallStackSymbols:";
    for (int i = 0; i < callStackArr.count; i++) {
        NSString * str = callStackArr[i];
        callStackStr = [callStackStr stringByAppendingFormat:@"\n%@", str];
    }
    //崩溃原因
    NSString * reason = [exception reason];//崩溃的原因，可以有崩溃的原因(数组越界,字典nil,调用未知方法...)崩溃的控制器以及方法
    //崩溃名字
    NSString * name = [exception name];
    //崩溃时间
    NSInteger dateInteger = [[NSDate date] timeIntervalSince1970]*1000;
    
    WZZExceptionModel * model = [[WZZExceptionModel alloc] init];
    model.eid = self.maxEid;
    model.time = @(dateInteger).stringValue;
    model.name = name;
    model.reason = reason;
    model.stack = callStackStr;
    model.stackJson = [WZZExceptionManager objectToJson:callStackArr];
    model.externStr = self.extStr;
    
    [self.expArr addObject:model];
    
    NSData * archArr = [NSKeyedArchiver archivedDataWithRootObject:self.expArr];
    [[NSUserDefaults standardUserDefaults] setObject:archArr forKey:@"WZZExceptionManager_expKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@(self.maxEid.integerValue+1).stringValue forKey:@"WZZExceptionManager_maxEid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.getExceptionBlock) {
        self.getExceptionBlock(model, exception);
    }
}

//清除异常表数据
- (void)cleanExcTableData {
    [self.expArr removeAllObjects];
    NSData * archData = [NSKeyedArchiver archivedDataWithRootObject:self.expArr];
    [[NSUserDefaults standardUserDefaults] setObject:archData forKey:@"WZZExceptionManager_expKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//删除某条数据
- (void)removeExcDataWithId:(NSString *)eid {
    if (!eid) {
        return;
    }
    NSInteger removeIdx = -1;
    for (int i = 0; i < self.expArr.count; i++) {
        WZZExceptionModel * expModel = self.expArr[i];
        if ([expModel.eid isEqualToString:eid]) {
            removeIdx = i;
        }
    }
    if (removeIdx >= 0) {
        [self.expArr removeObjectAtIndex:removeIdx];
    }
    
    NSData * archData = [NSKeyedArchiver archivedDataWithRootObject:self.expArr];
    [[NSUserDefaults standardUserDefaults] setObject:archData forKey:@"WZZExceptionManager_expKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//删除数据
- (void)removeExcDataWithIndex:(NSInteger)index {
    if (index >= 0 && index < self.expArr.count) {
        [self.expArr removeObjectAtIndex:index];
    }
    
    NSData * archData = [NSKeyedArchiver archivedDataWithRootObject:self.expArr];
    [[NSUserDefaults standardUserDefaults] setObject:archData forKey:@"WZZExceptionManager_expKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//获取异常数据
- (NSArray <WZZExceptionModel *>*)loadExcData {
    if (!self.expArr) {
        NSData * archData = [[NSUserDefaults standardUserDefaults] objectForKey:@"WZZExceptionManager_expKey"];
        self.expArr = [NSKeyedUnarchiver unarchiveObjectWithData:archData];
        if (!self.expArr) {
            self.expArr = [NSMutableArray array];
        }
    }
    return self.expArr;
}

#pragma mark - 工具
//MARK:json字符串转对象
+ (id)jsonToObject:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return object;
}

//MARK:对象转json字符串
+ (NSString *)objectToJson:(id)object {
    if (object == nil) {
        return nil;
    }
    NSError * err = nil;
    NSData * data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@implementation WZZExceptionModel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _eid = [aDecoder decodeObjectForKey:@"WZZExceptionModel_eid"];
        _time = [aDecoder decodeObjectForKey:@"WZZExceptionModel_time"];
        _name = [aDecoder decodeObjectForKey:@"WZZExceptionModel_name"];
        _reason = [aDecoder decodeObjectForKey:@"WZZExceptionModel_reason"];
        _stack = [aDecoder decodeObjectForKey:@"WZZExceptionModel_stack"];
        _stackJson = [aDecoder decodeObjectForKey:@"WZZExceptionModel_stackJson"];
        _externStr = [aDecoder decodeObjectForKey:@"WZZExceptionModel_externStr"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_eid forKey:@"WZZExceptionModel_eid"];
    [aCoder encodeObject:_time forKey:@"WZZExceptionModel_time"];
    [aCoder encodeObject:_name forKey:@"WZZExceptionModel_name"];
    [aCoder encodeObject:_reason forKey:@"WZZExceptionModel_reason"];
    [aCoder encodeObject:_stack forKey:@"WZZExceptionModel_stack"];
    [aCoder encodeObject:_stackJson forKey:@"WZZExceptionModel_stackJson"];
    [aCoder encodeObject:_externStr forKey:@"WZZExceptionModel_externStr"];
}

- (NSData *)archiveSelf {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (NSDictionary *)toDic {
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    dic[@"eid"] = _eid;
    dic[@"time"] = _time;
    dic[@"name"] = _name;
    dic[@"reason"] = _reason;
    dic[@"stack"] = _stack;
    dic[@"stackJson"] = _stackJson;
    dic[@"externStr"] = _externStr;
    return dic;
}

- (NSString *)toJson {
    return [WZZExceptionManager objectToJson:[self toDic]];
}

@end
