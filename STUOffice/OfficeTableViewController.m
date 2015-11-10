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
#import "KGModal.h"
#import "LoginViewController.h"

#define OFFICE_COUNT_URL @"http://wechat.stu.edu.cn//webservice_oa/OA/GetDocNum"
#define OFFICE_DOCUMENT_URL @"http://wechat.stu.edu.cn//webservice_oa/OA/GetDOCDetail"

static const NSInteger kMaximunNumberOfDocuments = 20;

static const NSTimeInterval kRequestTimeout = 8.0;

@interface OfficeTableViewController () <UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *officeData;

@property (nonatomic) BOOL isLoading;

@property (nonatomic) NSUInteger resultNum;

@property (nonatomic) NSInteger pageIndex;

@end

@implementation OfficeTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // View
    [self setupBackBarButton];
    [self setupExclusiveTouch];
    [self setupTableView];
    [self setupRefreshControl];

    // Data
//    [self login];
    [self setupDocumentData];
}

#pragma mark - loginAuthentication
//- (void)login {
//
//
//
//    LoginViewController *lgvc = [[LoginViewController alloc] init];
//    lgvc.delegate = self;
//    [[KGModal sharedInstance] showWithContentViewController:lgvc];
//}

#pragma mark - SuccessLoginDelegate
//- (void)loginSucceeded {
//    [self setupOfficeData];
//}

#pragma mark - Setup Documents
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

- (void)setupDocumentData
{
    _isLoading = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [self performSelector:@selector(getDocumentList) withObject:nil afterDelay:0.7];
}

#pragma mark - refresh
- (void)pullToRefresh
{
    // 网络访问
    [MobClick event:@"Refresh"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelector:@selector(getDocumentList) withObject:nil afterDelay:0.7];
}

#pragma mark - send request

// getDocumentList
- (void)getDocumentList
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = kRequestTimeout;
    NSDictionary *parameters = @{@"row_start": @"1", @"row_end": [NSString stringWithFormat:@"%d", kMaximunNumberOfDocuments]};  // row_end means the amount
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:OFFICE_DOCUMENT_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"list - 成功 - %@", responseObject);
        self.pageIndex = 0;
        [self setupDocumentList:responseObject];
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        [MBProgressHUD  hideAllHUDsForView:self.navigationController.view animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"list - 失败 - %@", error);
        _isLoading = NO;
        [self dealWithError];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

// setupDocumentList
- (void)setupDocumentList:(NSArray *)list {
    
    NSMutableArray *documentList = [NSMutableArray array];
    
    for (NSDictionary *document in list) {
        
        NSString *documentName = [self shrinkTitle:document[@"DOCSUBJECT"]];
        NSString *documentDate = [self formateDate:document[@"DOCVALIDDATE"]];
        NSString *documentPublisher = document[@"SUBCOMPANYNAME"];
        NSString *documentPublisherAbbr = [self shrinkPublisher:documentPublisher];
        NSString *documentDetail = document[@"DOCCONTENT"];
//        NSNumber *documentRowStart = @0;
        
        NSDictionary *dict = @{@"documentName":documentName,
                               @"documentDate":documentDate,
                               @"documentPublisher":documentPublisher,
                               @"documentPublisherAbbr":documentPublisherAbbr,
                               @"documentDetail":[self flattenHTML:documentDetail trimWhiteSpace:YES],
//                               @"documentRowStart":documentRowStart,
                               };
        [documentList addObject:dict];
    }
    
    if (self.pageIndex == 0) {
        _officeData = documentList;
    } else {
        [self addNewDocumentWith:documentList];
    }
    
    [self.tableView reloadData];
    
    _isLoading = NO;
}


#pragma mark - Loading More Documents
// ScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ((scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y < self.tableView.tableFooterView.bounds.size.height) && (!_isLoading)) {
        [self getNewDocuments];
    }
}

// 获取信息
- (void)getNewDocuments
{
    [MobClick event:@"Load_More"];
    _isLoading = YES;
    self.pageIndex++;
    [(OfficeFooterView *)self.tableView.tableFooterView showLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self performSelector:@selector(getMoreDocumentList) withObject:nil afterDelay:0.7];
}

- (void)getMoreDocumentList
{
    NSInteger row_start = kMaximunNumberOfDocuments * self.pageIndex + 1;
    NSInteger row_end = kMaximunNumberOfDocuments * (self.pageIndex + 1);
    NSString *startStr = [NSString stringWithFormat:@"%d", row_start];
    NSString *endStr = [NSString stringWithFormat:@"%d", row_end];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = kRequestTimeout;
    NSDictionary *parameters = @{@"row_start": startStr, @"row_end": endStr};  // row_end means the amount
    //    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:OFFICE_DOCUMENT_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"list - 成功 - %@", responseObject);
        [self setupDocumentList:responseObject];
        [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"list - 失败 - %@", error);
        [self showHUDWithText:@"无法连接服务器" andHideDelay:1.5];
        [self performSelector:@selector(restoreState) withObject:nil afterDelay:1.5];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)addNewDocumentWith:(NSMutableArray *)officeData
{
    [_officeData addObjectsFromArray:officeData];
    [(OfficeFooterView *)self.tableView.tableFooterView hideLoading];
    _isLoading = NO;
}


#pragma mark - error display
- (void)dealWithError
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (!self.refreshControl.isRefreshing) {
        // Show AlertView
        [self showAlertView];
    } else {
        // nothing TODO
        [self showHUDWithText:@"无法连接服务器" andHideDelay:1.5];
        [self.refreshControl endRefreshing];
    }
}

- (void)showAlertView
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"错误" andMessage:@"当前网络不可用"];
    
    alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
    
    [alertView addButtonWithTitle:@"重试" type:SIAlertViewButtonTypeDestructive handler:^(SIAlertView *alertView) {
        [self setupDocumentData];
    }];
    
    [alertView show];
}

- (void)restoreState
{
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height-self.tableView.tableFooterView.frame.size.height) animated:NO];
    [(OfficeFooterView *)self.tableView.tableFooterView hideLoading];
    _isLoading = NO;
    self.pageIndex--;
}


#pragma mark - SearchPress
// searchPress
- (IBAction)searchPress:(UIBarButtonItem *)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OfficeSearchTableViewController *ostvc = [sb instantiateViewControllerWithIdentifier:@"ostvc"];
    [self.navigationController pushViewController:ostvc animated:YES];
}


#pragma mark - data formating
// publishList
+ (NSDictionary *)publisherList
{
    return @{@"汕头大学":@"汕大", @"汕头大学党委":@"党委", @"汕头大学纪委":@"纪委", @"党委宣传部":@"党宣传", @"党政办公室":@"党政办", @"纪委办公室":@"纪委办", @"监察审计处":@"审计处", @"资源管理处":@"管理处", @"党委组织统战部":@"统战部", @"至诚书院":@"至诚院", @"研究生学院":@"研学院", @"继续教育学院":@"继教院", @"长江艺术与设计学院":@"艺术院", @"长江新闻与传播学院":@"新闻院", @"艺术教育中心":@"AEC", @"英语语言中心":@"EAC", @"教师发展中心":@"教发部", @"网络与信息中心":@"网络部", @"校报编辑部":@"校报部", @"学报编辑部":@"学报部", @"华文文学编辑部":@"华文部", @"高等教育研究所":@"高研所", @"招生办公室":@"招生办", @"中心实验室":@"实验室", @"港澳台事务办公室":@"港澳室", @"国际交流合作处":@"国际处", @"发展规划办":@"发规办", @"学生创业中心":@"创业部", @"教师发展与教育评估中心":@"评估部", @"学位评定委员会":@"学评会"};
}

#pragma mark - formate method

- (NSString *)shrinkTitle:(NSString *)title
{
    return [NSString stringWithFormat:@"            %@", title];
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
    if ([date isEqual:[NSNull null]])
        return @"该文档没有日期";
    
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
    
    cell.titleNameLabel.text = _officeData[section][@"documentName"];
    cell.publisherLabel.text = _officeData[section][@"documentPublisherAbbr"];
    cell.dateLabel.text = _officeData[section][@"documentDate"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [MobClick event:@"Read"];
    NSUInteger section = indexPath.section;
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OfficeDetailViewController *odvc = [sb instantiateViewControllerWithIdentifier:@"odvc"];
    odvc.title = _officeData[section][@"documentPublisher"];
    odvc.detail = _officeData[section][@"documentDetail"];
    odvc.publisher = _officeData[section][@"documentPublisherAbbr"];
    odvc.dateStr = _officeData[section][@"documentDate"];
    odvc.documentTitle = _officeData[section][@"documentName"];
    [self.navigationController pushViewController:odvc animated:YES];
}


#pragma mark - HUD
- (void)showHUDWithText:(NSString *)string andHideDelay:(NSTimeInterval)delay {
    
    [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = string;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:delay];
}


- (NSString *)flattenHTML:(NSString *)html trimWhiteSpace:(BOOL)trim
{
    html = [html stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"《"];
    html = [html stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"》"];
    html = [html stringByReplacingOccurrencesOfString:@"!@#$%^&*" withString:@""];
    html = [html stringByReplacingOccurrencesOfString:@"&#160;" withString:@" "];
    html = [html stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    html = [html stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    
    NSScanner *theScanner = [NSScanner scannerWithString:html];
    NSString *text = nil;
    while ([theScanner isAtEnd] == NO) {
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ;
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    html = [html stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
    return trim ? [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : html;
}


@end
