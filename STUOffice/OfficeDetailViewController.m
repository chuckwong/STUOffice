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
#import "OfficeLabel.h"

@interface OfficeDetailViewController ()

@property (weak, nonatomic) IBOutlet UIView *officeView;
@property (weak, nonatomic) IBOutlet UILabel *publisherLabel;
@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@property (weak, nonatomic) IBOutlet OfficeLabel *documentTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation OfficeDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupBackBarButton];
    [self setupView];
    [self setupData];
    NSLog(@"%@", _detail);
}

#pragma mark - setup method
- (void)setupBackBarButton
{
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
}

- (void)setupView {
    // officeView
    self.officeView.layer.cornerRadius = 4.0;
    
    // publisherLabel
    self.publisherLabel.layer.cornerRadius = 2.5;
    self.publisherLabel.layer.masksToBounds = YES;
}

- (void)setupData {
    _documentTitleLabel.text = _documentTitle;
    // force detailTextView appears on the top (wo zhen tm ji zhi)
    _detailTextView.scrollEnabled = false;
    _detailTextView.text = _detail;
    _detailTextView.scrollEnabled = true;
    _publisherLabel.text = _publisher;
    _dateLabel.text = _dateStr;
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





@end













