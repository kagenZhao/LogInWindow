//
//  DDRemoteAccess.m
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import "DDRemoteAccess.h"
#import "DDLogFilesResultBuilder.h"
#import "EPMFileLogger.h"
#import "EPMTTYLogger.h"

#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

NSString* const BonjourServiceName = @"epm-remote-log";

@interface DDRemoteAccess() <GCDWebServerDelegate>
@property (assign,nonatomic) NSUInteger serverPort;
@property (strong,nonatomic) GCDWebServer* webserver;
@property (strong,nonatomic) DDRemoteAccessEnableCompleteBlock enableCompleteBlock;
@end

@interface DDRemoteAccess()
@property (assign,nonatomic) BOOL isEnabled;
@end

@implementation DDRemoteAccess
+(void)configPort:(NSUInteger)port
{
    [DDRemoteAccess shared].serverPort = port;
}

+ (void)configLogger
{
    [[DDRemoteAccess shared] configDDLog];
}

+ (void)enableRemoteAccessWithCompleteBlock:(DDRemoteAccessEnableCompleteBlock)completeBlock
{
    [GCDWebServer setLogLevel:0];//no log
    [DDRemoteAccess shared].enableCompleteBlock = completeBlock;
    [DDRemoteAccess shared].isEnabled = YES;
    [[DDRemoteAccess shared].webserver startWithPort:[DDRemoteAccess shared].serverPort bonjourName:BonjourServiceName];
}

+ (DDRemoteAccess*)shared
{
    static DDRemoteAccess* _shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [DDRemoteAccess new];
        [[NSNotificationCenter defaultCenter] addObserver:_shared selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    });
    return _shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.serverPort = 15000;//default port
    }
    return self;
}

- (void)configDDLog
{
    [DDLog addLogger:[EPMTTYLogger sharedInstance]];
    self.fileLogger = [[EPMFileLogger alloc] init];
    self.fileLogger.rollingFrequency = 60 * 60 * 24 * 4; // 4 days rolling
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 100;
    [DDLog addLogger:self.fileLogger];
}

- (NSString *)logDirPath
{
    NSString* dirPath = [self.fileLogger.logFileManager logsDirectory];
    return dirPath;
}

- (void)registerWebServerHandlers:(GCDWebServer*)webserver
{
    NSString* logsDir = [self logDirPath];
    [webserver addHandlerForMethod:@"GET" path:@"/logs" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder buildJsonForFilesInDir:logsDir baseUrl:baseUrl]];
        return response;
    }];
    
    [webserver addHandlerForMethod:@"GET" path:@"/log" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        NSString* filename = [request query][@"file"];
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder fileContentWithName:filename inDir:logsDir]];
        return response;
    }];
    
    [webserver addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder latestFileContentInDir:logsDir]];
        return response;
    }];
}

#pragma mark - GCDWebServer Delegate
- (void)webServerDidStart:(GCDWebServer*)server
{
    if(self.enableCompleteBlock != nil)
    {
        self.enableCompleteBlock(YES,[server.serverURL absoluteString]);
    }
}

- (void)webServerDidStop:(GCDWebServer *)server
{
}

#pragma mark - Application Become Active
- (void)applicationDidBecomeActive:(NSNotification*)notification
{
    if(self.webserver != nil
       && self.webserver.isRunning == false
       && self.isEnabled)
    {
        [self.webserver startWithPort:[DDRemoteAccess shared].serverPort bonjourName:BonjourServiceName];
    }
}

#pragma mark - Getter & Setter
-(GCDWebServer *)webserver
{
    if(_webserver == nil)
    {
        _webserver = [[GCDWebServer alloc]init];
        _webserver.delegate = self;
        [self registerWebServerHandlers:_webserver];
    }
    return _webserver;
}

@end
