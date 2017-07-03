//
//  WMUnrecognizerSelectorExceptionHandler.h
//  WMCrashDefend
//
//  Created by guoyang on 2017/3/3.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMUnrecognizerSelectorExceptionHandler : NSObject

+ (void)handleUnrecognizerSelectorException;
+ (void)handleUnrecognizerSelectorWithClassePrefixArray:(NSArray<NSString *> *)classPrefixArray
                                             classArray:(NSArray<NSString *> *)classArray;

@end
