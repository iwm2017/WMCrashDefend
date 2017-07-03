//
//  TestKVO.h
//  stringAndArray
//
//  Created by guoyang on 2017/2/21.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMTestKVO : NSObject

@property (nonatomic, copy) NSString *testKVO;
@property (nonatomic, strong) NSData *data;

- (void)time:(NSTimer *)timer;

@end
