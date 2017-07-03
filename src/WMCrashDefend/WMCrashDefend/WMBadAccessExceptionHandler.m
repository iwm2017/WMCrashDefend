//
//  WMBadAccessExceptionHandler.m
//  stringAndArray
//
//  Created by guoyang on 2017/2/22.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMBadAccessExceptionHandler.h"
#import "WMRuntimeUtil.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "WMCrashLogger.h"
#import "WMZombieCenter.h"

@interface NSObject(WMBadAccessHandler)

+ (void)wmcd_handleBadAccessException;

@end

static NSArray *_classArray;
static NSArray *_prefixArray;

@implementation WMBadAccessExceptionHandler

+ (void)handleBadAccessException {
    [NSObject wmcd_handleBadAccessException];
}

+ (void)setClassArray:(NSArray *)array {
    _classArray = array;
    [_classArray retain];
}

+ (NSArray *)classArray {
    return _classArray;
}

+ (void)setPrefixArray:(NSArray *)array {
    _prefixArray = array;
    [_prefixArray retain];
}

+ (NSArray *)prefixArray {
    return _prefixArray;
}

+ (void)handleBadAccessWithClassePrefixArray:(NSArray<NSString *> *)classPrefixArray classArray:(NSArray<NSString *> *)classArray {
    [self setClassArray:classArray];
    [self setPrefixArray:classPrefixArray];
}

@end

@implementation NSObject(WMBadAccessHandler)

+ (void)wmcd_handleBadAccessException{
    [WMRuntimeUtil exchangeInstanceSEL:NSSelectorFromString(@"dealloc") targetInstanceSEL:@selector(wmcd_ba_dealloc) aClass:self];
}

- (void)wmcd_ba_dealloc {
    ///判断对象是否存在KVO的处理，如果存在需要先对KVO的对象进行析构
    NSObject *obj = objc_getAssociatedObject(self, NSSelectorFromString(@"addObserver:forKeyPath:options:context:"));
    if(obj) {
        ((void(*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"wmcd_dealloc"));
    }
    ///对指定前缀的对象进行zombie化，如果是非指定类型对象，直接走原dealloc方法
    if([self wmcd_checkNeedZombie]) {
        objc_destructInstance(self);
        NSString *className = [NSString stringWithUTF8String:object_getClassName(self)];
        [className retain];
        [[_WMZombieManager sharedManager] addZombie:(_WMZombie *)self forClassName:className];
        [className release];
/*
 *  发现部分对象添加zombie池后引用计数不增加，所以此处判断
 */
        if([self retainCount] == 2) {
            [self release];
        }
    }
    else {
        [self wmcd_ba_dealloc];
    }
}

- (BOOL)wmcd_checkNeedZombie {
    NSString *className = NSStringFromClass([self class]);
    NSRange wmcd_range = [className rangeOfString:@"_WM"];
    if(wmcd_range.location == 0) {
        return NO;
    }
    if([WMBadAccessExceptionHandler prefixArray].count == 0 &&
       [WMBadAccessExceptionHandler classArray].count == 0) {
        return YES;
    }
    __block BOOL needZombie = NO;
    [[WMBadAccessExceptionHandler prefixArray] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [className rangeOfString:obj];
        if(range.location == 0) {
            needZombie = YES;
            *stop = YES;
        }
    }];
    [[WMBadAccessExceptionHandler classArray] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isEqualToString:className]) {
            needZombie = YES;
            *stop = YES;
        }
    }];
    return needZombie;
}

@end
