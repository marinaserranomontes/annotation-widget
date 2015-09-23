//
//  OTAnnotationToolbar.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef IBInspectable
    #define IBInspectable
#endif

IB_DESIGNABLE

@interface OTAnnotationToolbar : UIView

//@property (nonatomic) IBInspectable UIColor *backgroundColor;
//@property (nonatomic) IBInspectable UIColor *tintColor;
@property (nonatomic) IBOutlet UIToolbar *mainToolbar;

@end
