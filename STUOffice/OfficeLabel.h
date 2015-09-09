//
//  OfficeLabel.h
//  STUOffice
//
//  Created by JunhaoWang on 7/26/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    VerticalAlignmentTop = 0, // default
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,
} VerticalAlignment;

@interface OfficeLabel : UILabel

@property (nonatomic) VerticalAlignment verticalAlignment;

- (void)setVerticalAlignment:(VerticalAlignment)verticalAlignment;

@end