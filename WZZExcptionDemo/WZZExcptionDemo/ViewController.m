//
//  ViewController.m
//  WZZExcptionDemo
//
//  Created by 王泽众 on 2017/9/25.
//  Copyright © 2017年 王泽众. All rights reserved.
//

#import "ViewController.h"
#import "WZZExceptionManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#if 0
    id str = @"";
    str[0];
#endif
    WZZExceptionManager * man = [WZZExceptionManager shareInstance];
    NSArray * arr = [man loadExcData];
    NSLog(@"log1:\n%@", arr);
    if (arr.count) {
        [man removeExcDataWithId:arr[0]?arr[0][@"eid"]:nil];
    }
    NSLog(@"log2:\n%@", [man loadExcData]);
}

@end
