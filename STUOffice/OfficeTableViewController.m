//
//  OfficeTableViewController.m
//  STUOffice
//
//  Created by JunhaoWang on 7/25/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "OfficeTableViewController.h"
#import "OfficeDetailViewController.h"
#import "OfficeSearchTableViewController.h"
#import "OfficeTableViewCell.h"
#import <AFNetworking/AfNetworking.h>
#import "MBProgressHUD.h"
#import "OfficeLabel.h"
#import "OfficeFooterView.h"
#import "Define.h"
#import "MobClick.h"
#import "SIAlertView.h"

#define OFFICE_URL @"http://office.stu.edu.cn/csweb/list.jsp"

@interface OfficeTableViewController () <UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *officeData;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) NSUInteger resultNum;

@end

@implementation OfficeTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBackBarButton];
    [self setupExclusiveTouch];
    [self setupTableView];
    [self setupRefreshControl];
    [self setupOfficeData];
    
    // 去掉黑边
    for (UIView *view1 in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view1.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]] && view2.bounds.size.height <= 1.0) {
                [view2 removeFromSuperview];
            }
        }
    }
}

#pragma mark - setup
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

- (void)setupTableView
{
    // FooterView
    OfficeFooterView *footerView = [[OfficeFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
    self.tableView.tableFooterView = footerView;
}

- (void)setupRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)setupOfficeData
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [self performSelector:@selector(sendRequest) withObject:nil afterDelay:0.7];
}

#pragma mark - refresh
- (void)pullToRefresh
{
    // 网络访问
    [MobClick event:@"Refresh"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelector:@selector(sendRequest) withObject:nil afterDelay:0.7];
}


#pragma mark - send request
// 发送请求
- (void)sendRequest
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 3.0;
    [manager.requestSerializer setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSDictionary *parameters = @{@"pageindex": @"1", @"pagesize": @"25"};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:OFFICE_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"成功");
        [self getTotalNum:operation.responseString];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败 - %@", error);
        [self dealWithError];
    }];
}

// 获取总数
- (void)getTotalNum:(NSString *)responseHtml
{
    NSString *pantten = [NSString stringWithFormat:@"共(\\d+)条记录"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pantten options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:NULL];
    NSTextCheckingResult *result = [regex firstMatchInString:responseHtml options:0 range:NSMakeRange(0, [responseHtml length])];
    if (result) {
        // 得到结果数 > 0
        NSString *resultNumStr = [responseHtml substringWithRange:[result rangeAtIndex:1]];
        NSUInteger resultNum = [resultNumStr integerValue];
        _resultNum = resultNum;
        [self dealWithResponseHtml:responseHtml];
    } else {
        // 一般不会发生 - 未知错误 - 网页被修改了
        [self dealWithError];
    }
}

// 解析办公自动化信息
- (void)dealWithResponseHtml:(NSString *)responseHtml
{
    NSString *pattern = [NSString stringWithFormat:@"<TR class=datalight>\\s*<TD width=\".*?\" style=\"height:25px;\"><a target ='_blank'  href='(.*?)' title='(.*?)'><img class=\"vt\" src=\"/csweb/images/38.jpg\"/><span style=\"padding-top:2px;\">.*?</span></a></TD>\\s*<TD width=\".*?\" align=\"center\">(.*?)</TD>\\s*<TD width=\".*?\" align=\"center\">(.*?)</TD>\\s*</TR>"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:NULL];
    NSArray *matchedArray = [regex matchesInString:responseHtml options:0 range:NSMakeRange(0, responseHtml.length)];
    if (matchedArray.count > 0) {
        // 匹配成功
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSMutableArray *officeData = [NSMutableArray array];
        for (NSTextCheckingResult *result in matchedArray) {
            
            NSString *contentURL = [@"http://office.stu.edu.cn" stringByAppendingString:[responseHtml substringWithRange:[result rangeAtIndex:1]]];
            NSString *titleName = [self shrinkTitle:[responseHtml substringWithRange:[result rangeAtIndex:2]]];
            NSString *publisher1 = [self shrinkPublisher:[responseHtml substringWithRange:[result rangeAtIndex:3]]];
            NSString *publisher2 = [responseHtml substringWithRange:[result rangeAtIndex:3]];
            NSString *date = [self formateDate:[responseHtml substringWithRange:[result rangeAtIndex:4]]];
        
            NSMutableDictionary *office = [NSMutableDictionary dictionaryWithDictionary:@{@"contentURL": contentURL, @"titleName": titleName, @"publisher1": publisher1, @"publisher2": publisher2, @"date": date}];
            
            [officeData addObject:office];
        }
        _officeData = officeData;
        [self.tableView reloadData];
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
    } else {
        // 一般不会发生 - 未知错误 - 网页被修改了
        NSLog(@"没有匹配");
        [self dealWithError];
    }
}

#pragma mark - formate
- (NSString *)shrinkTitle:(NSString *)title
{
    return [NSString stringWithFormat:@"          %@", title];
}


- (NSString *)shrinkPublisher:(NSString *)publisher
{
    NSDictionary *list = [OfficeTableViewController publisherList];
    for (id key in list) {
        if ([publisher isEqualToString:key]) {
            return [list objectForKey:key];
        }
    }
    return publisher;
}


- (NSString *)formateDate:(NSString *)date
{
    NSArray *strArray = [date componentsSeparatedByString:@"-"];
    return [NSString stringWithFormat:@"%@年%@月%@日", strArray[0], strArray[1], strArray[2]];
}


#pragma mark - tableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _officeData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    
    OfficeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OFFICECELL"];
    
    cell.titleNameLabel.text = _officeData[section][@"titleName"];
    cell.publisherLabel.text = _officeData[section][@"publisher1"];
    cell.dateLabel.text = _officeData[section][@"date"];
    
    // 居上
    [((OfficeLabel *)cell.titleNameLabel) setVerticalAlignment:VerticalAlignmentTop];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [MobClick event:@"Read"];
    NSUInteger section = indexPath.section;
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OfficeDetailViewController *odvc = [sb instantiateViewControllerWithIdentifier:@"odvc"];
    odvc.title = _officeData[section][@"publisher2"];
    odvc.url = _officeData[section][@"contentURL"];
    [self.navigationController pushViewController:odvc animated:YES];
}


#pragma mark - loading new
// 加载更多数据
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ((scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y < self.tableView.tableFooterView.bounds.size.height) && (_officeData.count < _resultNum) && (!_isLoading)) {
        [self getNewOffice];
    }
}

// 获取信息
- (void)getNewOffice
{
    [MobClick event:@"Load_More"];
    _isLoading = YES;
    [(OfficeFooterView *)self.tableView.tableFooterView showLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self performSelector:@selector(sendNewRequest) withObject:nil afterDelay:0.7];
}


- (void)sendNewRequest
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 3.0;
    [manager.requestSerializer setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSInteger page = _officeData.count / 25 + 1;
    NSLog(@"page - %ld", (long)page);
    NSDictionary *parameters = @{@"pageindex": [NSString stringWithFormat:@"%ld", (long)page], @"pagesize": @"25"};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:OFFICE_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"成功");
        [self dealWithNewResponseHtml:operation.responseString];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败 - %@", error);
        NSLog(@"没有匹配");
        [self dealWithErrorWhileLoadingNew];
    }];
}


- (void)dealWithNewResponseHtml:(NSString *)responseHtml
{
    NSString *pattern = [NSString stringWithFormat:@"<TR class=datalight>\\s*<TD width=\".*?\" style=\"height:25px;\"><a target ='_blank'  href='(.*?)' title='(.*?)'><img class=\"vt\" src=\"/csweb/images/38.jpg\"/><span style=\"padding-top:2px;\">.*?</span></a></TD>\\s*<TD width=\".*?\" align=\"center\">(.*?)</TD>\\s*<TD width=\".*?\" align=\"center\">(.*?)</TD>\\s*</TR>"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:NULL];
    NSArray *matchedArray = [regex matchesInString:responseHtml options:0 range:NSMakeRange(0, responseHtml.length)];
    if (matchedArray.count > 0) {
        // 匹配成功
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSMutableArray *officeData = [NSMutableArray array];
        for (NSTextCheckingResult *result in matchedArray) {
            
            NSString *contentURL = [@"http://office.stu.edu.cn" stringByAppendingString:[responseHtml substringWithRange:[result rangeAtIndex:1]]];
            NSString *titleName = [self shrinkTitle:[responseHtml substringWithRange:[result rangeAtIndex:2]]];
            NSString *publisher1 = [self shrinkPublisher:[responseHtml substringWithRange:[result rangeAtIndex:3]]];
            NSString *publisher2 = [responseHtml substringWithRange:[result rangeAtIndex:3]];
            NSString *date = [self formateDate:[responseHtml substringWithRange:[result rangeAtIndex:4]]];
            
            NSMutableDictionary *office = [NSMutableDictionary dictionaryWithDictionary:@{@"contentURL": contentURL, @"titleName": titleName, @"publisher1": publisher1, @"publisher2": publisher2, @"date": date}];
            
            [officeData addObject:office];
        }
        [self addNewOfficeWith:officeData];
    } else {
        NSLog(@"没有匹配");
        // 一般不会发生 - 未知错误 - 网页被修改了
        [self dealWithErrorWhileLoadingNew];
    }
}

- (void)addNewOfficeWith:(NSMutableArray *)officeData
{
    [_officeData addObjectsFromArray:officeData];
    [self.tableView reloadData];
    [(OfficeFooterView *)self.tableView.tableFooterView hideLoading];
    if (_officeData.count >= _resultNum) {
        UIView *endFooterView = [[UIView alloc] initWithFrame:CGRectMake(8.6f, 0, self.tableView.bounds.size.width-8.6f, 0.3)];
        endFooterView.backgroundColor = RGB(200, 199, 204);
        self.tableView.tableFooterView = endFooterView;
    }
    _isLoading = NO;
}


#pragma mark - error display
// while loading firstly
- (void)dealWithError
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (!self.refreshControl.isRefreshing) {
        // Show AlertView
        [self showAlertView];
    } else {
        // nothing TODO
        [self.refreshControl endRefreshing];
    }
}

- (void)showAlertView
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提示" andMessage:@"获取失败\n(请连入校园网>_<)"];
    
    alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
    
    [alertView addButtonWithTitle:@"重试" type:SIAlertViewButtonTypeDestructive handler:^(SIAlertView *alertView) {
        [self setupOfficeData];
    }];
    
    [alertView show];
}

// while getting new
- (void)dealWithErrorWhileLoadingNew
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
    
    [self performSelector:@selector(restoreState) withObject:nil afterDelay:delay];
}

- (void)restoreState
{
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height-self.tableView.tableFooterView.frame.size.height) animated:NO];
    [(OfficeFooterView *)self.tableView.tableFooterView hideLoading];
    _isLoading = NO;
}

// searchPress
- (IBAction)searchPress:(UIBarButtonItem *)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OfficeSearchTableViewController *ostvc = [sb instantiateViewControllerWithIdentifier:@"ostvc"];
    [self.navigationController pushViewController:ostvc animated:YES];
}


// publishList
+ (NSDictionary *)publisherList
{
    return @{@"汕头大学":@"汕大", @"汕头大学党委":@"党委", @"汕头大学纪委":@"纪委", @"党委宣传部":@"党宣传", @"党政办公室":@"党政办", @"纪委办公室":@"纪委办", @"监察审计处":@"审计处", @"资源管理处":@"管理处", @"党委组织统战部":@"统战部", @"至诚书院":@"至诚院", @"研究生学院":@"研学院", @"继续教育学院":@"继教院", @"长江艺术与设计学院":@"艺术院", @"长江新闻与传播学院":@"新闻院", @"艺术教育中心":@"AEC", @"英语语言中心":@"EAC", @"教师发展中心":@"教发部", @"网络与信息中心":@"网络部", @"校报编辑部":@"校报部", @"学报编辑部":@"学报部", @"华文文学编辑部":@"华文部", @"高等教育研究所":@"高研所", @"招生办公室":@"招生办", @"中心实验室":@"实验室", @"港澳台事务办公室":@"港澳室", @"国际交流合作处":@"国际处", @"发展规划办":@"发规办", @"学生创业中心":@"创业部", @"教师发展与教育评估中心":@"评估部", @"学位评定委员会":@"学评会"};
}

@end
