//
//  WMObserverExceptionHandler.m
//  stringAndArray
//
//  Created by guoyang on 2017/2/21.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMObserverExceptionHandler.h"
#import "WMRuntimeUtil.h"
#import <objc/runtime.h>
#import "WMBadAccessExceptionHandler.h"
#import "WMCrashLogger.h"

@interface NSObject(WMExceptionHandler)
+ (void)wmcd_handleObserverExceptionWithBadAccess:(BOOL)badAccess;
- (void)wmcd_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)wmcd_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
@end

@implementation WMObserverExceptionHandler

+ (void)handleObserverExceptionWithBadAccess:(BOOL)badAccess {
    [NSObject wmcd_handleObserverExceptionWithBadAccess:badAccess];
}

@end

@interface _WMKVOProxy : NSObject
{
    NSMutableDictionary<NSString *,NSHashTable *> *_kvoMap;
    dispatch_semaphore_t _semaphore;
}
@property (nonatomic, assign) NSObject *bindObject;

- (id)initWithObject:(NSObject *)object;
- (BOOL)hasKeyPath:(NSString *)keyPath;
- (BOOL)containObject:(NSObject *)object forKey:(NSString *)key;
- (void)addObject:(NSObject *)object forKey:(NSString *)key;
- (void)removeObject:(NSObject *)object forKey:(NSString *)key;
- (void)destructProxy;

@end

@implementation _WMKVOProxy

- (id)initWithObject:(NSObject *)object {
    self = [super init];
    if(self) {
        _kvoMap = [[NSMutableDictionary alloc] init];
        _bindObject = object;
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (BOOL)hasKeyPath:(NSString *)keyPath {
    if(keyPath.length == 0) {
        return NO;
    }
    if([_kvoMap objectForKey:keyPath].count > 0) {
        return YES;
    }
    return NO;
}

- (BOOL)containObject:(NSObject *)object forKey:(NSString *)key {
    if(!object || key.length == 0) {
        return NO;
    }
    NSHashTable *array = [_kvoMap objectForKey:key];
    if(array.count > 0) {
        return [array containsObject:object];
    }
    return NO;
}

- (void)addObject:(NSObject *)object forKey:(NSString *)key {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if(!object || key.length == 0 || [self containObject:object forKey:key]) {
        return;
    }
    ///用hashTable是为了存放弱引用，时被观察者不会因观察者释放而造成crash
    NSHashTable *array = [_kvoMap objectForKey:key];
    if(!array) {
        array = [NSHashTable weakObjectsHashTable];
        [_kvoMap setObject:array forKey:key];
        [_bindObject wmcd_addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    [array addObject:object];
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeObject:(NSObject *)object forKey:(NSString *)key {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if(!object || key.length == 0 || ![self containObject:object forKey:key]) {
        return;
    }
    NSHashTable *array = [NSHashTable weakObjectsHashTable];
    [array removeObject:object];
    if(array.count == 0) {
        [_bindObject wmcd_removeObserver:self forKeyPath:key];
        [_kvoMap removeObjectForKey:key];
    }
    dispatch_semaphore_signal(_semaphore);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSHashTable *array = [_kvoMap objectForKey:keyPath];
    NSEnumerator *enumerator = [array objectEnumerator];
    NSArray *allObject = [enumerator allObjects];
    if(allObject.count == 0) {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        [_kvoMap removeObjectForKey:keyPath];
        dispatch_semaphore_signal(_semaphore);
        [object wmcd_removeObserver:self forKeyPath:keyPath];
        return;
    }
    [allObject enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
            [obj observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }];
}

- (void)destructProxy {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL needLog = NO;
    [_kvoMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSHashTable * _Nonnull obj, BOOL * _Nonnull stop) {
        [_bindObject wmcd_removeObserver:self forKeyPath:key];
        [obj removeAllObjects];
        needLog = YES;
    }];
    if(needLog) {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) has dealloc bug still have object observer it", NSStringFromClass([_bindObject class]),_bindObject];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
    }
    _bindObject = nil;
    _kvoMap = nil;
    dispatch_semaphore_signal(_semaphore);
}

@end

@implementation NSObject(WMExceptionHandler)

/*
 * 用于判断是否空指针和观察者handler同时存在，如果同时存在需要只用空指针的wmcd_ba_dealloc去做method_swizzling，把观察者的wmcd_dealloc作为函数在wmcd_ba_dealloc中进行调用。如果只存在观察者handler，就用观察者handler去进行method_swizzling。
 */
static BOOL _hasBadAccess = NO;

+ (void)wmcd_handleObserverExceptionWithBadAccess:(BOOL)badAccess {
    [WMRuntimeUtil exchangeInstanceSEL:@selector(addObserver:forKeyPath:options:context:)
                     targetInstanceSEL:@selector(wmcd_addObserver:forKeyPath:options:context:)
                                aClass:self];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(removeObserver:forKeyPath:)
                     targetInstanceSEL:@selector(wmcd_removeObserver:forKeyPath:)
                                aClass:self];
    _hasBadAccess = badAccess;
}

/// hook主要目的在于在观察者和被观察之间添加一层proxy，这样可以在不小心多次添加或者多次删除观察者时作出判断并修复，同时因为是弱引用不用担心观察者析构引发空指针为题，也不用担心被观察者析构造成的crash。
- (void)wmcd_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    _WMKVOProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if(proxy && ![proxy isKindOfClass:[_WMKVOProxy class]]) {
        return;
    }
    if(!proxy) {
        proxy = [[_WMKVOProxy alloc] initWithObject:self];
        
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN);
        ///如果不对空指针进行处理，则swizzling dealloc方法
        if(!_hasBadAccess) {
            [WMRuntimeUtil exchangeInstanceSEL:NSSelectorFromString(@"dealloc")
                             targetInstanceSEL:@selector(wmcd_dealloc)
                                        aClass:[self class]];
        }
    }
    if([proxy containObject:observer forKey:keyPath]) {
        return;
    } else {
        [proxy addObject:observer forKey:keyPath];
    }
}

- (void)wmcd_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    _WMKVOProxy *proxy = objc_getAssociatedObject(self, @selector(addObserver:forKeyPath:options:context:));
    if(proxy && ![proxy isKindOfClass:[_WMKVOProxy class]]) {
        return;
    }
    if(!proxy) {
        proxy = [[_WMKVOProxy alloc] initWithObject:self];
        objc_setAssociatedObject(self, @selector(addObserver:forKeyPath:options:context:), proxy, OBJC_ASSOCIATION_RETAIN);
    }
    if([proxy containObject:observer forKey:keyPath]) {
        [proxy removeObject:observer forKey:keyPath];
    }
    else {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) already removed kvo from %@(%p)",NSStringFromClass([observer class]), observer, NSStringFromClass([self class]), self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
    }
}

- (void)wmcd_dealloc {
    _WMKVOProxy *proxy = objc_getAssociatedObject(self, @selector(addObserver:forKeyPath:options:context:));
    if(proxy) {
        //释放所有观察者
        [proxy destructProxy];
    }
    if(!_hasBadAccess) {
        objc_removeAssociatedObjects(self);
        [self wmcd_dealloc];
    }
}

@end
