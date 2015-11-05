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

@class OTColorButtonItem;

@protocol OTColorButtonItemDelegate <NSObject>

- (void)shouldShowColorPicker:(BOOL)showPicker;
- (void)didChooseColor:(UIColor*)color;
- (void)didSelectItem:(OTColorButtonItem*)item;

@end

@interface OTColorButtonItem : UIBarButtonItem

@property (nonatomic) IBInspectable NSString *identifier;
@property (nonatomic) IBInspectable UIColor *color;
@property (nonatomic) IBInspectable BOOL showsPicker;

@property (nonatomic, weak) id<OTColorButtonItemDelegate> delegate;

@end
