//
//  DDLogFilesHtmlBuilder.m
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import "DDLogFilesResultBuilder.h"

@implementation DDLogFilesResultBuilder
+ (NSString*)buildJsonForFilesInDir:(NSString*)dir baseUrl:(NSString*)baseUrl
{
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    NSString* file = nil;
    NSMutableArray* files = [NSMutableArray new];
    while (file = [enumerator nextObject]) {
        [files addObject:[NSString stringWithFormat:@"%@log?file=%@",baseUrl,file]];
    }
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[files copy] options:NSJSONReadingAllowFragments error:nil];
    return [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString*)fileContentWithName:(NSString*)filename inDir:(NSString*)dir
{
    NSString* filePath = [NSString pathWithComponents:@[dir,filename]];
    NSError* error;
    NSString* fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        return @"error";
    }
    return fileContent;
}

+ (NSString*)latestFileContentInDir:(NSString*)dir
{
    NSDate* latestFileDate = [NSDate dateWithTimeIntervalSince1970:0];
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    NSString* file = nil;
    NSString* latestFile = nil;
    NSMutableArray* files = [NSMutableArray new];
    while (file = [enumerator nextObject]) {
        NSString* filePath = [NSString pathWithComponents:@[dir,file]];
        NSDictionary* fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSDate* fileCreateDate = [fileAttrs objectForKey: NSFileCreationDate];
        if([fileCreateDate timeIntervalSinceDate:latestFileDate] > 0)
        {
            latestFileDate = fileCreateDate;
            latestFile = file;
        }
    }
    
    if(latestFile)
    {
        NSError* error;
        NSString* filePath = [NSString pathWithComponents:@[dir,latestFile]];
        NSString* fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            return @"error";
        }
        return fileContent;
    }
    return @"no such log file";
}
@end
