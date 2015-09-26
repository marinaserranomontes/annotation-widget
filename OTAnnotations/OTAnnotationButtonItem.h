//
//  OTAnnotationButtonItem.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 9/22/15.
//  Copyright © 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef IBInspectable
    #define IBInspectable
#endif

@interface OTAnnotationButtonItem : UIBarButtonItem

@property (nonatomic) IBInspectable NSString *identifier;
@property (nonatomic) IBOutlet UIToolbar *subToolbar;

@end
