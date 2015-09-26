//
//  OTAnnotationView.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>

@interface OTAnnotationView : UIView {

}

- (id)initWithSubscriber:(OTSubscriber *)subscriber;
- (id)initWithPublisher:(OTPublisher *)publisher;

- (void)didTapAnnotationItem:(UIBarButtonItem*)item;

- (void)setColor:(UIColor *)color;
- (void)setLineWidth:(CGFloat *)lineWidth;

@end
