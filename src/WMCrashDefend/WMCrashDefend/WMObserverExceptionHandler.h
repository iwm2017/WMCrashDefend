//
//  WMObserverExceptionHandler.h
//  stringAndArray
//
//  Created by guoyang on 2017/2/21.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMObserverExceptionHandler : NSObject

+ (void)handleObserverExceptionWithBadAccess:(BOOL)badAccess;

@end
