/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application delegate class.
 */

#import "APLViewController.h"
#import "Reachability.h"
#import "TSReachabilityManager.h"
#import<CoreTelephony/CTTelephonyNetworkInfo.h>
#import "AFURLSessionManager.h"
#import "APLTestTSReachabilityController.h"

@interface APLViewController ()

@property (nonatomic, weak) IBOutlet UILabel* summaryLabel;

@property (nonatomic, weak) IBOutlet UITextField *remoteHostLabel;
@property (nonatomic, weak) IBOutlet UIImageView *remoteHostImageView;
@property (nonatomic, weak) IBOutlet UITextField *remoteHostStatusField;

@property (nonatomic, weak) IBOutlet UIImageView *internetConnectionImageView;
@property (nonatomic, weak) IBOutlet UITextField *internetConnectionStatusField;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *localWIFIReachability;

@property (nonatomic, strong) UITextField *localWIFIStatus;

@end




@implementation APLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.summaryLabel.hidden = YES;

    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    //Change the host name here to change the server you want to monitor.
   // NSString *remoteHostName = @"https://twitter.com";
   //NSString *remoteHostName = @"http://www.abc123.com";
    NSString *remoteHostName = @"192.168.43.1";
   // NSString *remoteHostName = @"www.baidu.com";
    NSString *remoteHostLabelFormatString = NSLocalizedString(@"Remote Host: %@", @"Remote host label format string");
    self.remoteHostLabel.text = [NSString stringWithFormat:remoteHostLabelFormatString, remoteHostName];
    
	self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
	[self.hostReachability startNotifier];
	[self updateInterfaceWithReachability:self.hostReachability];

    self.internetReachability = [Reachability reachabilityForInternetConnection];
	[self.internetReachability startNotifier];
	[self updateInterfaceWithReachability:self.internetReachability];
    
    //[[TSReachabilityManager shareManager] startMonitor];
    
    UILabel *syncLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 300, 280, 35)];
    [self.view addSubview:syncLabel];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NetworkStatus netStatus = [self.hostReachability currentReachabilityStatus];
        NSString *tips = [self syncGetNetStatus:netStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            syncLabel.text = [NSString stringWithFormat:@"同步探测结果:%@",tips];
        });
    });
    
    _localWIFIStatus = [[UITextField alloc] initWithFrame:CGRectMake(30, 250, 280, 35)];
    [self.view addSubview:_localWIFIStatus];
    self.localWIFIReachability = [Reachability reachabilityForLocalWiFi];
    [self.localWIFIReachability startNotifier];
    	[self updateInterfaceWithReachability:self.localWIFIReachability];
}

- (NSString *)syncGetNetStatus:(NetworkStatus)netStatus
{
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

- (void)startRequest
{
    NSString *URLString = @"http://192.168.43.1:8080/cateye/Status";
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURLRequest *request =
    [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:nil error:nil];;
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            //获取当前网络状态
            NetworkStatus status;
            //弹出断网alert/tips/toast等等
            if(status == NotReachable)
            {
                
            }
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    [dataTask resume];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        APLTestTSReachabilityController *ac = [[APLTestTSReachabilityController alloc] init];
        [self presentViewController:ac animated:YES completion:^{
            
        }];
    });
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
}


- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    if (reachability == self.hostReachability)
    {

        [self configureTextField:self.remoteHostStatusField
                       imageView:self.remoteHostImageView
                    reachability:reachability];
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        BOOL connectionRequired = [reachability connectionRequired];

        self.summaryLabel.hidden = (netStatus != ReachableViaWWAN);
        NSString *baseLabelText = @"";

        if (connectionRequired)
        {
            baseLabelText
                = NSLocalizedString(@"Cellular data network is available.\nInternet traffic will "
                                    @"be routed through it after a connection is established.",
                                    @"Reachability text if a connection is required");
        }
        else
        {
            baseLabelText = NSLocalizedString(
                @"Cellular data network is active.\nInternet traffic will be routed through it.",
                @"Reachability text if a connection is not required");
        }
        self.summaryLabel.text = baseLabelText;
    }

    else if (reachability == self.internetReachability)
    {
        [self configureTextField:self.internetConnectionStatusField
                       imageView:self.internetConnectionImageView
                    reachability:reachability];
    }
    else if (reachability == self.localWIFIReachability)
    {
        [self configureTextField:self.localWIFIStatus
                       imageView:self.internetConnectionImageView
                    reachability:reachability];
    }
}


- (void)configureTextField:(UITextField *)textField imageView:(UIImageView *)imageView reachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];
    NSString* statusString = @"";
    
    switch (netStatus)
    {
        case NotReachable:        {
            statusString = NSLocalizedString(@"Access Not Available", @"Text field text for access is not available");
            imageView.image = [UIImage imageNamed:@"stop-32.png"] ;
            /*
             Minor interface detail- connectionRequired may return YES even when the host is unreachable. We cover that up here...
             */
            connectionRequired = NO;
            break;
        }

        case ReachableViaWWAN:        {
            statusString = NSLocalizedString(@"Reachable WWAN", @"");
            imageView.image = [UIImage imageNamed:@"WWAN5.png"];
            break;
        }
        case ReachableViaWiFi:        {
            statusString= NSLocalizedString(@"Reachable WiFi", @"");
            imageView.image = [UIImage imageNamed:@"Airport.png"];
            break;
        }
            case kReachableVia2G:
        {
            statusString = NSLocalizedString(@"Reachable 2G", @"");
            
        }
            break;
            case kReachableVia3G:
        {
            statusString = NSLocalizedString(@"Reachable 3G", @"");
            
        }
            break;
            case kReachableVia4G:
        {
            statusString = NSLocalizedString(@"Reachable 4G", @"");
            
        }
            break;
    }
    
    if (connectionRequired)
    {
        NSString *connectionRequiredFormatString = NSLocalizedString(@"%@, Connection Required", @"Concatenation of status string with connection requirement");
        statusString= [NSString stringWithFormat:connectionRequiredFormatString, statusString];
    }
    textField.text= statusString;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}


@end
