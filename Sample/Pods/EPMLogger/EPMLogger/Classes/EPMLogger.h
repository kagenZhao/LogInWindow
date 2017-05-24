//
//  EPMLogger.h
//  Pods
//
//  Created by wangyang on 16/7/19.
//
//

#import <Foundation/Foundation.h>
#import "DDRemoteAccess.h"

#define DRStrMerge(str1,str2) [str1 stringByAppendingString:str2]
#define CurrentClsName  NSStringFromClass(self.class)

static DDLogLevel ddLogLevel = DDLogLevelAll;

@interface EPMLogger : NSObject
+ (void)setup;
+ (NSArray *)logFilePaths;
+ (void)setLogLevel:(DDLogLevel)logLevel;
+ (DDLogLevel)logLevel;
@end


#define EPMLogError(fmt, ...) \
if ([EPMLogger logLevel] & DDLogFlagError) {\
DDLogError(fmt, ##__VA_ARGS__); \
}

#define EPMLogWarn(fmt, ...) \
if ([EPMLogger logLevel] & DDLogFlagWarning) {\
DDLogWarn(fmt, ##__VA_ARGS__); \
}

#define EPMLogInfo(fmt, ...) \
if ([EPMLogger logLevel] & DDLogFlagInfo) {\
DDLogInfo(fmt, ##__VA_ARGS__); \
}

#define EPMLogDBG(fmt, ...) \
if ([EPMLogger logLevel] & DDLogFlagDebug) {\
DDLogDebug(fmt, ##__VA_ARGS__); \
}

//如果在OC的类中，使用C后缀的宏会自动记录当前的ClassName
//为了兼容之前的写法
#define EPMLogErrorC(fmt, ...) EPMLogError(fmt,##__VA_ARGS__)
#define EPMLogWarnC(fmt, ...) EPMLogWarn(fmt, ##__VA_ARGS__)
#define EPMLogInfoC(fmt, ...) EPMLogInfo(fmt, ##__VA_ARGS__)
#define EPMLogDBGC(fmt, ...) EPMLogDBG(fmt, ##__VA_ARGS__)
