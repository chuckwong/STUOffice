//
//  LoginViewController.m
//  stuget
//
//  Created by JunhaoWang on 8/1/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "LoginViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "BZGFormField.h"
#import "KGModal.h"
#import <CommonCrypto/CommonDigest.h>
#import "MBProgressHUD.h"

#define RGB(r, g, b) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:1.0]

#define LOGIN_URL @"http://wechat.stu.edu.cn//webservice_oa/OA/Login"

@interface LoginViewController () <BZGFormFieldDelegate>

@property (strong, nonatomic) BZGFormField *usernameField;
@property (strong, nonatomic) BZGFormField *passwordField;
@end


@implementation LoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupView];
}


- (void)setupView
{
    // self
    self.view.frame = CGRectMake(0, 0, 240, 150);
    
    // titleLabel
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-102, 6, 86, 24)];
    leftLabel.text = @"STU";
    leftLabel.textColor = RGB(146, 196, 89);
    leftLabel.textAlignment = NSTextAlignmentRight;
    leftLabel.font = [UIFont boldSystemFontOfSize:19.5];
    [self.view addSubview:leftLabel];
    
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-16, 6, 100, 24)];
    rightLabel.text = @"CHECK";
    rightLabel.textColor = RGB(255, 84, 73);
    rightLabel.textAlignment = NSTextAlignmentLeft;
    rightLabel.font = [UIFont boldSystemFontOfSize:19.5];
    [self.view addSubview:rightLabel];
    
    // noticeLabal
    UILabel *noticeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
    noticeLabel.center = CGPointMake(self.view.frame.size.width/2.0, self.view.frame.size.height-11);
    noticeLabel.text = @"☞ 我们不知道您的密码";
    noticeLabel.textColor = [UIColor grayColor];
    noticeLabel.textAlignment = NSTextAlignmentRight;
    noticeLabel.font = [UIFont systemFontOfSize:13.0];
    [self.view addSubview:noticeLabel];
    
    // field
    _usernameField = [[BZGFormField alloc] initWithFrame:CGRectMake(46, 62, 200, 40)];
    _passwordField = [[BZGFormField alloc] initWithFrame:CGRectMake(46, 109, 200, 40)];
    
    _usernameField.center = CGPointMake(self.view.frame.size.width/2.0, 62);
    _passwordField.center = CGPointMake(self.view.frame.size.width/2.0, 109);
    
    _usernameField.textField.placeholder = @"校园网账号";
    _passwordField.textField.placeholder = @"校园网密码";
    
    _passwordField.textField.secureTextEntry = YES;
    _usernameField.textField.returnKeyType = UIReturnKeyNext;
    _passwordField.textField.returnKeyType = UIReturnKeyGo;
    _usernameField.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    // delegate
    _usernameField.delegate = self;
    _passwordField.delegate = self;
    
    // block
    [self.usernameField setTextValidationBlock:^BOOL(NSString *text) {
        return (text.length > 0);
    }];
    
    [self.passwordField setTextValidationBlock:^BOOL(NSString *text) {
        return (text.length >= 6);
    }];
    
    // target
    _usernameField.textField.tag = 0;
    [_usernameField.textField addTarget:self action:@selector(returnKeyPress:) forControlEvents:UIControlEventEditingDidEndOnExit];
    _passwordField.textField.tag = 1;
    [_passwordField.textField addTarget:self action:@selector(returnKeyPress:) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self.view addSubview:_usernameField];
    [self.view addSubview:_passwordField];
    
    // set Text
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *username = [ud stringForKey:@"USERNAME"];
    NSString *password = [ud stringForKey:@"PASSWORD"];
    
    if (username && password) {
        _usernameField.textField.text = username;
        [_usernameField setupFormFieldState:BZGFormFieldStateValid];
        [_passwordField setupFormFieldState:BZGFormFieldStateValid];
    } else {
        [self.usernameField.textField becomeFirstResponder];
    }
}


- (void)returnKeyPress:(UITextField *)sender
{
    if (sender.tag == 0) {
        [_passwordField.textField becomeFirstResponder];
    } else if (sender.tag == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self loginCheck];
    }
}


- (void)loginCheck
{
    if (_usernameField.textField.text.length == 0 && _passwordField.textField.text.length == 0) {
        [self showHUDWithText:@"请输入账号和密码" andHideDelay:1.0];
        [_usernameField.textField becomeFirstResponder];
    } else if (_usernameField.textField.text.length == 0) {
        [self showHUDWithText:@"请输入账号" andHideDelay:1.0];
        [_usernameField.textField becomeFirstResponder];
    } else if (_passwordField.textField.text.length == 0) {
        [self showHUDWithText:@"请输入密码" andHideDelay:1.0];
        [_passwordField.textField becomeFirstResponder];
    } else if (_passwordField.textField.text.length < 6) {
        [self showHUDWithText:@"请输入6位或6位以上的密码" andHideDelay:1.0];
        [_passwordField.textField becomeFirstResponder];
    } else {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self sendRequest];
    }
}

- (void)showHUDWithText:(NSString *)string andHideDelay:(NSTimeInterval)delay {
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = string;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:delay];
}


- (void)sendRequest
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    manager.requestSerializer.timeoutInterval = 8.0;
    
    NSDictionary *parameters = @{@"username": _usernameField.textField.text,
                                 @"password": _passwordField.textField.text,
                                 };
    
    [manager GET:LOGIN_URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // not run
//        NSLog(@"login成功 - %@", operation.responseString);
//        NSLog(@"----%@", responseObject);
//        [self dealWithResponseObject:responseObject];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"login - %@", operation.responseString);
        
        [self dealWithResponseObject:operation.responseString];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)dealWithResponseObject:(NSString *)responseString
{
    if ([responseString isEqualToString:@"1"]) {
        
        [self showHUDWithText:@"登录成功" andHideDelay:1.4];
        // set ud
        [[NSUserDefaults standardUserDefaults] setObject:_usernameField.textField.text forKey:@"USERNAME"];
        [[NSUserDefaults standardUserDefaults] setObject:_passwordField.textField.text forKey:@"PASSWORD"];
        
        [self performSelector:@selector(returnToVC) withObject:nil afterDelay:1.2];
        
    } else if ([responseString isEqualToString:@"0"]) {
        [self showHUDWithText:@"账号或密码不正确" andHideDelay:1.0];
        [_passwordField.textField becomeFirstResponder];
    } else {
        [self showHUDWithText:@"无法连接服务器" andHideDelay:1.0];
        [_passwordField.textField becomeFirstResponder];
    }
}


- (void)returnToVC {
    [[KGModal sharedInstance] hideWithCompletionBlock:^{
        [_delegate loginSucceeded];
    }];
}


@end






