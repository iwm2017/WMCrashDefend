//
//  WMRuntimeUtil.h
//  stringAndArray
//
//  Created by guoyang on 2017/2/20.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMRuntimeUtil : NSObject

///当originClass不存在originSEL时，该方法会自动添加一个imp为targetSEL的实现并替换targetSEL为原方法。调用该方法不需要再调用前做任何添加方法操作。
+ (void)exchangeClassSEL:(SEL)originClassSEL
             originClass:(Class)originClass
          targetClassSEL:(SEL)targetClassSEL
             targetClass:(Class)targetClass;

+ (void)exchangeInstanceSEL:(SEL)originInstanceSEL
             originClass:(Class)originClass
          targetInstanceSEL:(SEL)targetInstanceSEL
             targetClass:(Class)targetClass;

+ (void)exchangeClassSEL:(SEL)originClassSEL
          targetClassSEL:(SEL)targetClassSEL
                  aClass:(Class)aClass;

+ (void)exchangeInstanceSEL:(SEL)originSEL
          targetInstanceSEL:(SEL)targetSEL
                     aClass:(Class)aClass;

@end
