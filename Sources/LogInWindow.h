//
//  LogInWindow.h
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT void logInWindow(bool flag);

/** 使log信息显示在屏幕上
 当调用NSLog方法时(或手动调用println方法)会显示在window上, 同时控制台也会输出

 0.0.1: hook了NSLog方法
 0.0.2增加: hook writev方法, 用来兼容DDTTYLogger在控制台的输出;
 0.0.3增加: hook fwrite 和 __swbuf方法 用来兼容swift
 0.0.4: 优化逻辑
 0.0.5: fix NSLog和writev打印重复的问题
 0.1.0: 适配Swift5.x
 */
@interface logInWindowManager : NSObject
@end

