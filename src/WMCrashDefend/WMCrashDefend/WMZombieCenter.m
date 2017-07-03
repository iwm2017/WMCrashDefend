//
//  WMZombie.m
//  stringAndArray
//
//  Created by guoyang on 2017/2/27.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "WMZombieCenter.h"
#import <objc/message.h>
#import "WMCrashLogger.h"

#pragma mark - WMSubtempObject

@interface _WMSubtempObject : NSObject

@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *calledSelector;
@property (nonatomic, copy) NSObject *zombie;

- (id)initWithClassName:(NSString *)className selectorName:(NSString *)selectorName objectPointer:(NSObject *)pointer;

@end

@implementation _WMSubtempObject

- (id)initWithClassName:(NSString *)className selectorName:(NSString *)selectorName objectPointer:(NSObject *)pointer {
    self = [super init];
    if(self) {
        _className = className;
        _calledSelector = selectorName;
        _zombie = pointer;
    }
    return self;
}

- (id)emptyMethodHandler {
    NSString *errorLog = [NSString stringWithFormat:@"instance %p(%@) has called selector(%@) after dealloc",&_zombie, _className, _calledSelector];
    [WMCrashLogger addCrashLogWithMessage:errorLog];
    return nil;
}

- (void)dealloc {
    NSLog(@"temp dealloc");
}

@end

#pragma mark - WMZombie
@implementation _WMZombie

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if(!aSelector) {return nil;}
    IMP calledZombie = class_getMethodImplementation([_WMSubtempObject class], @selector(emptyMethodHandler));
    const char *types = method_getTypeEncoding(class_getInstanceMethod([_WMSubtempObject class], @selector(emptyMethodHandler)));
    class_addMethod([_WMSubtempObject class], aSelector, calledZombie, types);
    NSString *originClassName = objc_getAssociatedObject(self, @selector(addZombie:forClassName:));
    _WMSubtempObject *tempobject = [[_WMSubtempObject alloc] initWithClassName:originClassName selectorName:NSStringFromSelector(aSelector) objectPointer:self];
    [[_WMZombieManager sharedManager] hitedZombie:self];
    return tempobject;
}

- (void)dealloc {
    NSLog(@"zombie dealloc");
}

@end

#define WMCD_Zombie_default_size 2 * 1024 * 1024
#pragma mark - WMZombieManager

@interface _WMZombieManager()
{
    NSMutableArray *_zombies;
    dispatch_semaphore_t _semphore;
}
@end

@implementation _WMZombieManager

+ (id)sharedManager {
    static _WMZombieManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[_WMZombieManager alloc] init];
    });
    return manager;
}

- (id)init {
    self = [super init];
    if(self) {
        _maxCost = 0;
        _zombies = [[NSMutableArray alloc] init];
        _semphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)clearAllZombies {
    dispatch_semaphore_wait(_semphore, DISPATCH_TIME_FOREVER);
    [_zombies removeAllObjects];
    dispatch_semaphore_signal(_semphore);
}

- (void)hitedZombie:(_WMZombie *)zombie {
    dispatch_semaphore_wait(_semphore, DISPATCH_TIME_FOREVER);
    if([_zombies containsObject:zombie]) {
        _WMZombie *obj = [_zombies firstObject];
        [_zombies removeObject:obj];
        [_zombies addObject:obj];
    }
    dispatch_semaphore_signal(_semphore);
}

- (void)addZombie:(NSObject *)zombie forClassName:(NSString *)className {
    dispatch_semaphore_wait(_semphore, DISPATCH_TIME_FOREVER);
    if(zombie) {
        object_setClass(zombie, [_WMZombie class]);
        ///有些对象发现setClass后，不会转为WMZombie对象
        if([zombie isKindOfClass:[_WMZombie class]]) {
            NSUInteger classSize = 56;//class_getInstanceSize([_WMZombie class]);
            if(self.maxCost >= WMCD_Zombie_default_size) {
                _WMZombie *obj = [_zombies firstObject];
                [_zombies removeObject:obj];
                _maxCost -= classSize;
            }
            [_zombies addObject:zombie];
            objc_setAssociatedObject(zombie, _cmd, className, OBJC_ASSOCIATION_RETAIN);
            _maxCost += classSize;
        }
    }
    dispatch_semaphore_signal(_semphore);
}

- (void)removeZombie:(_WMZombie *)zombie {
    dispatch_semaphore_wait(_semphore, DISPATCH_TIME_FOREVER);
    if(zombie && [_zombies containsObject:zombie]) {
        [_zombies removeObject:zombie];
    }
    dispatch_semaphore_signal(_semphore);
}

@end
