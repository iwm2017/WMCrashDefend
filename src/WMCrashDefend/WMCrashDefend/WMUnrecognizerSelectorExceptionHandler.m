//
//  WMUnrecognizerSelectorExceptionHandler.m
//  WMCrashDefend
//
//  Created by guoyang on 2017/3/3.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMUnrecognizerSelectorExceptionHandler.h"
#import "WMRuntimeUtil.h"
#import <objc/runtime.h>
#import "WMCrashLogger.h"
#import "WMBadAccessExceptionHandler.h"

@interface _WMDefendUnselectorObject : NSObject

@end

@implementation _WMDefendUnselectorObject

- (id)wmcd_generalMethodForDefend {
    return nil;
}

@end

@interface NSObject(WMUnselectorExceptionHandler)

+ (void)wmcd_defend_handleUnrecognizerSelectorException;

@end

static NSArray *_prefixArray;
static NSArray *_classArray;

@implementation WMUnrecognizerSelectorExceptionHandler

+ (void)handleUnrecognizerSelectorException {
    [NSObject wmcd_defend_handleUnrecognizerSelectorException];
}

+ (void)handleUnrecognizerSelectorWithClassePrefixArray:(NSArray<NSString *> *)classPrefixArray
                                             classArray:(NSArray<NSString *> *)classArray {
    [self setClassArray:classArray];
    [self setPrefixArray:classPrefixArray];
}

+ (void)setClassArray:(NSArray *)array {
    _classArray = array;
}

+ (NSArray *)classArray {
    return _classArray;
}

+ (void)setPrefixArray:(NSArray *)array {
    _prefixArray = array;
}

+ (NSArray *)prefixArray {
    return _prefixArray;
}

@end

@implementation NSObject(WMUnselectorExceptionHandler)

+ (void)wmcd_defend_handleUnrecognizerSelectorException {
    [WMRuntimeUtil exchangeInstanceSEL:@selector(forwardingTargetForSelector:)
                     targetInstanceSEL:@selector(wmcd_defend_forwardingTargetForSelector:)
                                aClass:self];
}

- (id)wmcd_defend_forwardingTargetForSelector:(SEL)aSelector {
    if ([self wmcd_defend_shouldCatchUnselector] && ![self wmcd_defend_isInWMServiceStack]) {
        return [self wmcd_defend_objectForUnselector:aSelector];
    }
    return [self wmcd_defend_forwardingTargetForSelector:aSelector];
}

- (BOOL)wmcd_defend_shouldCatchUnselector {
    if([WMUnrecognizerSelectorExceptionHandler prefixArray].count == 0 && [WMUnrecognizerSelectorExceptionHandler classArray].count == 0) {
        return YES;
    }
    NSString *className = NSStringFromClass([self class]);
    __block BOOL needCatch = NO;
    [[WMUnrecognizerSelectorExceptionHandler prefixArray] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [className rangeOfString:obj];
        if(range.location == 0) {
            needCatch = YES;
            *stop = YES;
        }
    }];
    [[WMUnrecognizerSelectorExceptionHandler classArray] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([className isEqualToString:obj]) {
            needCatch =YES;
            *stop = YES;
        }
    }];
    return needCatch;
}

- (BOOL)wmcd_defend_isInWMServiceStack {
    NSArray *callStackSymbols = [NSThread callStackSymbols];
    BOOL result = NO;
    for (NSString *callStatck in callStackSymbols) {
        if ([callStatck rangeOfString:@"+[WMService"].location != NSNotFound) {
            result = YES;
            break;
        }
    }
    return result;
}

- (id)wmcd_defend_objectForUnselector:(SEL)aSelector {
    _WMDefendUnselectorObject *defendObj = [[_WMDefendUnselectorObject alloc] init];
    SEL swizzledSelector = @selector(wmcd_generalMethodForDefend);
    Method swizzleMethod = class_getInstanceMethod([_WMDefendUnselectorObject class], swizzledSelector);
    BOOL didAddMethod = class_addMethod([_WMDefendUnselectorObject class],
                                        aSelector,
                                        method_getImplementation(swizzleMethod),
                                        method_getTypeEncoding(swizzleMethod));
    NSString *log = [NSString stringWithFormat:@"self:%@, didAddMethod:%d, for unselector:%@", NSStringFromClass([self class]), didAddMethod, NSStringFromSelector(aSelector)];
    [WMCrashLogger addCrashLogWithMessage:log];
    return defendObj;
}

@end
