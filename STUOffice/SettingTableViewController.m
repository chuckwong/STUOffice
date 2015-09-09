//
//  SettingTableViewController.m
//  STUOffice
//
//  Created by JunhaoWang on 8/30/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "SettingTableViewController.h"
#import "AboutViewController.h"
#import "FeedbackTableViewController.h"

@interface SettingTableViewController ()

@end

@implementation SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBackBarButton];
    [self setupExclusiveTouch];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-14, 0, 0, 0);
}

- (void)setupBackBarButton
{
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
}

- (void)setupExclusiveTouch
{
    self.navigationController.navigationBar.exclusiveTouch = YES;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        [view setExclusiveTouch:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 去掉黑边
    for (UIView *view1 in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view1.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]] && view2.bounds.size.height <= 1.0) {
                [view2 removeFromSuperview];
            }
        }
    }
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (indexPath.section == 0) {
        NSLog(@"关于我们");
        AboutViewController *avc = [sb instantiateViewControllerWithIdentifier:@"avc"];
        [self.navigationController pushViewController:avc animated:YES];
    } else {
        NSLog(@"反馈");
        FeedbackTableViewController *ftvc = [sb instantiateViewControllerWithIdentifier:@"ftvc"];
        [self.navigationController pushViewController:ftvc animated:YES];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
