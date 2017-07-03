//
//  WMCrashHandler.h
//  stringAndArray
//
//  Created by guoyang on 2017/3/1.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>
///获取log后，此key用于获取文件名Array
FOUNDATION_EXPORT NSString *const WMCrashLoggerFileNameListKey;
///获取log后，此key用于获取文件路径Array
FOUNDATION_EXPORT NSString *const WMCrashLoggerFilePathListKey;

typedef void (^WMCrashLoadCompletionBlock) (NSDictionary *info);

typedef NS_OPTIONS(NSUInteger, WMCrashOption) {
    WMCrashOptionContainer            = 1 << 0, ///容器类
    WMCrashOptionObserver             = 1 << 1, ///KVO
    WMCrashOptionBadAccess            = 1 << 2, ///空指针
    WMCrashOptionTimer                = 1 << 3, ///定时器
    WMCrashOptionUnrecongizerSelector = 1 << 4, ///消息响应
    WMCrashOptionAll                  = 0xff    ///mask
};

@interface WMCrashHandler : NSObject

///选择开启
+ (void)handleCrashWithOptions:(WMCrashOption)options;
///获取所有的异常log，completion info为空表示当前没有异常数据。该方法会回调至主线程。
+ (void)getExceptionInfoWithCompletionBlocK:(WMCrashLoadCompletionBlock)completion;

@end
