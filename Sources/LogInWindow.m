//
//  LogInWindow.m
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "LogInWindow.h"
#import "fishhook/fishhook.h"

@interface LogTextView : UITextView
@end

@interface OutPutWindow : UIWindow
@property (nonatomic, strong) LogTextView *textView;
@end

@interface logInWindowManager()
@property (nonatomic, strong) OutPutWindow * window;
@property (nonatomic, copy, readwrite) NSString *printString;
+ (instancetype)share;
- (void)setupInWindow;
- (void)hideFromWindow;
+ (void)print:(NSString *)msg;
@end

@implementation OutPutWindow
- (instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.windowLevel = UIWindowLevelAlert;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _textView = [[LogTextView alloc] init];
        [self addSubview:_textView];
    }
    return self;
}
@end

@implementation LogTextView

- (instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds textContainer:nil];
    if (self) {
        CGRect f = self.frame;
        f.origin.y = 20;
        f.size.height -= 20;
        self.frame = f;
        self.font = [UIFont systemFontOfSize:12];
        self.textColor = [UIColor greenColor];
        self.backgroundColor = [UIColor clearColor];
        self.scrollsToTop = false;
    }
    return self;
}
@end


static void (*orig_NSLog)(NSString *format, ...);
void(new_NSLog)(NSString *format, ...) {
    va_list args;
    if(format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        orig_NSLog(@"%@", message);
        [logInWindowManager print:message];
        va_end(args);
    }
}
void println(NSString *format, ...) {
    va_list args;
    if(format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        NSLog(@"%@", message);
        va_end(args);
    }
}

@implementation logInWindowManager
+ (instancetype)share {
    static logInWindowManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[logInWindowManager alloc] init];
        instance.window = [[OutPutWindow alloc] init];
        rebind_symbols((struct rebinding[1]){{"NSLog", new_NSLog, (void *)&orig_NSLog}}, 1);
    });
    return instance;
}

- (void)setupInWindow {
    if (![UIApplication sharedApplication].keyWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupInWindow];
        });
        return;
    }
    [self.window makeKeyAndVisible];
}

- (void)hideFromWindow {
    [self.window resignKeyWindow];
}

+ (void)print:(NSString *)msg {
    [[logInWindowManager share] addPrintWithMessage:msg];
}

- (void)addPrintWithMessage:(NSString *)msg {
    @synchronized (self) {
        if (self.window.textView.text.length) {
            self.window.textView.text = [NSString stringWithFormat:@"%@\n%@", self.window.textView.text, msg];
            [self.window.textView scrollRangeToVisible:NSMakeRange((self.window.textView.text.length - 1), 1)];
        } else {
            self.window.textView.text = msg;
            [self.window.textView scrollRangeToVisible:NSMakeRange(MAX((self.window.textView.text.length - 1), 0), msg.length ? 1 : 0)];
        }
    }
}

@end

void logInWindow(bool flag) {
    if (flag) {
        [[logInWindowManager share] setupInWindow];
    } else {
        [[logInWindowManager share] hideFromWindow];
    }
}


