#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DDLogFilesResultBuilder.h"
#import "DDRemoteAccess.h"
#import "EPMFileLogger.h"
#import "EPMLogger.h"
#import "EPMTTYLogger.h"

FOUNDATION_EXPORT double EPMLoggerVersionNumber;
FOUNDATION_EXPORT const unsigned char EPMLoggerVersionString[];

