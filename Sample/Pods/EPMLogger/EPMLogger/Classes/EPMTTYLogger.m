//
//  EPMTTYLogger.m
//  Pods
//
//  Created by wangyang on 2016/11/7.
//
//

#import "EPMTTYLogger.h"

@implementation EPMTTYLoggerFormatterDefault

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    return [NSString stringWithFormat:@"<EPL> %@ %@ : [%@] %@",logMessage.timestamp,[self strFromFlag:logMessage.flag],logMessage.fileName,logMessage.message];
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

@implementation EPMTTYLogger
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.logFormatter = [EPMTTYLoggerFormatterDefault new];
    }
    return self;
}
@end
