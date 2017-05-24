//
//  LogInWindow.m
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "LogInWindow.h"
#import <sys/uio.h>
#import <stdio.h>
#import "fishhook/fishhook.h"

void logInWindow(bool flag) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flag) {
            [[logInWindowManager share] setupInWindow];
        } else {
            [[logInWindowManager share] hideFromWindow];
        }
    });
}

// 这两个方法是 swift 的print调用的
static char __chineseChar[999999];
static int __buffIdx = 0;
static NSString *token = @"token";

static size_t (*orig_fwrite)(const void * __restrict __ptr, size_t __size, size_t __nitems, FILE * __restrict __stream);
size_t new_fwrite(const void * __restrict __ptr, size_t __size, size_t __nitems, FILE * __restrict __stream) {
    
    char *str = (char *)__ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (str[0] == '\n' && __chineseChar[0] != '\0') {
            @synchronized (token) {
                s = [[NSString stringWithCString:__chineseChar encoding:NSUTF8StringEncoding] stringByAppendingString:s];
                __chineseChar[0] = '\0';
                __buffIdx = 0;
            }
        }
        [[logInWindowManager share] addPrintWithMessage:s needReturn:false];
    });
    return orig_fwrite(__ptr, __size, __nitems, __stream);
}

static int	(*orin___swbuf)(int, FILE *);
int	new___swbuf(int c, FILE *p) {
    @synchronized (token) {
        __chineseChar[__buffIdx] = (char)c;
        __chineseChar[__buffIdx+1] = '\0';
        __buffIdx++;
    }
    return orin___swbuf(c, p);
}

// 发现新问题, 这个方法和NSLog重复了.. 所以把不hook NSLog了
static ssize_t (*orig_writev)(int a, const struct iovec * v, int v_len);
ssize_t new_writev(int a, const struct iovec *v, int v_len) {
    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < v_len; i++) {
        char *c = (char *)v[i].iov_base;
        [string appendString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
    }
    ssize_t result = orig_writev(a, v, v_len);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[logInWindowManager share] addPrintWithMessage:string needReturn:false];
    });
    return result;
}

static void (*orig_NSLog)(NSString *format, ...);
void(new_NSLog)(NSString *format, ...) {
    va_list args;
    if(format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [[logInWindowManager share] addPrintWithMessage:message needReturn:true];
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

void rebindFunction() {
    rebind_symbols((struct rebinding[1]){{"NSLog", new_NSLog, (void *)&orig_NSLog}}, 1);
//    rebind_symbols((struct rebinding[1]){{"writev", new_writev, (void *)&orig_writev}}, 1);
//    rebind_symbols((struct rebinding[1]){{"fwrite", new_fwrite, (void *)&orig_fwrite}}, 1);
//    rebind_symbols((struct rebinding[1]){{"__swbuf", new___swbuf, (void *)&orin___swbuf}}, 1);
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
        rebindFunction();
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

- (void)addPrintWithMessage:(NSString *)msg needReturn:(BOOL)needReturn{
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (self) {
            if (self.window.textView.text.length) {
                if (needReturn) {
                    self.window.textView.text = [NSString stringWithFormat:@"%@\n%@", self.window.textView.text, msg];
                } else {
                    self.window.textView.text = [NSString stringWithFormat:@"%@%@", self.window.textView.text, msg];
                }
                [self.window.textView scrollRangeToVisible:NSMakeRange((self.window.textView.text.length - 1), 1)];
            } else {
                self.window.textView.text = msg;
                [self.window.textView scrollRangeToVisible:NSMakeRange(MAX((self.window.textView.text.length - 1), 0), msg.length ? 1 : 0)];
            }
        }
    });
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

