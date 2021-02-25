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


void rebindFunction(void);

@interface LogTextView : UITextView

@end

@interface OutPutWindow : UIWindow
@property (nonatomic, strong) LogTextView *textView;
@property (nonatomic, strong) UIButton *cleanButton;
@end

@interface logInWindowManager()
@property (nonatomic, assign) CGPoint preCenter;
@property (nonatomic, strong) OutPutWindow * window;
@property (nonatomic, copy, readwrite) NSString *printString;
- (void)addPrintWithMessage:(NSString *)msg needReturn:(BOOL)needReturn;
+ (instancetype)share;
- (void)setupInWindow;
- (void)hideFromWindow;
@end


void logInWindow(bool flag) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rebindFunction();
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flag) {
            [[logInWindowManager share] setupInWindow];
        } else {
            [[logInWindowManager share] hideFromWindow];
        }
    });
}

// swift5.x 只需要hook这一个方法即可
static size_t (*orig_fwrite)(const void * __restrict, size_t, size_t, FILE * __restrict);
size_t new_fwrite(const void * __restrict ptr, size_t size, size_t nitems, FILE * __restrict stream) {
    char *str = (char *)ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    [[logInWindowManager share] addPrintWithMessage:s needReturn:false];
    return orig_fwrite(ptr, size, nitems, stream);
}

// 这个方法就是NSLog底层调用.. 所以把不hook NSLog了
static ssize_t (*orig_writev)(int a, const struct iovec *, int);
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

void rebindFunction(void) {
    // Swift5.x print
    rebind_symbols((struct rebinding[1]){{"fwrite", new_fwrite, (void *)&orig_fwrite}}, 1);
    
    // NSLog, DDLog
    rebind_symbols((struct rebinding[1]){{"writev", new_writev, (void *)&orig_writev}}, 1);
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
        instance.preCenter = CGPointMake(25, 125);
        instance.window = [[OutPutWindow alloc] initWithFrame:CGRectMake(0, 100, 50, 50)];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(doubleTapAction:)];
        doubleTap.numberOfTapsRequired = 2;
        [instance.window addGestureRecognizer:doubleTap];
        UIPanGestureRecognizer *longP = [[UIPanGestureRecognizer alloc] initWithTarget:instance action:@selector(longGestureAction:)];
        [instance.window addGestureRecognizer:longP];
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
                self.preCenter = self.window.center;
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
                self.window.frame = CGRectMake(self.preCenter.x - 25, self.preCenter.y - 25, 50, 50);
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
    [self.window setHidden:NO];
}

- (void)hideFromWindow {
    [self.window setHidden:YES];
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

@end
