//
//  WMCrashDefendDemoTests.m
//  WMCrashDefendDemoTests
//
//  Created by guoyang on 2017/3/2.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WMTestKVO.h"
#import <WMCrashDefend/WMCrashHandler.h>
#import <objc/message.h>

@interface WMCrashDefendDemoTests : XCTestCase
{
    WMTestKVO *_kvo;
}
@end

@implementation WMCrashDefendDemoTests

- (void)setUp {
    [super setUp];
    _kvo = [WMTestKVO new];
    [WMCrashHandler handleCrashWithOptions:WMCrashOptionAll];
}

- (void)tearDown {
    [super tearDown];
}

///空指针问题 || 对象内存正常释放
- (void)testBadAccess {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"a" ofType:@"txt"];
    _kvo.data = [NSData dataWithContentsOfFile:path];
    _kvo.testKVO = @"hello";
    ((void(*)(id,SEL))objc_msgSend)(_kvo,NSSelectorFromString(@"dealloc"));
    _kvo.testKVO = @"hello2";
}

///僵尸对象缓存问题   缓存阀值为37450，超过阀值开始dealloc zombie 采用LRU（最近最少使用）淘汰
- (void)testBadAccess2 {
    NSLog(@"test");
    __unsafe_unretained WMTestKVO *test = nil;
    {
        test = [[WMTestKVO alloc] init];
    }
    NSLog(@"test:%@", test);
    for(int i = 0; i < 37450; i++) {
        @autoreleasepool {
            [WMTestKVO new];
        }
        if(i == 30000) {
            test.testKVO = @"haha";
        }
    }
    test.testKVO = @"1";
}

///KVO 对象释放，观察者未remove的情况
- (void)testKVO {
    [_kvo addObserver:self forKeyPath:@"testKVO" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    ((void(*)(id,SEL))objc_msgSend)(_kvo,NSSelectorFromString(@"dealloc"));
}

///KVO 观察者remove两次导致crash问题
- (void)testKVO2 {
    [_kvo addObserver:self forKeyPath:@"testKVO" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [_kvo removeObserver:self forKeyPath:@"testKVO"];
    [_kvo removeObserver:self forKeyPath:@"testKVO"];
}

///KVO 观察者释放导致crash
- (void)testKVO3 {
    WMTestKVO *observer = [WMTestKVO new];
    [_kvo addObserver:observer forKeyPath:@"testKVO" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    ((void(*)(id,SEL))objc_msgSend)(observer,NSSelectorFromString(@"dealloc"));
    _kvo.testKVO = @"123";
}

///测试timer 对象释放没有制空timer问题
- (void)testTimer {
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:_kvo selector:@selector(time:) userInfo:nil repeats:YES];
    [timer fire];
    ((void(*)(id,SEL))objc_msgSend)(_kvo,NSSelectorFromString(@"dealloc"));
    NSLog(@"asd");
}

///NSArray 语法糖插入nil对象
- (void)testContainer {
    NSString *nilStr = nil;
    NSArray *array = @[@"asd",nilStr];
    XCTAssertNil(array, @"error");
}

///NSArray add nil对象
- (void)testContainer2 {
    NSString *nilStr = nil;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:0];
    [array addObject:nilStr];
    [array addObject:@"test"];
    NSLog(@"%@",array);
}

///NSArray 各种数组越界
- (void)testContainer3 {
    NSArray *singleArray = [NSArray arrayWithObject:@"test"];
    [singleArray objectAtIndex:2];
    NSArray *arrayI = [NSArray arrayWithObjects:@"test1",@"test2", nil];
    [arrayI objectAtIndex:2];
    NSMutableArray *arrayM = [NSMutableArray arrayWithObjects:@"test1",@"test2", nil];
    [arrayM objectAtIndex:2];
    NSArray *array = [[NSArray alloc] init];
    [array objectAtIndex:1];
}

///NSDictionary 语法糖
- (void)testContainer4 {
    NSString *nilStr = nil;
    NSDictionary *dictionary = @{
                                 @"test":nilStr,
                                 nilStr:@"test"
                                 };
    XCTAssertNil(dictionary,@"error");
}

///NSDictionary 防空插
- (void)testContainer5 {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSString *nilStr = nil;
    [dic setValue:nilStr forKey:@"test"];
    XCTAssert(dic.count == 0,@"error");
}

///NSSet 防空插
- (void)testContainer6 {
    NSMutableSet *set = [[NSMutableSet alloc] init];
    NSString *nilStr = nil;
    [set setValue:@"test" forKey:nilStr];
    [set setValue:nilStr forKey:@"test"];
    XCTAssert(set.count == 0,@"error");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
