//
//  WMBadAccessExceptionHandler.h
//  stringAndArray
//
//  Created by guoyang on 2017/2/22.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMBadAccessExceptionHandler : NSObject

+ (void)handleBadAccessException;
+ (void)handleBadAccessWithClassePrefixArray:(NSArray<NSString *> *)classPrefixArray classArray:(NSArray<NSString *> *)classArray;

@end
