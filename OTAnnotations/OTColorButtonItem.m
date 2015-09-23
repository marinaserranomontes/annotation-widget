//
//  OTColorButtonItem.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 9/22/15.
//  Copyright © 2015 TokBox Inc. All rights reserved.
//

#import "OTColorButtonItem.h"

@implementation OTColorButtonItem

- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {
    if (self = [super initWithBarButtonSystemItem:systemItem target:target action:action]) {
        [self initialize];
    }
    return self;
}

-(instancetype)initWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    if (self = [super initWithImage:image landscapeImagePhone:landscapeImagePhone style:style target:target action:action]) {
        [self initialize];
    }
    return self;
}

-(instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    if (self = [super initWithImage:image style:style target:target action:action]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    if (self = [super initWithTitle:title style:style target:target action:action]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*) coder {
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    if (_color == nil) {
        _color = [UIColor redColor];
    }
        
    NSLog(@"Button init");
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 30, 30);
    button.layer.backgroundColor = _color.CGColor;
    button.layer.cornerRadius = 15;
    
    [self setCustomView:button];
}

@end
