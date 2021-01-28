//
//  ViewController.m
//  Sample
//
//  Created by 赵国庆 on 2017/5/24.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "ViewController.h"

#define ddLogLevel DDLogLevelAll

@import CocoaLumberjack;

@import LogInWindow;

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    logInWindow(YES);
    
    NSLog(@"NSLog: 0123456789");
    NSLog(@"NSLog: abcdefghigklmnopqrstuvwxyz");
    NSLog(@"NSLog: 北京欢迎你");
    NSLog(@"NSLog: *^(*&()åß∂çåß∂ƒœ∑¥øµ≤åß∫∂çø…ƒπœ∑¬µ√÷“æ˙¡ª•§");
    NSLog(@"NSLog: 예사소리/평음い　うけ か　さ た　 に ぬ の ま み め も り る");
    NSLog(@"NSLog: %s", [@"asd0123" cStringUsingEncoding:(NSUTF8StringEncoding)]);
    
    [DDLog addLogger:[DDOSLogger sharedInstance]]; // Uses os_log
    
    
    DDLogInfo(@"DDLog: 0123456789");
    DDLogInfo(@"DDLog: abcdefghigklmnopqrstuvwxyz");
    DDLogInfo(@"DDLog: 北京欢迎你");
    DDLogInfo(@"DDLog: *^(*&()åß∂çåß∂ƒœ∑¥øµ≤åß∫∂çø…ƒπœ∑¬µ√÷“æ˙¡ª•§");
    DDLogInfo(@"DDLog: 예사소리/평음い　うけ か　さ た　 に ぬ の ま み め も り る");
    DDLogInfo(@"DDLog: %s", [@"asd0123" cStringUsingEncoding:(NSUTF8StringEncoding)]);
}


@end
