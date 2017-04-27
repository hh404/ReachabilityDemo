//
//  TSReachabilityManager.m
//  Reachability
//
//  Created by huangjianwu on 16/9/29.
//  Copyright © 2016年 Apple Inc. All rights reserved.
//

#import "TSReachabilityManager.h"


NSString *kTSReachabilityChangedNotification = @"kTSNetworkReachabilityChangedNotification";


static TSReachabilityManager *gTSReachabilityManager = nil;

@interface TSReachabilityManager ()

@property (nonatomic, strong) NSThread *reachabilityDaemonThread;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, assign) NetworkStatus currentReachabilityStatus;
@end

@implementation TSReachabilityManager

+ (instancetype)shareManager;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gTSReachabilityManager = [[TSReachabilityManager alloc] init];
        [gTSReachabilityManager _setup];
    });
    
    return gTSReachabilityManager;
}

- (void)_setup
{
    _remoteHostName = @"www.baidu.com";
    [self startMonitor];
}

- (void)startMonitor
{
    //启动守护线程，防止服务器在长时间无响应导致的看门狗杀死app的情形发生
    _reachabilityDaemonThread = [[NSThread alloc] initWithTarget:self selector:@selector(monitorNetReachability) object:nil];
    [_reachabilityDaemonThread start];
    
}

- (void)monitorNetReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //Change the host name here to change the server you want to monitor.

    //能够判断出远程服务器时候可达，ping不通的时候,还是wifi连接状态。服务器状态还是用接口返回情况来判断准确，只有需要判断connectionRequired的时候才用host
    self.internetReachability = [Reachability reachabilityWithHostName:_remoteHostName];
    [self.internetReachability startNotifier];
    
    
    //保持线程不退出
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
    
    _currentReachabilityStatus = [self currentReachabilityStatus];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_currentReachabilityStatus],@"status",[self netStatusDescription],@"description", nil];
         [[NSNotificationCenter defaultCenter] postNotificationName:kTSReachabilityChangedNotification object:self userInfo:dic];
    });

}


/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    _currentReachabilityStatus = [curReach currentReachabilityStatus];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_currentReachabilityStatus],@"status",[self netStatusDescription],@"description", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTSReachabilityChangedNotification object:self userInfo:dic];
    });
}



- (NSString*)netStatusDescription
{
    NetworkStatus netStatus = [self currentReachabilityStatus];
    NSString *tips = @"";
    switch (netStatus)
    {
        case NotReachable:
            tips = @"无网络连接";
            break;
            
        case ReachableViaWiFi:
            tips = @"Wifi";
            break;
            
        case ReachableViaWWAN:
            NSLog(@"移动流量");
        case kReachableVia2G:
            tips = @"2G";
            break;
            
        case kReachableVia3G:
            tips = @"3G";
            break;
            
        case kReachableVia4G:
            tips = @"4G";
            break;
        default:
            tips = @"正在获取状态";
    }
    return tips;
}




- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
