//
//  OTAnnotationToolbar.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTAnnotationView.h"

@class OTAnnotationView;

#ifndef IBInspectable
    #define IBInspectable
#endif

@protocol OTScreenCaptureDelegate <NSObject>

-(void)didCaptureImage:(UIImage*)image forConnection:(NSString*)connectionId;

@end

@protocol OTAnnotationToolbarDelegate <NSObject>

-(void)didTapItem:(UIBarButtonItem*)item;

@end

IB_DESIGNABLE @interface OTAnnotationToolbar : UIView

@property (nonatomic) IBInspectable UIColor *barTintColor;
@property (nonatomic) IBInspectable UIColor *tintColor;
@property (nonatomic) IBOutlet UIToolbar *mainToolbar;
@property (nonatomic) NSArray<UIColor*> *colors;
@property (nonatomic) id<OTScreenCaptureDelegate> screenCaptureDelegate;
@property (nonatomic) id<OTAnnotationToolbarDelegate> delegate;

/**
 * Links an OTAnnotationView instance to the toolbar.
 *
 * @param annotationView The OpenTok annotation canvas.
 */
-(void)attachAnnotationView:(OTAnnotationView*)annotationView;

/**
 * Attaches an OpenTok signal to be used to handle incoming annotations.
 *
 * @param type The type of OpenTok signal.
 * @param connection The OpenTok connection the signal was received on.
 * @param string The signal string.
 */
-(void)attachSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string;

/**
 * Called when a screen capture has been taken on an OpenTok annotation canvas.
 *
 * @param image The screenshot image.
 * @param connectionId The OpenTok connection ID associated with the screen capture.
 */
-(void)didCaptureImage:(UIImage*)image forConnection:(NSString*)connectionId;

/**
 * Adds a new color to the current annotation color palette.
 *
 * @param color The color to add to the existing palette.
 */
-(void)addColor:(UIColor*)color;

@end
