//
//  LogInWindow.h
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT void logInWindow(bool flag);

FOUNDATION_EXPORT void println(NSString *format, ...);

/** 使log信息显示在屏幕上
 hook了NSLog方法
 当调用NSLog方法时(或手动调用println方法)会显示在window上, 同时控制台也会输出
 
 
 TODO: 增加滚动和隐藏
 */
@interface logInWindowManager : NSObject
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, copy, readonly) NSString *printString;

+ (instancetype)share;
- (void)setupInWindow;
- (void)hideFromWindow;
- (void)addPrintWithMessage:(NSString *)msg;
@end
