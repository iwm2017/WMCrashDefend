//
//  TestViewController.m
//  stringAndArray
//
//  Created by guoyang on 2017/3/1.
//  Copyright © 2017年 guoyang. All rights reserved.
//

#import "TestViewController.h"
#import <WMCrashDefend/WMCrashDefend.h>
#import "TestDetailViewController.h"

@interface TestViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray *_nameArray;
    NSMutableArray *_pathArray;
}

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"dismiss" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [btn sizeToFit];
    btn.center = CGPointMake(self.view.frame.size.width/2, 20);
    [self.view addSubview:btn];
    
    UITableView *testTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height - 100)];
    testTableView.delegate = self;
    testTableView.dataSource = self;
    [self.view addSubview:testTableView];
    [WMCrashHandler getExceptionInfoWithCompletionBlocK:^(NSDictionary *info) {
        _nameArray = [info objectForKey:WMCrashLoggerFileNameListKey];
        _pathArray = [info objectForKey:WMCrashLoggerFilePathListKey];
        __strong UITableView *tableView = testTableView;
        [tableView reloadData];
    }];
}

- (void)dismiss:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_nameArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"test"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
    }
    cell.textLabel.text = [_nameArray objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *path = [_pathArray objectAtIndex:indexPath.row];
    TestDetailViewController *testDetail = [[TestDetailViewController alloc] initWithPath:path];
    [self.navigationController pushViewController:testDetail animated:YES];
}

@end
