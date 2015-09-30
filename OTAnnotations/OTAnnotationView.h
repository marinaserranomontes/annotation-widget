//
//  OTAnnotationView.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>
#import "OTAnnotationToolbar.h"

@class OTAnnotationToolbar;

@interface OTAnnotationView : UIView {
    @package
    OTAnnotationToolbar* toolbar;
}

- (id)initWithSubscriber:(OTSubscriber *)subscriber;
- (id)initWithPublisher:(OTPublisher *)publisher;

- (void)didTapAnnotationItem:(UIBarButtonItem*)item;

- (void)setColor:(UIColor *)color;
- (void)setLineWidth:(CGFloat)lineWidth;

- (UIImage*)captureScreenshot;

- (void)didReceiveSignal:(NSString*)signal withType:(NSString*)type fromConnection:(OTConnection*)connection;

@end
