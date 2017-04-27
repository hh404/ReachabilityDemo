//
//  APLTestTSReachabilityController.m
//  Reachability
//
//  Created by huangjianwu on 2016/11/24.
//  Copyright © 2016年 Apple Inc. All rights reserved.
//

#import "APLTestTSReachabilityController.h"
#import "TSReachabilityManager.h"

@implementation APLTestTSReachabilityController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showNetStatus:) name:kTSReachabilityChangedNotification object:nil];
    [[TSReachabilityManager shareManager] startMonitor];
}

- (void)_showNetStatus:(NSNotification*)aNo
{
    NSLog(@"userInfo:%@",[aNo.userInfo objectForKey:@"description"]);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}

@end
