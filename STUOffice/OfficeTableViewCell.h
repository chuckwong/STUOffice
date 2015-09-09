//
//  OfficeTableViewCell.h
//  STUOffice
//
//  Created by JunhaoWang on 7/25/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OfficeTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *officeView;
@property (strong, nonatomic) IBOutlet UILabel *titleNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *publisherLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@end
