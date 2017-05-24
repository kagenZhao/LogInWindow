//
//  EPMLogger.m
//  Pods
//
//  Created by wangyang on 16/7/19.
//
//

#import "EPMLogger.h"
#import <objc/runtime.h>

const NSString *kLogLevelKey;

@implementation EPMLogger

+ (void)setup
{
    [DDRemoteAccess configLogger];
    [self setLogLevel:ddLogLevel];
}

+ (NSArray *)logFilePaths {
    return [[DDRemoteAccess shared].fileLogger.logFileManager sortedLogFilePaths];
}

+ (void)setLogLevel:(DDLogLevel)logLevel {
    objc_setAssociatedObject(self, &kLogLevelKey, @(logLevel), OBJC_ASSOCIATION_RETAIN);
}

+ (DDLogLevel)logLevel {
    DDLogLevel level = [objc_getAssociatedObject(self, &kLogLevelKey) unsignedIntegerValue];
    return level;
}
@end
