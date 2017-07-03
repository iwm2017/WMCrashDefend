//
//  WMZombie.h
//  stringAndArray
//
//  Created by guoyang on 2017/2/27.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _WMZombie : NSObject

@property (nonatomic, copy) NSString *originClassName;

@end

@interface _WMZombieManager : NSObject

@property(nonatomic, assign)NSUInteger maxCost;

+ (id)sharedManager;
- (void)clearAllZombies;

- (void)hitedZombie:(_WMZombie *)zombie;
- (void)addZombie:(NSObject *)zombie forClassName:(NSString *)className;
- (void)removeZombie:(_WMZombie *)zombie;

@end
