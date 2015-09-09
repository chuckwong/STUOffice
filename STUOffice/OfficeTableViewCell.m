//
//  OfficeTableViewCell.m
//  STUOffice
//
//  Created by JunhaoWang on 7/25/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "OfficeTableViewCell.h"

@interface OfficeTableViewCell ()


@end



@implementation OfficeTableViewCell


- (void)awakeFromNib
{
    [super awakeFromNib];
    // officeView
    self.officeView.layer.cornerRadius = 4.0;
    
    // 阴影 添加后返回有点点卡
//    self.officeView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
//    self.officeView.layer.shouldRasterize = YES;
//    self.officeView.layer.shadowOpacity = 0.1;
//    self.officeView.layer.shadowOffset = CGSizeMake(-0.2, 0.2);
//    self.officeView.layer.shadowColor = [UIColor blackColor].CGColor;
    
    // publisherLabel
    _publisherLabel.layer.cornerRadius = 2.5;
    _publisherLabel.layer.masksToBounds = YES;
} 







@end
