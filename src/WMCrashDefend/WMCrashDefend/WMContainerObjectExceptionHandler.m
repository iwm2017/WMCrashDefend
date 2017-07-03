//
//  WMContainerObjectExceptionHandler.m
//  stringAndArray
//
//  Created by guoyang on 2017/2/20.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMContainerObjectExceptionHandler.h"
#import <objc/runtime.h>
#import "WMRuntimeUtil.h"
#import "WMCrashLogger.h"

@interface NSArray(WMExceptionHandler)
+ (void)wmcd_handleArrayException;
@end
@interface NSDictionary(WMExceptionHandler)
+ (void)wmcd_handleDictionaryException;
@end
@interface NSSet(WMExceptionHandler)
+ (void)wmcd_handleSetException;
@end
@interface NSNotificationCenter (WMExceptionHandler)
+ (void)wmcd_handleNotificationException;
@end

@implementation WMContainerObjectExceptionHandler

+ (void)handleContainerException {
    [NSArray wmcd_handleArrayException];
    [NSDictionary wmcd_handleDictionaryException];
    [NSSet wmcd_handleSetException];
}

@end

@implementation NSArray (WMExceptionHandler)

+ (void)wmcd_handleArrayException {
    NSArray *array_NSArrayI = [NSArray arrayWithObjects:@"double",@"array",nil];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(objectAtIndex:)
                           originClass:[array_NSArrayI class]
                     targetInstanceSEL:@selector(wmcd_IobjectAtIndex:)
                           targetClass:self];
    NSArray *array_NSArray0 = [NSArray array];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(objectAtIndex:)
                           originClass:[array_NSArray0 class]
                     targetInstanceSEL:@selector(wmcd_0objectAtIndex:)
                           targetClass:self];
    NSArray *array_NSSingleObjectArrayI = [NSArray arrayWithObject:@"singleI"];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(objectAtIndex:)
                           originClass:[array_NSSingleObjectArrayI class]
                     targetInstanceSEL:@selector(wmcd_1objectAtIndex:)
                           targetClass:self];
    NSMutableArray *array_NSArrayM = [[NSMutableArray alloc] initWithCapacity:0];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(objectAtIndex:)
                           originClass:[array_NSArrayM class]
                     targetInstanceSEL:@selector(wmcd_mobjectAtIndex:)
                           targetClass:self];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(insertObject:atIndex:)
                           originClass:[array_NSArrayM class]
                     targetInstanceSEL:@selector(wmcd_insertObject:atIndex:)
                           targetClass:self];
    NSArray *array_NSPlaceholderArray = @[];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(initWithObjects:count:)
                           originClass:[array_NSPlaceholderArray class]
                     targetInstanceSEL:@selector(wmcd_initWithObjects:count:)
                           targetClass:self];
}

///语法糖插nil
- (instancetype)wmcd_initWithObjects:(const NSObject **)objects count:(NSUInteger)cnt {
    for(int i = 0; i < cnt; i++) {
        if(!objects[i]) {
            NSString *errorLog = @"can't insert a nil object when create NSSArray by using syntex sugar";
            [WMCrashLogger addCrashLogWithMessage:errorLog];
            return nil;
        }
    }
    return [self wmcd_initWithObjects:objects count:cnt];
}

///防越界
- (NSObject *)wmcd_IobjectAtIndex:(NSUInteger)index {
    if(self.count <= index) {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) index out of bounds", NSStringFromClass([self class]) ,self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
        return nil;
    }
    return [self wmcd_IobjectAtIndex:index];
}

- (NSObject *)wmcd_0objectAtIndex:(NSUInteger)index {
    if(self.count <= index) {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) index out of bounds", NSStringFromClass([self class]) ,self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
        return nil;
    }
    return [self wmcd_0objectAtIndex:index];
}

- (NSObject *)wmcd_1objectAtIndex:(NSUInteger)index {
    if(self.count <= index) {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) index out of bounds", NSStringFromClass([self class]) ,self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
        return nil;
    }
    return [self wmcd_1objectAtIndex:index];
}

- (NSObject *)wmcd_mobjectAtIndex:(NSUInteger)index {
    if(self.count <= index) {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) index out of bounds", NSStringFromClass([self class]) ,self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
        return nil;
    }
    return [self wmcd_mobjectAtIndex:index];
}

///防空插
- (void)wmcd_insertObject:(NSObject *)anObject atIndex:(NSUInteger)index {
    if(anObject && index <= self.count) {
        [self wmcd_insertObject:anObject atIndex:index];
    }
    else {
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) can't insert a nil object", NSStringFromClass([self class]), self];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
    }
}

@end

@implementation NSDictionary (WMExceptionHandler)

+ (void)wmcd_handleDictionaryException {
    NSMutableDictionary *dictionary_NSDictionaryM = [[NSMutableDictionary alloc] initWithCapacity:0];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(setObject:forKey:)
                           originClass:[dictionary_NSDictionaryM class]
                     targetInstanceSEL:@selector(wmcd_setObject:forKey:)
                           targetClass:self];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(initWithObjects:forKeys:count:)
                           originClass:NSClassFromString(@"__NSPlaceholderDictionary")
                     targetInstanceSEL:@selector(wmcd_initWithObjects:forKeys:count:)
                           targetClass:self];
}

///语法糖
- (id)wmcd_initWithObjects:(NSObject **)objects forKeys:(NSObject **)keys count:(NSUInteger)count {
    for(int i = 0; i < count ;i++) {
        if(!objects[i] || !keys[i]) {
            NSString *className = objects[i]?NSStringFromClass([objects[i] class]):@"empty";
            NSString *keyName = keys[i]?NSStringFromClass([keys[i] class]):@"empty";
            NSString *errorLog = [NSString stringWithFormat:@"%@(%p) can't add a %@ for %@ when create Dictionary by using syntex sugar",NSStringFromClass([self class]),self,className,keyName];
            [WMCrashLogger addCrashLogWithMessage:errorLog];
            return nil;
        }
    }
    return [self wmcd_initWithObjects:objects forKeys:keys count:count];
}

///防空插
- (void)wmcd_setObject:(NSObject *)object forKey:(NSObject<NSCopying> *)key {
    if(!object || !key) {
        NSString *className = object?NSStringFromClass([object class]):@"empty";
        NSString *keyName = key?NSStringFromClass([key class]):@"empty";
        NSString *errorLog = [NSString stringWithFormat:@"%@(%p) can't add a %@ for %@",NSStringFromClass([self class]),self,className,keyName];
        [WMCrashLogger addCrashLogWithMessage:errorLog];
        return;
    }
    [self wmcd_setObject:object forKey:key];
}

@end

@implementation NSSet (WMExceptionHandler)

+ (void)wmcd_handleSetException {
    NSMutableSet *set_NSSetM = [[NSMutableSet alloc] init];
    [WMRuntimeUtil exchangeInstanceSEL:@selector(addObject:)
                           originClass:[set_NSSetM class]
                     targetInstanceSEL:@selector(wmcd_addObject:)
                           targetClass:self];
}

- (void)wmcd_addObject:(NSObject *)object {
    if(object) {
        [self wmcd_addObject:object];
    }
    else {
        NSString *errorLog = @"can't add a nil object into NSMutableSet";
        [WMCrashLogger addCrashLogWithMessage:errorLog];
    }
}

@end

/*
 *  hook NotificationCenter会对系统API造成影响，暂不处理
 */
@implementation NSNotificationCenter(WMExceptionHandler)

+ (void)wmcd_handleNotificationException {
    [WMRuntimeUtil exchangeInstanceSEL:@selector(addObserver:selector:name:object:)
                     targetInstanceSEL:@selector(wmcd_addObserver:selector:name:object:)
                                aClass:self];
}

- (void)wmcd_addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)userInfo{
    if(observer) {
        [WMRuntimeUtil exchangeInstanceSEL:NSSelectorFromString(@"dealloc")
                               originClass:observer
                         targetInstanceSEL:@selector(wmcd_dealloc)
                               targetClass:[NSNotificationCenter class]];
    }
    [self wmcd_addObserver:observer selector:selector name:name object:userInfo];
}

- (void)wmcd_dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self wmcd_dealloc];
}

@end



