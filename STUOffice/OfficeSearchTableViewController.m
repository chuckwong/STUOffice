//
//  OfficeSearchTableViewController.m
//  STUOffice
//
//  Created by JunhaoWang on 7/28/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "OfficeSearchTableViewController.h"
#import "OfficeSearchBar.h"
#import "MBProgressHUD.h"
#import <AFNetworking/AFNetworking.h>
#import "OfficeDetailViewController.h"
#import "OfficeFooterView.h"
#import "OfficeTableViewCell.h"
#import "OfficeLabel.h"
#import "Define.h"
#import "MobClick.h"

#define OFFICE_URL @"http://office.stu.edu.cn/csweb/list.jsp"

@interface OfficeSearchTableViewController () <UISearchBarDelegate>

@property (strong, nonatomic) OfficeSearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *officeData;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) NSUInteger resultNum;

@end

@implementation OfficeSearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupBackBarButton];
    [self setupTableView];
    [self setupSearchBar];
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


- (void)setupSearchBar
{
    self.searchBar = [[OfficeSearchBar alloc] initWithFrame:CGRectMake(40, 0, self.view.bounds.size.width - 52, 44)];
    self.searchBar.placeholder = @"搜索";
    self.searchBar.text = @"";
    self.searchBar.delegate = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    [self.searchBar becomeFirstResponder];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [MobClick event:@"Search" attributes:@{@"content": searchBar.text}];
    [self.searchBar resignFirstResponder];
    [self setupOfficeData:searchBar.text];
}


- (void)setupTableView
{
    // FooterView
    OfficeFooterView *footerView = [[OfficeFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
    self.tableView.tableFooterView = footerView;
}


- (void)setupOfficeData:(NSString *)keyword
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"正在搜索";
    [self performSelector:@selector(sendRequest:) withObject:keyword afterDelay:0.7];
}


#pragma mark - send request
// 发送请求
- (void)sendRequest:(NSString *)keyword
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    manager.requestSerializer.stringEncoding = enc;
    manager.requestSerializer.timeoutInterval = 20.0;
//    [manager.requestSerializer setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSDictionary *parameters = @{@"pageindex": @"1", @"pagesize": @"25", @"keyword": keyword, @"searchBtn": @""};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:OFFICE_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"成功");
        [self getTotalNum:operation.responseString];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败 - %@", error);
        [self dealWithErrorWhileSeaching];
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
        NSLog(@"记录条数: %lu", (unsigned long)resultNum);
        _resultNum = resultNum;
        if (_resultNum > 0) {
            [self dealWithResponseHtml:responseHtml];
        } else {
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"找不到有关信息";
            hud.margin = 10.f;
            hud.removeFromSuperViewOnHide = YES;
            
            NSTimeInterval delay = 1.5;
            
            [hud hide:YES afterDelay:delay];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self performSelector:@selector(restoreSearching) withObject:nil afterDelay:delay];
        }
    } else {
        // 一般不会发生 - 未知错误 - 网页被修改了
        [self dealWithErrorWhileSeaching];
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
//        [self.tableView setContentOffset:CGPointMake(0, 0)];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    } else {
        NSLog(@"没有匹配");
        // 一般不会发生 - 未知错误 - 网页被修改了
        [self dealWithErrorWhileSeaching];
    }
}

#pragma mark - formate
- (NSString *)shrinkTitle:(NSString *)title
{
    return [NSString stringWithFormat:@"            %@", title];
}


- (NSString *)shrinkPublisher:(NSString *)publisher
{
    NSDictionary *list = [OfficeSearchTableViewController publisherList];
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
    
    OfficeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OFFICESEARCHCELL"];
    
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
    [self.searchBar resignFirstResponder];
    [self.navigationController pushViewController:odvc animated:YES];
}


#pragma mark - getting new
// 加载更多数据
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ((scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y < self.tableView.tableFooterView.bounds.size.height) && (_officeData.count < _resultNum) && (!_isLoading)) {
        [self getNewOffice];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (_officeData.count > 0) {
        [self.searchBar resignFirstResponder];
    }
}


// 获取信息
- (void)getNewOffice
{
    [MobClick event:@"Load_More"];
    _isLoading = YES;
    [(OfficeFooterView *)self.tableView.tableFooterView showLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self performSelector:@selector(sendNewRequest:) withObject:self.searchBar.text afterDelay:0.7];
}

- (void)sendNewRequest:(NSString *)keyword
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    manager.requestSerializer.stringEncoding = enc;
    manager.requestSerializer.timeoutInterval = 8.0;
    [manager.requestSerializer setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSInteger page = _officeData.count / 25 + 1;
    NSLog(@"page - %ld", (long)page);
    NSDictionary *parameters = @{@"pageindex": [NSString stringWithFormat:@"%ld", (long)page], @"pagesize": @"25", @"keyword": keyword, @"searchBtn": @""};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:OFFICE_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"成功");
        [self dealWithNewResponseHtml:operation.responseString];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败 - %@", error);
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
// searching
- (void)dealWithErrorWhileSeaching
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
    
    [self performSelector:@selector(restoreSearching) withObject:nil afterDelay:delay];
}

- (void)restoreSearching
{
    [self.searchBar becomeFirstResponder];
}

// loading new
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


// publisherList
+ (NSDictionary *)publisherList
{
    return @{@"汕头大学":@"汕大", @"汕头大学党委":@"党委", @"汕头大学纪委":@"纪委", @"党委宣传部":@"党宣传", @"党政办公室":@"党政办", @"纪委办公室":@"纪委办", @"监察审计处":@"审计处", @"资源管理处":@"管理处", @"党委组织统战部":@"统战部", @"至诚书院":@"至诚院", @"研究生学院":@"研学院", @"继续教育学院":@"继教院", @"长江艺术与设计学院":@"艺术院", @"长江新闻与传播学院":@"新闻院", @"艺术教育中心":@"AEC", @"英语语言中心":@"EAC", @"教师发展中心":@"教发部", @"网络与信息中心":@"网络部", @"校报编辑部":@"校报部", @"学报编辑部":@"学报部", @"华文文学编辑部":@"华文部", @"高等教育研究所":@"高研所", @"招生办公室":@"招生办", @"中心实验室":@"实验室", @"港澳台事务办公室":@"港澳室", @"国际交流合作处":@"国际处", @"发展规划办":@"发规办", @"学生创业中心":@"创业部", @"教师发展与教育评估中心":@"评估部", @"学位评定委员会":@"学评会"};
}


@end
