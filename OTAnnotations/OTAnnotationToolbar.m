//
//  OTAnnotationToolbar.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import "OTAnnotationToolbar.h"

@implementation OTAnnotationToolbar {
    UIView* view;
}

- (instancetype)initWithFrame:(CGRect) frame {
    if (self = [super initWithFrame:frame]) {
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
    view = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"OTAnnotationToolbar" owner:self options:nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect {
    [view addSubview:_mainToolbar];
    
    view.backgroundColor = self.backgroundColor;
    _mainToolbar.barTintColor = self.backgroundColor;
    _mainToolbar.tintColor = self.tintColor;
}

@end
