//
//  DDLogFilesHtmlBuilder.h
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import <Foundation/Foundation.h>

@interface DDLogFilesResultBuilder : NSObject
+ (NSString*)buildJsonForFilesInDir:(NSString*)dir baseUrl:(NSString*)baseUrl;
+ (NSString*)fileContentWithName:(NSString*)filename inDir:(NSString*)dir;
+ (NSString*)latestFileContentInDir:(NSString*)dir;
@end
