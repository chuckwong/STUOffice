//
//  OfficeDetailViewController.m
//  STUOffice
//
//  Created by JunhaoWang on 7/26/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "OfficeDetailViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "MBProgressHUD.h"
#import "MobClick.h"

@interface OfficeDetailViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end


@implementation OfficeDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupBackBarButton];
    [self setupWebView];
}

- (void)setupBackBarButton
{
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
}

- (void)setupWebView
{
    self.webView.delegate = self;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [self performSelector:@selector(showDetailWithURL:) withObject:_url afterDelay:0.4];
}


- (void)showDetailWithURL:(NSString *)url
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 3.0;
    [manager.requestSerializer setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.webView loadHTMLString:[self dealWithHtml:operation.responseString] baseURL:nil];
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self dealWithError];
    }];
}

// display error
- (void)dealWithError
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"获取失败(请连入校园网>_<)";
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    
    NSTimeInterval delay = 1.5;
    
    [hud hide:YES afterDelay:delay];
    
    [self performSelector:@selector(popNavVC) withObject:nil afterDelay:delay];
}

- (void)popNavVC
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (NSString *)dealWithHtml:(NSString *)responseHtml
{
    responseHtml = [[[[responseHtml stringByReplacingOccurrencesOfString:@"FONT-FAMILY: Verdana;" withString:@"background: #eeeeee;"] stringByReplacingOccurrencesOfString:@"#ffffff" withString:@"#eeeeee"] stringByReplacingOccurrencesOfString:@"<hr />" withString:@""] stringByReplacingOccurrencesOfString:@"<hr>" withString:@""];
    return responseHtml;
}


// opening url
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ( navigationType == UIWebViewNavigationTypeLinkClicked ) {
        [MobClick event:@"Open_Link"];
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}




@end













