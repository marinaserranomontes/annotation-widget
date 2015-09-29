//
//  OTAnnotationToolbar.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTAnnotationView.h"

#ifndef IBInspectable
    #define IBInspectable
#endif

IB_DESIGNABLE

@interface OTAnnotationToolbar : UIView

@property (nonatomic) IBInspectable UIColor *barTintColor;
@property (nonatomic) IBInspectable UIColor *tintColor;
@property (nonatomic) IBOutlet UIToolbar *mainToolbar;

-(void)attachAnnotationView:(OTAnnotationView*)annotationView;
-(void)attachSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string;

@end
