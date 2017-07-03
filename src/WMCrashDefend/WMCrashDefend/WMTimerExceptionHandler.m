//
//  WMTimerExceptionHandler.m
//  stringAndArray
//
//  Created by guoyang on 2017/3/2.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMTimerExceptionHandler.h"
#import "WMRuntimeUtil.h"
#import <UIKit/UIDevice.h>
#import <objc/runtime.h>

@interface _WMWeakTimerProxy : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic)       SEL selector;
@property (nonatomic, weak) NSTimer *timer;

- (id)initWithTarget:(id)target selector:(SEL)selector;

@end

@implementation _WMWeakTimerProxy

- (id)initWithTarget:(id)target selector:(SEL)selector {
    self = [super init];
    if(self) {
        _target = target;
        _selector = selector;
    }
    return self;
}

- (void)timerFired:(NSTimer *)timer {
    if ([self.target respondsToSelector:self.selector]) {
        NSMethodSignature *methodSignature = [self.target methodSignatureForSelector:self.selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        if (methodSignature.numberOfArguments > 2) [invocation setArgument:&timer atIndex:2];
        invocation.selector = self.selector;
        [invocation invokeWithTarget:self.target];
    } else {
        [self.target doesNotRecognizeSelector:self.selector];
    }
}

@end

@interface _WMWeakTimerLifecycleTracker : NSObject

@property (nonatomic, weak) _WMWeakTimerProxy *timerProxy;

@end

@implementation _WMWeakTimerLifecycleTracker

- (id)initWithTimerProxy:(_WMWeakTimerProxy *)timerProxy {
    if (self = [super init]) {
        _timerProxy = timerProxy;
    }
    return self;
}

- (void)dealloc {
    [self.timerProxy.timer invalidate];
    self.timerProxy.timer = nil;
}

@end

@interface NSTimer(WMTimerExceptionHandler)

+ (void)wmcd_handleTimerException;

@end

@implementation WMTimerExceptionHandler

+ (void)handleTimerException {
    [NSTimer wmcd_handleTimerException];
}

@end

@implementation NSTimer(WMTimerExceptionHandler)

#pragma mark - CommonMethod
+ (void)wmcd_handleTimerException {
    [WMRuntimeUtil exchangeClassSEL:@selector(timerWithTimeInterval:invocation:repeats:) targetClassSEL:@selector(wmcd_timerWithTimeInterval:invocation:repeats:) aClass:self];
    [WMRuntimeUtil exchangeClassSEL:@selector(scheduledTimerWithTimeInterval:invocation:repeats:) targetClassSEL:@selector(wmcd_scheduledTimerWithTimeInterval:invocation:repeats:) aClass:self];
    [WMRuntimeUtil exchangeClassSEL:@selector(timerWithTimeInterval:target:selector:userInfo:repeats:) targetClassSEL:@selector(wmcd_timerWithTimeInterval:target:selector:userInfo:repeats:) aClass:self];
    [WMRuntimeUtil exchangeClassSEL:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) targetClassSEL:@selector(wmcd_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) aClass:self];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(initWithFireDate:interval:target:selector:userInfo:repeats:) targetInstanceSEL:@selector(wmcd_initWithFireDate:interval:target:selector:userInfo:repeats:) aClass:self];
}

+ (NSTimer *)wmcd_timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo {
    NSTimer *timer = [NSTimer wmcd_timerWithTimeInterval:ti invocation:invocation repeats:yesOrNo];
    [self wmcd_convertTimer:timer bindTracker:invocation.target selector:invocation.selector];
    return timer;
}

+ (NSTimer *)wmcd_scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo {
    NSTimer *timer = [NSTimer wmcd_scheduledTimerWithTimeInterval:ti invocation:invocation repeats:yesOrNo];
    [self wmcd_convertTimer:timer bindTracker:invocation.target selector:invocation.selector];
    return timer;
}

+ (NSTimer *)wmcd_timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo {
    NSTimer *timer = [NSTimer wmcd_timerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
    [self wmcd_convertTimer:timer bindTracker:aTarget selector:aSelector];
    return timer;
}

+ (NSTimer *)wmcd_scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo {
    NSTimer *timer = [NSTimer wmcd_scheduledTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
    [self wmcd_convertTimer:timer bindTracker:aTarget selector:aSelector];
    return timer;
}

- (instancetype)wmcd_initWithFireDate:(NSDate *)date interval:(NSTimeInterval)ti target:(id)t selector:(SEL)s userInfo:(nullable id)ui repeats:(BOOL)rep {
    NSTimer *timer = [self wmcd_initWithFireDate:date interval:ti target:t selector:s userInfo:ui repeats:rep];
    [[self class] wmcd_convertTimer:timer bindTracker:t selector:s];
    return self;
}

#pragma mark - privateMethod
+ (void)wmcd_convertTimer:(NSTimer *)timer bindTracker:(NSObject *)target selector:(SEL)selector {
    _WMWeakTimerProxy *proxyTarget = [[_WMWeakTimerProxy alloc] initWithTarget:target selector:selector];
    proxyTarget.timer = timer;
    _WMWeakTimerLifecycleTracker *tracker = [[_WMWeakTimerLifecycleTracker alloc] initWithTimerProxy:proxyTarget];
    objc_setAssociatedObject(target, (__bridge void *)tracker, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
