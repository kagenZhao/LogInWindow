//
//  DDRemoteAccess.h
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

typedef void(^DDRemoteAccessEnableCompleteBlock)(BOOL isSuccess,NSString* visitUrl);

@interface DDRemoteAccess : NSObject

@property (strong,nonatomic) DDFileLogger* fileLogger;

+ (DDRemoteAccess*)shared;
+ (void)configPort:(NSUInteger)port;//default port is 15000
+ (void)enableRemoteAccessWithCompleteBlock:(DDRemoteAccessEnableCompleteBlock)completeBlock;
+ (void)configLogger;
@end
