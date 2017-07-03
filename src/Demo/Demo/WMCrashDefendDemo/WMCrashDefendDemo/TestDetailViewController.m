//
//  TestDetailViewController.m
//  stringAndArray
//
//  Created by guoyang on 2017/3/2.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "TestDetailViewController.h"

@interface TestDetailViewController ()
{
    NSString *_path;
}
@end

@implementation TestDetailViewController

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if(self) {
        _path = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UITextView *textView = [[UITextView alloc] init];
    [self.view addSubview:textView];
    textView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

    NSData *data = [NSData dataWithContentsOfFile:_path];
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSMutableString *string = [[NSMutableString alloc] init];
    [array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [string appendString:obj];
        [string appendString:@"\n"];
    }];
    textView.text = string;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
