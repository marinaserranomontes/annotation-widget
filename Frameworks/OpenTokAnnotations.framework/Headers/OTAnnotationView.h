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

/**
 * Sets the active annotation color.
 *
 * @param color The color to apply to newly drawn annotations.
 */
- (void)setColor:(UIColor *)color;

/**
 * Sets the active annotation line width (stroke size).
 *
 * @param lineWidth The line width, in pixels, to apply to newly drawn annotations.
 */
- (void)setLineWidth:(CGFloat)lineWidth;

/**
 * Captures a screenshot of the attached video feed along with its annotations.
 *
 * @return The screenshot image.
 */
- (UIImage*)captureScreenshot;

/**
 * Called when a toolbar menu item has been tapped by the user.
 *
 * @param item The bar button item that was tapped by the user.
 * @see OTAnnotationButtonItem
 * @see OTColorButtonItem
 */
- (void)didTapAnnotationItem:(UIBarButtonItem*)item;

/**
 * Called when an OpenTok annotation signal is passed from an active OpenTok session.
 *
 * @param signal The OpenTok signal string.
 * @param type The type of OpenTok signal.
 * @param connection The OpenTok connection the signal was received on.
 */
- (void)didReceiveSignal:(NSString*)signal withType:(NSString*)type fromConnection:(OTConnection*)connection;

@end
