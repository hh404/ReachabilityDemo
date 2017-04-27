//
//  TSReachabilityManager.h
//  Reachability
//
//  Created by huangjianwu on 16/9/29.
//  Copyright © 2016年 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

extern NSString *kTSReachabilityChangedNotification;

@interface TSReachabilityManager : NSObject

@property (nonatomic, strong) NSString *remoteHostName;

+ (instancetype)shareManager;

- (void)startMonitor;

@end
