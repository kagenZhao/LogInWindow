//
//  EPMFileLogger.m
//  Pods
//
//  Created by wangyang on 2016/11/4.
//
//

#import "EPMFileLogger.h"

@implementation EPMFileLoggerFormatterDefault

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSMutableDictionary *result = [NSMutableDictionary new];
    result[@"fileName"] = logMessage.fileName;
    result[@"message"] = logMessage.message;
    result[@"type"] = [self strFromFlag:logMessage.flag];
    result[@"function"] = logMessage.function;
    result[@"line"] = @(logMessage.line);
    result[@"timestamp"] = @([logMessage.timestamp timeIntervalSince1970] * 1000);
    result[@"queueLabel"] = logMessage.queueLabel;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)strFromFlag:(DDLogFlag)flag {
    switch (flag) {
        case DDLogFlagInfo:
            return @"Info";
        case DDLogFlagError:
            return @"Error";
        case DDLogFlagWarning:
            return @"Warn";
        case DDLogFlagDebug:
            return @"Debug";
        default:
            return @"Verbose";
    }
    return @"All";
}

@end

@implementation EPMFileLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.logFormatter = [EPMFileLoggerFormatterDefault new];
    }
    return self;
}

- (id<DDLogFormatter>)logFormatter {
    if (_logFormatter == nil) {
        _logFormatter = [EPMFileLoggerFormatterDefault new];
    }
    return _logFormatter;
}
@end
