//
//  WMCrashLoger.h
//  stringAndArray
//
//  Created by guoyang on 2017/3/1.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const WMCrashLoggerFileNameListKey;
FOUNDATION_EXPORT NSString *const WMCrashLoggerFilePathListKey;

typedef void (^WMCrashLoggerBlock) (NSDictionary *info);

@interface WMCrashLogger : NSObject

+ (void)addCrashLogWithMessage:(NSString *)message;
+ (void)loadLogDictionaryWithLoggerBlock:(WMCrashLoggerBlock)completion;

@end
