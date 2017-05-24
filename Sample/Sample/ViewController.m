//
//  ViewController.m
//  Sample
//
//  Created by 赵国庆 on 2017/5/24.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "ViewController.h"
#import "LogInWindow.h"
#import <EPMLogger/EPMLogger.h>

@interface ViewController ()
@property (nonatomic, strong) dispatch_source_t timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [EPMLogger setup];
    
    logInWindow(YES);
    [logInWindowManager share].backgroundColor = [UIColor blueColor];
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        NSLog(@"%d", arc4random() % 9999);
    });
    dispatch_resume(_timer);
    
}


@end
