//
//  LoginViewController.h
//  stuget
//
//  Created by JunhaoWang on 8/1/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SuccessLoginDelegate <NSObject>

- (void)loginSucceeded;

@end




@interface LoginViewController : UIViewController
@property (weak, nonatomic) id <SuccessLoginDelegate>delegate;
@end
