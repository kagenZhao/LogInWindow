//
//  LogInWindow.m
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "LogInWindow.h"
#import "fishhook/fishhook.h"

void logInWindow(bool flag) {
    if (flag) {
        [[logInWindowManager share] setupInWindow];
    } else {
        [[logInWindowManager share] hideFromWindow];
    }
}

static void (*orig_NSLog)(NSString *format, ...);
void(new_NSLog)(NSString *format, ...) {
    va_list args;
    if(format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [[logInWindowManager share] addPrintWithMessage:message];
        orig_NSLog(@"%@", message);
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

@interface LogTextView : UITextView
@end

@interface OutPutWindow : UIWindow
@property (nonatomic, strong) LogTextView *textView;
@end

@interface logInWindowManager()
@property (nonatomic, strong) OutPutWindow * window;
@property (nonatomic, copy, readwrite) NSString *printString;
@end


@implementation LogTextView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame textContainer:nil];
    if (self) {
        self.font = [UIFont systemFontOfSize:12];
        self.textColor = [UIColor greenColor];
        self.backgroundColor = [UIColor clearColor];
        self.scrollsToTop = false;
    }
    return self;
}
@end

@implementation OutPutWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _textView = [[LogTextView alloc] initWithFrame:self.bounds];
        [self addSubview:_textView];
    }
    return self;
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _textView.frame = self.bounds;
}
@end

@implementation logInWindowManager
+ (instancetype)share {
    static logInWindowManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[logInWindowManager alloc] init];
        instance.window = [[OutPutWindow alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20)];
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


#pragma mark - SetGet
- (CGRect)frame {
    return self.window.frame;
}
- (void)setFrame:(CGRect)frame {
    self.window.frame = frame;
}
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.window.backgroundColor = [backgroundColor colorWithAlphaComponent:0.3];
}
- (UIColor *)backgroundColor {
    return self.window.backgroundColor;
}
- (void)setFont:(UIFont *)font {
    self.window.textView.font = font;
}
- (UIFont *)font {
    return self.window.textView.font;
}
- (void)setTextColor:(UIColor *)textColor {
    self.window.textView.textColor = textColor;
}
- (UIColor *)textColor {
    return self.window.textView.textColor;
}

@end

