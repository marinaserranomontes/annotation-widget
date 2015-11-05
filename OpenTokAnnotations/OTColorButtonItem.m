//
//  OTColorButtonItem.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 9/22/15.
//  Copyright © 2015 TokBox Inc. All rights reserved.
//

#import "OTColorButtonItem.h"

@implementation OTColorButtonItem

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

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
    
    _showsPicker = false;
    [self updateView];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    
    [self updateView];
}

- (void)updateView {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 30, 30);
    button.layer.backgroundColor = _color.CGColor;
    button.layer.cornerRadius = 15;
    
    [button addTarget:self action:@selector(handleClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self setCustomView:button];
}

- (void)handleClick {
    NSLog(@"Clicked color choice");
    
    if (_delegate) {
        [_delegate didSelectItem:self];
        
        if (_showsPicker) {
           [_delegate shouldShowColorPicker:true];
        } else {
            [_delegate didChooseColor:_color];
        }
    } else {
        // Handle the action normally
        [self.target performSelector:self.action withObject:self];
    }
}

@end
