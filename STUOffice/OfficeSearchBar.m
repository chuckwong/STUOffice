//
//  OfficeSearchBar.m
//  STUOffice
//
//  Created by JunhaoWang on 7/28/15.
//  Copyright (c) 2015 JunhaoWang. All rights reserved.
//

#import "OfficeSearchBar.h"

@implementation OfficeSearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setImage:[UIImage imageNamed:@"searchbar-icon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"searchbar-clear"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"searchbar-clear"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
        
        self.searchBarStyle = UISearchBarStyleMinimal;
        self.tintColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        
        // text
        [[UITextField appearanceWhenContainedIn:[self class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:14.0]}];
        
        // placeholder
        self.placeholder = @"搜索";
        NSDictionary *placeholderAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.9 alpha:1.0], NSFontAttributeName:[UIFont systemFontOfSize:14.0]};
        
        [[UITextField appearanceWhenContainedIn:[self class], nil] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:self.placeholder attributes:placeholderAttributes]];
        
    }
    return self;
}

@end
