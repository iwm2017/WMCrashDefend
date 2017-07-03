//
//  WMCrashHandler.m
//  stringAndArray
//
//  Created by guoyang on 2017/3/1.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMCrashHandler.h"
#import "WMContainerObjectExceptionHandler.h"
#import "WMObserverExceptionHandler.h"
#import "WMBadAccessExceptionHandler.h"
#import "WMTimerExceptionHandler.h"
#import "WMUnrecognizerSelectorExceptionHandler.h"
#import "WMCrashLogger.h"

const NSString *WMCrashHandlerConfigPrefixArrayKey = @"__WMCrashHandlerConfigPrefixArrayKey";
const NSString *WMCrashHandlerConfigObjectArrayKey = @"__WMCrashHandlerConfigObjectArrayKey";

@implementation WMCrashHandler

+ (void)handleCrashWithOptions:(WMCrashOption)options {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self handleBadAccessWithClassePrefixArray];
        if((options & WMCrashOptionContainer) == WMCrashOptionContainer) {
            [WMContainerObjectExceptionHandler handleContainerException];
        }
        if((options & WMCrashOptionObserver) == WMCrashOptionObserver) {
            [WMObserverExceptionHandler handleObserverExceptionWithBadAccess:((options & WMCrashOptionBadAccess) == WMCrashOptionBadAccess)];
        }
        if((options & WMCrashOptionBadAccess) == WMCrashOptionBadAccess) {
            [WMBadAccessExceptionHandler handleBadAccessException];
        }
        if((options & WMCrashOptionTimer) == WMCrashOptionTimer) {
            [WMTimerExceptionHandler handleTimerException];
        }
        if((options & WMCrashOptionUnrecongizerSelector) == WMCrashOptionUnrecongizerSelector) {
            [WMUnrecognizerSelectorExceptionHandler handleUnrecognizerSelectorException];
        }
    });
}

+ (void)handleBadAccessWithClassePrefixArray {
    NSString *defendBundlePath = [[NSBundle mainBundle] pathForResource:@"WMCrashDefend" ofType:@"bundle"];
    NSString *configPath = [defendBundlePath stringByAppendingPathComponent:@"config.plist"];
    NSDictionary *configDic = [NSDictionary dictionaryWithContentsOfFile:configPath];
    NSLog(@"bundle_path:%@, configpath:%@, content:%@", defendBundlePath, configPath, configDic);
    NSArray *prefixArray = [configDic objectForKey:WMCrashHandlerConfigPrefixArrayKey];
    NSArray *classArray = [configDic objectForKey:WMCrashHandlerConfigObjectArrayKey];
    if(prefixArray.count > 0 || classArray.count > 0) {
        [WMBadAccessExceptionHandler handleBadAccessWithClassePrefixArray:prefixArray classArray:classArray];
        [WMUnrecognizerSelectorExceptionHandler handleUnrecognizerSelectorWithClassePrefixArray:prefixArray classArray:classArray];
    }
}

+ (void)getExceptionInfoWithCompletionBlocK:(WMCrashLoadCompletionBlock)completion; {
    if(!completion) {
        return;
    }
    [WMCrashLogger loadLogDictionaryWithLoggerBlock:^(NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(info);
        });
    }];
}

@end
