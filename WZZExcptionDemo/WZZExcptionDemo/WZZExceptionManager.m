//
//  WZZExceptionManager.m
//  WZZExcptionDemo
//
//  Created by 王泽众 on 2017/9/25.
//  Copyright © 2017年 王泽众. All rights reserved.
//

#import "WZZExceptionManager.h"
#import "FMDatabase.h"
@class WZZExceptionManager;

//数据库路径
#define WZZExceptionManager_FMDBDir [NSHomeDirectory() stringByAppendingString:@"/Documents/WZZExceptionManager"]
//异常表
#define WZZExceptionManager_excTableName @"excTable"

//崩溃时的回调函数
void UncaughtExceptionHandler(NSException * exception) {
    //插入数据
    WZZExceptionManager * man = [WZZExceptionManager shareInstance];
    [man saveException:exception];
}

static WZZExceptionManager * wzzExceptionManager;

@implementation WZZExceptionManager

//单例
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wzzExceptionManager = [[WZZExceptionManager alloc] init];
        NSFileManager * manager = [NSFileManager defaultManager];
        //文件夹不存在创建
        BOOL isExexutable = [manager isExecutableFileAtPath:WZZExceptionManager_FMDBDir];
        if (!isExexutable) {
            [manager createDirectoryAtPath:WZZExceptionManager_FMDBDir withIntermediateDirectories:NO attributes:nil error:nil];
        }
    });
    return wzzExceptionManager;
}

//初始化
- (void)setupManager {
    BOOL openDBOK = NO;
    BOOL openTableOK = NO;
    
    
    //创建db
    NSString * dbStr = [WZZExceptionManager_FMDBDir stringByAppendingString:@"/exceptionDB.db"];
    NSLog(@"数据库地址:%@", dbStr);
    fmdb = [FMDatabase databaseWithPath:dbStr];
    openDBOK = [fmdb open];
    if (openDBOK) {
        NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    }
    
    //创建表
    openTableOK = [fmdb executeUpdate:[NSString stringWithFormat:@"create table if not exists %@(eid integer primary key autoincrement, etime integer, ename text, ereason text, estack text, euser text, ephone text, eextern text);", WZZExceptionManager_excTableName]];
    if (openTableOK) {
        NSLog(@"创建异常表OK");
    }
}

//配置用户id和手机
- (void)setUserId:(NSString *)uid
            phone:(NSString *)phone {
    _uid = uid;
    _phone = phone;
}

//设置版本号
- (void)setVersion:(NSString *)version {
    _version = version;
}

//异常回调
- (void)getExceptionBlock:(void (^)(NSString *, NSString *, NSString *, NSString *, NSArray *, NSException *))aBlock {
    _getExceptionBlock = aBlock;
}

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
    NSTimeInterval dateInteger = [[NSDate date] timeIntervalSince1970];
    
    if (!_version) {
        NSString * versionInfo = [WZZExceptionManager objectToJson:[[NSBundle mainBundle] infoDictionary]];
        _version = versionInfo;
    }
    
    NSString * version = _version?_version:@"no ext";
    id extObj = [WZZExceptionManager jsonToObject:version];
    NSDictionary * extDic = @{@"appversion":extObj?extObj:version};
    NSString * extJsonStr = [NSString stringWithFormat:@"%@", [WZZExceptionManager objectToJson:extDic]];
    
    [self->fmdb executeUpdate:[NSString stringWithFormat:@"insert into %@(etime, ename, ereason, estack, euser, ephone, eextern) values(?, ?, ?, ?, ?, ?, ?)", WZZExceptionManager_excTableName], [NSString stringWithFormat:@"%ld", (NSInteger)dateInteger], name?name:@"no name", reason?reason:@"no reason", callStackStr?callStackStr:@"no call stack", _uid?_uid:@"no user id", _phone?_phone:@"no phone", extJsonStr];
    if (_getExceptionBlock) {
        _getExceptionBlock([NSString stringWithFormat:@"%ld", (NSInteger)dateInteger], name, reason, callStackStr, callStackArr, exception);
    }
}

//清除异常表数据
- (void)cleanExcTableData {
    [fmdb executeUpdate:[NSString stringWithFormat:@"delete from %@;", WZZExceptionManager_excTableName]];
}

//删除某条数据
- (void)removeExcDataWithId:(NSString *)eid {
    if (!eid) {
        return;
    }
    [fmdb executeUpdate:[NSString stringWithFormat:@"delete from %@ where eid=?;", WZZExceptionManager_excTableName], eid];
}

//获取异常数据
- (NSArray *)loadExcData {
    FMResultSet * result = [fmdb executeQuery:[NSString stringWithFormat:@"select * from %@", WZZExceptionManager_excTableName]];
    NSMutableArray * arr = [NSMutableArray array];
    while ([result next]) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        dic[@"eid"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"eid"]];
        dic[@"etime"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"etime"]];
        dic[@"ename"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"ename"]];
        dic[@"ereason"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"ereason"]];
        dic[@"estack"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"estack"]];
        dic[@"euser"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"euser"]];
        dic[@"ephone"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"ephone"]];
        dic[@"eextern"] = [NSString stringWithFormat:@"%@", [result stringForColumn:@"eextern"]];
        [arr addObject:dic];
    }
    return arr;
}

#pragma mark - 辅助方法
//json字符串转对象
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

//对象转json字符串
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
