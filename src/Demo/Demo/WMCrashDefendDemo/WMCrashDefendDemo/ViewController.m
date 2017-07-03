//
//  ViewController.m
//  stringAndArray
//
//  Created by guoyang on 2017/2/20.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "ViewController.h"
#import <WMCrashDefend/WMCrashDefend.h>
#import "WMTestKVO.h"
#import <objc/message.h>
#import "TestViewController.h"
#import "TestObjectSub.h"
#import "TestObjectParent.h"

@interface ViewController ()
{
    WMTestKVO *_kvo;
    WMTestKVO *_kvo2;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WMCrashHandler handleCrashWithOptions:WMCrashOptionAll];
    
    _kvo = [WMTestKVO new];
    _kvo2 = [WMTestKVO new];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"a" ofType:@"txt"];
    _kvo.data = [NSData dataWithContentsOfFile:path];
    _kvo.testKVO = @"hello";
    [_kvo addObserver:self forKeyPath:@"testKVO" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    ((void(*)(id,SEL))objc_msgSend)(_kvo,NSSelectorFromString(@"dealloc"));
    ((void(*)(id,SEL))objc_msgSend)(_kvo2,NSSelectorFromString(@"dealloc"));
    _kvo.testKVO = @"hello";
    _kvo2.testKVO = @"helo";
// Do any additional setup after loading the view, typically from a nib.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@",[change objectForKey:NSKeyValueChangeNewKey]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)click:(id)sender {
    TestViewController *testVC = [[TestViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:testVC];
    [self presentViewController:navigation animated:YES completion:nil];
//    _kvo.testKVO = @"world";
}

@end
