//
//  LogInWindow.m
//
//  Created by kagenZhao on 2017/5/23.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

#import "LogInWindow.h"
#import <sys/uio.h>
#import <stdio.h>
#import <fishhook/fishhook.h>

@interface LogTextView : UITextView

@end

@interface OutPutWindow : UIWindow
@property (nonatomic, strong) LogTextView *textView;
@property (nonatomic, strong) UIButton *cleanButton;
@end

@interface logInWindowManager()

@property (nonatomic, strong) dispatch_source_t sourt_t;


@property (nonatomic, strong) OutPutWindow * window;
@property (nonatomic, copy, readwrite) NSString *printString;
- (void)addPrintWithMessage:(NSString *)msg needReturn:(BOOL)needReturn;
+ (instancetype)share;
- (void)setupInWindow;
- (void)hideFromWindow;
@end



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
// 修复swift4
static char *__chineseChar = {0};
static int __buffIdx = 0;
static NSString *__syncToken = @"token";
static size_t (*orig_fwrite)(const void * __restrict, size_t, size_t, FILE * __restrict);
size_t new_fwrite(const void * __restrict ptr, size_t size, size_t nitems, FILE * __restrict stream) {
    
    char *str = (char *)ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (__syncToken) {
            if (__chineseChar != NULL) {
                if (str[0] == '\n' && __chineseChar[0] != '\0') {
                    s = [[NSString stringWithCString:__chineseChar encoding:NSUTF8StringEncoding] stringByAppendingString:s];
                    __buffIdx = 0;
                    __chineseChar = calloc(1, sizeof(char));
                }
            } else {
               
            }
        }
        [[logInWindowManager share] addPrintWithMessage:s needReturn:false];
    });
    return orig_fwrite(ptr, size, nitems, stream);
}

static int (*orin___swbuf)(int, FILE *);
static int new___swbuf(int c, FILE *p) {
    @synchronized (__syncToken) {
        __chineseChar = realloc(__chineseChar, sizeof(char) * (__buffIdx + 2));
        __chineseChar[__buffIdx] = (char)c;
        __chineseChar[__buffIdx + 1] = '\0';
        __buffIdx++;
    }
    return orin___swbuf(c, p);
}

// 发现新问题, 这个方法和NSLog重复了.. 所以把不hook NSLog了
static ssize_t (*orig_writev)(int, const struct iovec *, int);
static ssize_t new_writev(int a, const struct iovec *v, int v_len) {
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

static void rebindFunction() {
    int error = 0;
    error = rebind_symbols((struct rebinding[1]){{"writev", new_writev, (void *)&orig_writev}}, 1);
    if (error < 0) {
        NSLog(@"错误 writev");
    }
    error = rebind_symbols((struct rebinding[1]){{"fwrite", new_fwrite, (void *)&orig_fwrite}}, 1);
    if (error < 0) {
        NSLog(@"错误 fwrite");
    }
    error = rebind_symbols((struct rebinding[1]){{"__swbuf", new___swbuf, (void *)&orin___swbuf}}, 1);
    if (error < 0) {
        NSLog(@"错误 __swbuf");
    }
}


@implementation LogTextView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame textContainer:nil];
    if (self) {
        self.font = [UIFont systemFontOfSize:12];
        self.textColor = [UIColor greenColor];
        self.backgroundColor = [UIColor blackColor];
        self.scrollsToTop = false;
        self.editable = false;
        self.selectable = false;
        self.userInteractionEnabled = false;
    }
    return self;
}
@end

@implementation OutPutWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        //        self.userInteractionEnabled = NO;
        _textView = [[LogTextView alloc] initWithFrame:self.bounds];
        [self addSubview:_textView];
        
        _cleanButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _cleanButton.hidden = true;
        [_cleanButton setTitle:@"清空" forState:UIControlStateNormal];
        [_cleanButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self addSubview:_cleanButton];
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
        instance.window = [[OutPutWindow alloc] initWithFrame:CGRectMake(0, 20, 50, 50)];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(doubleTapAction:)];
        doubleTap.numberOfTapsRequired = 2;
        [instance.window addGestureRecognizer:doubleTap];
        UIPanGestureRecognizer *longP = [[UIPanGestureRecognizer alloc] initWithTarget:instance action:@selector(longGestureAction:)];
        [instance.window addGestureRecognizer:longP];
        rebindFunction();
//        instance.sourt_t = [instance startCapturinglogFrom:STDERR_FILENO];
    });
    return instance;
}

// 通过fd 绑定 不能拦截swift 的 print
//- (dispatch_source_t)startCapturinglogFrom:(int)fd {
//    int origianlFD = fd;
//    int originalStdHandle = dup(fd);
//    int fildes[2];
//    pipe(fildes);
//    dup2(fildes[1], fd);
//    close(fildes[1]);
//    fd = fildes[0];
//    NSMutableData *data = [[NSMutableData alloc] init];
//    fcntl(fd, F_SETFL, O_NONBLOCK);
//    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
//
//    int writeEnd = fildes[1];
//    dispatch_source_set_cancel_handler(source, ^{
//        close(writeEnd);
//        dup2(originalStdHandle, origianlFD);
//    });
//    dispatch_source_set_event_handler(source, ^{
//        @autoreleasepool {
//            char buffer[1024 * 10];
//            ssize_t size = read(fd, (void*)buffer, (size_t)(sizeof(buffer)));
//            [data setLength:0];
//            [data appendBytes:buffer length:size];
//            NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            [self addPrintWithMessage:aString needReturn:YES];
//            printf("\n%s\n",[aString UTF8String]);
//        }
//    });
//    dispatch_resume(source);
//    return source;
//}

static BOOL __isShow = false;

- (void)longGestureAction: (UIPanGestureRecognizer *)longP {
    static BOOL isBegin = false;
    if (__isShow) {
        if (isBegin) {
            [UIView animateWithDuration:0.2 animations:^{
                self.window.transform = CGAffineTransformMakeScale(1.2, 1.2);
            }];
            isBegin = false;
        }
        return;
    }
    switch (longP.state) {
        case UIGestureRecognizerStateBegan:
            if (!isBegin) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.window.transform = CGAffineTransformMakeScale(1.2, 1.2);
                }];
                isBegin = true;
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (isBegin) {
                CGPoint oldCenter = self.window.center;
                CGFloat newX = oldCenter.x + [longP translationInView:self.window].x;
                CGFloat newY = oldCenter.y + [longP translationInView:self.window].y;
                
                CGPoint newCenter = CGPointMake(newX, newY);
                [longP setTranslation:CGPointZero inView:self.window];
                self.window.center = newCenter;
            }
            break;
        default:
            if (isBegin) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.window.transform = CGAffineTransformIdentity;
                }];
                isBegin = false;
            }
            break;
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)ges {
    if (ges.numberOfTapsRequired == 2) {
        if (!__isShow) {
            [UIView animateWithDuration:0.5 animations:^{
                self.window.cleanButton.hidden = false;
                self.window.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                self.window.textView.frame = CGRectMake(0, 40, self.window.bounds.size.width, self.window.bounds.size.height - 40);
                self.window.cleanButton.frame = CGRectMake(0, 0, self.window.bounds.size.width, 40);
            }];
            self.window.textView.userInteractionEnabled = true;
        } else {
            [UIView animateWithDuration:0.5 animations:^{
                self.window.cleanButton.hidden = true;
                self.window.frame = CGRectMake(0, 0, 50, 50);
                self.window.textView.frame = self.window.bounds;
            }];
            self.window.textView.userInteractionEnabled = false;
        }
        __isShow = !__isShow;
    }
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
            } else {
                self.window.textView.text = msg;
            }
            if (!__isShow) {
                [self.window.textView scrollRangeToVisible:NSMakeRange(MAX((self.window.textView.text.length - 1), 0), self.window.textView.text.length ? 1 : 0)];
            }
        }
    });
}


#pragma mark - SetGet
//- (CGRect)frame {
//    return self.window.frame;
//}
//- (void)setFrame:(CGRect)frame {
//    self.window.frame = frame;
//}
//- (void)setBackgroundColor:(UIColor *)backgroundColor {
//    self.window.backgroundColor = [backgroundColor colorWithAlphaComponent:0.3];
//}
//- (UIColor *)backgroundColor {
//    return self.window.backgroundColor;
//}
//- (void)setFont:(UIFont *)font {
//    self.window.textView.font = font;
//}
//- (UIFont *)font {
//    return self.window.textView.font;
//}
//- (void)setTextColor:(UIColor *)textColor {
//    self.window.textView.textColor = textColor;
//}
//- (UIColor *)textColor {
//    return self.window.textView.textColor;
//}

@end
