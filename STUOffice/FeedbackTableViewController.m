//
//  FeedbackTableViewController.m
//  STUOffice
//
//  Created by JunhaoWang on 8/30/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "FeedbackTableViewController.h"
#import "MBProgressHUD.h"
#import "MobClick.h"
#import "AFNetworking.h"

@interface FeedbackTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation FeedbackTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-14, 0, 0, 0);
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)send:(id)sender
{
    [self.textView resignFirstResponder];
    [self sendFeedBack];
}


- (void)sendFeedBack
{
    if (self.textView.text.length > 0) {
        // 有输入
        if (self.textView.text.length > 150) {
            // 输入过长
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"您的反馈太长了...";
            hud.margin = 10.f;
            hud.removeFromSuperViewOnHide = YES;
            
            [hud hide:YES afterDelay:1.5];
        } else {
            if ([self hasReachLimit]) {
                // 超过限制的两次发送
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"您的反馈次数已达到上限>_<";
                hud.margin = 10.f;
                hud.removeFromSuperViewOnHide = YES;
                
                [hud hide:YES afterDelay:1.5];
            } else {
                // ok
                [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                [self sendRequest];
            }
        }
    } else {
        // 空白输入
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"请输入反馈";
        hud.margin = 10.f;
        hud.removeFromSuperViewOnHide = YES;
        
        [hud hide:YES afterDelay:1.5];
    }
}

#define FEEDBACK_KEY @"KqePnWoGfHhbLCU4yoPEXi5qXWQk69IE"
#define FEEDBACK_URL @"http://chuckwo.com/stuoffice/feedback.json"

- (void)sendRequest
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    manager.requestSerializer.timeoutInterval = 8.0;
    
    NSDictionary *parameters = @{@"device": @"iOS", @"key": FEEDBACK_KEY, @"content": self.textView.text};
    
    [manager POST:FEEDBACK_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"成功");
        NSLog(@"code - %@", [responseObject objectForKey:@"code"]);
        if ([[responseObject objectForKey:@"code"] integerValue] == 0) {
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"发送成功! (谢谢您的反馈>_<)";
            hud.margin = 10.f;
            hud.removeFromSuperViewOnHide = YES;
            
            [hud hide:YES afterDelay:1.5];
            [self performSelector:@selector(pop) withObject:nil afterDelay:1.5];
            // ud
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            NSInteger times = [ud integerForKey:@"feedback"];
            times++;
            [ud setInteger:times forKey:@"feedback"];
            
            [MobClick event:@"Feedback"];
        } else {
            // unknown error
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self.textView becomeFirstResponder];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"无法连接服务器";
            hud.margin = 10.f;
            hud.removeFromSuperViewOnHide = YES;
            
            [hud hide:YES afterDelay:1.5];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败");
        
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"无法连接服务器";
        hud.margin = 10.f;
        hud.removeFromSuperViewOnHide = YES;
        
        [hud hide:YES afterDelay:1.5];
    }];
}

- (BOOL)hasReachLimit
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSInteger feedbackTimes = [ud integerForKey:@"feedback"];
    
    if (feedbackTimes > 2) {
        return YES;
    } else {
        return NO;
    }
}

- (void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
