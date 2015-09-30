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

IB_DESIGNABLE

@protocol OTScreenCaptureDelegate <NSObject>

-(void)didCaptureImage:(UIImage*)image forConnection:(NSString*)connectionId;

@end

@protocol OTAnnotationToolbarDelegate <NSObject>

// TODO: Add button click callbacks

@end

@interface OTAnnotationToolbar : UIView

@property (nonatomic) IBInspectable UIColor *barTintColor;
@property (nonatomic) IBInspectable UIColor *tintColor;
@property (nonatomic) IBOutlet UIToolbar *mainToolbar;
@property (nonatomic) id<OTScreenCaptureDelegate> screenCaptureDelegate;
@property (nonatomic) id<OTAnnotationToolbarDelegate> delegate;

-(void)attachAnnotationView:(OTAnnotationView*)annotationView;
-(void)attachSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string;
-(void)didCaptureImage:(UIImage*)image forConnection:(NSString*)connectionId;

@end
