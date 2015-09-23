//
//  OTColorButtonItem.h
//  Annotations Demo
//
//  Created by Trevor Boyer on 9/22/15.
//  Copyright © 2015 TokBox Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef IBInspectable
    #define IBInspectable
#endif

IB_DESIGNABLE

@interface OTColorButtonItem : UIBarButtonItem

@property (nonatomic) IBInspectable NSString *identifier;
@property (nonatomic) IBInspectable UIColor *color;

@end
