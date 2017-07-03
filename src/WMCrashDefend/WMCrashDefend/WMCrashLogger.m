
//
//  WMCrashLoger.m
//  stringAndArray
//
//  Created by guoyang on 2017/3/1.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMCrashLogger.h"
#import <CommonCrypto/CommonDigest.h>
#include <execinfo.h>

NSString *const WMCrashLoggerFileNameListKey = @"__WMCrashLoggerFileNameListKey";
NSString *const WMCrashLoggerFilePathListKey = @"__WMCrashLoggerFilePathListKey";

const char *_loggerQueueLabel = "com.baidu.waimai.crashdefend.crashlogger";

@implementation WMCrashLogger

#pragma mark - Public Method

+ (dispatch_queue_t)sharedQueue {
    static dispatch_queue_t _loggerQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loggerQueue = dispatch_queue_create(_loggerQueueLabel, DISPATCH_QUEUE_SERIAL);
    });
    return _loggerQueue;
}

+ (void)addCrashLogWithMessage:(NSString *)message {
    dispatch_barrier_async([self sharedQueue], ^{
        NSArray *backtrace = [self backtrace];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:message];
        if(backtrace.count > 0) {
            [array addObjectsFromArray:backtrace];
        }
        [self writeLog:array];
    });
}

+ (void)loadLogDictionaryWithLoggerBlock:(WMCrashLoggerBlock)completion {
    if(!completion) {
        return;
    }
    dispatch_async([self sharedQueue], ^{
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSString *saveDirectoryPath = [self saveDirectoryPath];
        if(![defaultManager fileExistsAtPath:saveDirectoryPath]) {
            completion(nil);
            return;
        }
        NSArray *subNameArray = [defaultManager subpathsOfDirectoryAtPath:saveDirectoryPath error:nil];
        if(subNameArray.count == 0) {
            completion(nil);
            return;
        }
        NSMutableArray *subPathArray = [[NSMutableArray alloc] initWithCapacity:subNameArray.count];
        [subNameArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *subPath = [[self saveDirectoryPath] stringByAppendingPathComponent:obj];
            [subPathArray addObject:subPath];
        }];
        NSDictionary *completionDic = @{
                                        WMCrashLoggerFileNameListKey : subNameArray,
                                        WMCrashLoggerFilePathListKey : subPathArray
                                        };
        completion(completionDic);
    });
}

#pragma mark - Private Method
+ (NSString *)saveDirectoryPath {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *directoryPath = [documentPath stringByAppendingPathComponent:@"__CrashLog"];
    return directoryPath;
}

+ (NSString *)saveFilePath {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    NSString *dateStr = [dateFormatter stringFromDate:date];
    int tag1 = arc4random() % 10000;
    int tag2 = arc4random() % 10000;
    NSString *tagStr = [NSString stringWithFormat:@"__%d%d",tag1,tag2];
    NSString *fileName = [NSString stringWithFormat:@"%@%@",dateStr,tagStr];
    return [[self saveDirectoryPath] stringByAppendingPathComponent:fileName];
}

+ (void)writeLog:(NSArray *)log {
    if(log.count == 0) {
        return;
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:log];
    if(data.length == 0) {return;}
    NSString *saveFilePath = [self saveFilePath];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *saveDirectoryPath = [self saveDirectoryPath];
    if(![defaultManager fileExistsAtPath:saveDirectoryPath]) {
        [defaultManager createDirectoryAtPath:saveDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if([defaultManager fileExistsAtPath:saveFilePath]) {
        [defaultManager removeItemAtPath:saveFilePath error:nil];
    }
    if(data) {
        [defaultManager createFileAtPath:saveFilePath contents:data attributes:nil];
    }
}

+ (NSArray *)backtrace {
//    [NSThread callStackSymbols];
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i = 0; i < frames; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

@end
