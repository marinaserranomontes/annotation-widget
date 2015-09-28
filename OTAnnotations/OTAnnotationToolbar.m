//
//  OTAnnotationToolbar.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import "OTAnnotationToolbar.h"
#import "OTAnnotationButtonItem.h"
#import "OTColorButtonItem.h"
#import "UIColor+HexString.h"
#import "UIBezierPath+Image.h"

@implementation OTAnnotationToolbar {
    UIView* _view;
    UIToolbar* _subToolbar;
    NSMutableArray* _annotationViews;
    
    UIColor* _backgroundColor;
    
    OTColorButtonItem* _colorPickerItem;
    NSMutableArray* _colors;
    
    UIColor* _selectedColor;
    CGFloat _activeLineWidth;
    
    NSMutableArray* _lineWidths;
    
    CGRect _bounds;
}

- (instancetype)initWithFrame:(CGRect) frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*) coder {
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    // INFO: This is required for the custom toolbar to be displayed in IB - _view = _mainToolbar
    _view = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"OTAnnotationToolbar" owner:self options:nil] firstObject];
    
    _bounds = self.bounds;
    
    self.opaque = false;
    super.backgroundColor = [UIColor clearColor];
    
    _annotationViews = [[NSMutableArray alloc] init];
    _colors = [[NSMutableArray alloc] init];
    _lineWidths = [[NSMutableArray alloc] init];
    [self initDefaultColors];
    [self initDefaultLineWidths];
}

- (void)initDefaultColors {
    [_colors addObject: [UIColor colorFromHex:0x000000]];  // Black
    [_colors addObject: [UIColor colorFromHex:0x0000FF]];  // Blue
    [_colors addObject: [UIColor colorFromHex:0xFF0000]];  // Red
    [_colors addObject: [UIColor colorFromHex:0x00FF00]];  // Green
    [_colors addObject: [UIColor colorFromHex:0xFF8C00]];  // Orange
    [_colors addObject: [UIColor colorFromHex:0xFFD700]];  // Yellow
    [_colors addObject: [UIColor colorFromHex:0x4B0082]];  // Purple
    [_colors addObject: [UIColor colorFromHex:0x800000]];  // Brown
}

- (void)initDefaultLineWidths {
    [_lineWidths addObject: [NSNumber numberWithFloat: 2.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat: 4.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat: 6.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat: 8.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat:10.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat:12.f]];
    [_lineWidths addObject: [NSNumber numberWithFloat:14.f]];
}

- (void)awakeFromNib {
    // FIXME: Find a way to override the height from IB and allow it to get set here, dynamically (needs to update when a sub toolbar is added/removed)
    CGRect mainframe = _bounds;
    mainframe.size.height = 2 * _bounds.size.height;
    self.frame = mainframe;
    
    _selectedColor = [_colors objectAtIndex:0];

    for (UIBarButtonItem* item in _mainToolbar.items) {
        item.target = self;
        item.action = @selector(handleTap:);
        
        if ([item isKindOfClass: OTColorButtonItem.self]) {
            OTColorButtonItem* colorItem = (OTColorButtonItem*) item;
            [colorItem setColor:[_colors objectAtIndex:0]];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    // FIXME: Scrollview isn't working
//    UIScrollView* mainScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
//    [mainScrollView setScrollEnabled:YES];
//    mainScrollView.contentSize = _mainToolbar.frame.size;
//    
//    [_view addSubview:mainScrollView];
    [self addSubview:_mainToolbar];
    [_mainToolbar sizeToFit];
    
    _mainToolbar.barTintColor = _barTintColor;
    _mainToolbar.tintColor = _tintColor;
}

// INFO: This is a workaround to ensure that the background view is drawn with UIColor.clearColor
- (void) setBackgroundColor:(UIColor *)newColor {
    if (newColor != _backgroundColor) {
        _backgroundColor = newColor;
    }
}

- (void)handleTap:(UIBarButtonItem*)sender {
    NSLog(@"Did tap item..");
    
    [self hideToolbar];
    
    // Delegate callback

    for (OTAnnotationView* annotationView in _annotationViews) {
        [annotationView didTapAnnotationItem: sender];
    }
    
    if ([sender isKindOfClass: OTColorButtonItem.self]) {
        OTColorButtonItem* item = (OTColorButtonItem*) sender;
        if (item.showsPicker) {
            _colorPickerItem = item;
            // Show color sub menu
            [self showColorToolbar];
        } else {
            for (OTAnnotationView* annotationView in _annotationViews) {
                [annotationView setColor: item.color];
            }
            [_colorPickerItem setColor:item.color];
            [self hideToolbar];
        }
    } else if ([sender isKindOfClass: OTAnnotationButtonItem.self]) {
        OTAnnotationButtonItem* item = (OTAnnotationButtonItem*) sender;
        
        if (item.subToolbar != nil) {
            // Add click listener to add sub toolbar to view
            [self showToolbar: item.subToolbar];
        } else if ([item.identifier isEqualToString:@"ot_line_width"]) {
            [self showLineWidthToolbar];
        } else if ([item.identifier rangeOfString:@"ot_line_width_"].location != NSNotFound) {
            NSString* str = [[item.identifier
                              stringByReplacingOccurrencesOfString:@"ot_line_width_" withString:@""]
                              stringByReplacingOccurrencesOfString:@"_" withString:@"."];
            
            _activeLineWidth = (CGFloat)[str floatValue];
            
            for (OTAnnotationView* annotationView in _annotationViews) {
                [annotationView setLineWidth:_activeLineWidth];
            }
        }
    }
}

- (void)hideToolbar {
    if ([_subToolbar superview] != nil) {
        [_subToolbar removeFromSuperview];
        
//        _view.frame = _bounds;
//        self.frame = _bounds;
    }
}

- (void)showToolbar:(UIToolbar*) toolbar {
    // Retains a copy so that it can be removed from the view later
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = toolbar.frame;
    frame.origin.y = _bounds.size.height / 2;
    toolbar.frame = frame;
    
    // Add action handlers FIXME: The button items aren't currently clickable
    for (UIBarButtonItem* item in toolbar.items) {
        item.target = self;
        item.action = @selector(handleTap:);
    }
    
//    CGRect mainframe = _bounds;
//    mainframe.size.height = 2 * _bounds.size.height;
//    _view.frame = mainframe;
//    self.frame = mainframe;
    
    [self addSubview:toolbar];
//    [_view bringSubviewToFront: toolbar];
}

- (void)showColorToolbar {
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:_view.frame];
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
//    UIScrollView* scrollView = [[UIScrollView alloc] init];
//    scrollView.frame = toolbar.frame;
//    scrollView.bounds = toolbar.bounds;
//    scrollView.autoresizingMask = toolbar.autoresizingMask;
//    scrollView.showsVerticalScrollIndicator = false;
//    scrollView.showsHorizontalScrollIndicator = false;
//    scrollView.userInteractionEnabled = YES;
//    
//    toolbar.autoresizingMask = UIViewAutoresizingNone;
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = toolbar.frame;
    frame.origin.y = _bounds.size.height / 2;
    toolbar.frame = frame;
    
//    scrollView.contentSize = toolbar.frame.size;
    
//        CGRect mainframe = _view.frame;
//        mainframe.size.height = 2 * _bounds.size.height;
//        _view.frame = mainframe;
    
    NSMutableArray* items = [[NSMutableArray alloc] init];
    
    for (UIColor* color in _colors) {
        OTColorButtonItem* colorItem = [[OTColorButtonItem alloc] init];
        [colorItem setColor:color];
        [items addObject:colorItem];
        
        colorItem.target = self;
        colorItem.action = @selector(handleTap:);
    }
    
    toolbar.items = items;
    
//    [scrollView addSubview: toolbar];
    [self addSubview: toolbar];
    [self bringSubviewToFront: toolbar];
}

- (void)showLineWidthToolbar {
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:_view.frame];
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
//    UIScrollView* scrollView = [[UIScrollView alloc] init];
//    scrollView.frame = toolbar.frame;
//    scrollView.bounds = toolbar.bounds;
//    scrollView.autoresizingMask = toolbar.autoresizingMask;
//    scrollView.showsVerticalScrollIndicator = false;
//    scrollView.showsHorizontalScrollIndicator = false;
//    scrollView.userInteractionEnabled = YES;
    
    toolbar.autoresizingMask = UIViewAutoresizingNone;
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = toolbar.frame;
    frame.origin.y = _bounds.size.height / 2;
    toolbar.frame = frame;
    
//    scrollView.contentSize = toolbar.frame.size;
    
//        CGRect mainframe = _bounds;
//        mainframe.size.height = 2 * _bounds.size.height;
//        _view.frame = mainframe;
    
    NSMutableArray* items = [[NSMutableArray alloc] init];
    
    for (NSNumber* number in _lineWidths) {
        CGFloat lineWidth = number.floatValue;
        
        OTAnnotationButtonItem* item = [[OTAnnotationButtonItem alloc] init];
        
        // Creates a string identifier for the line width (e.g., ot_line_width_14_5 for 14.5f)
        NSString* str = [NSString stringWithFormat:@"%.01f", lineWidth];
        NSString* lwStr = [str stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        item.identifier = [NSString stringWithFormat: @"ot_line_width_%@", lwStr];
        
        UIBezierPath* icon = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 20, lineWidth)];
        item.image = [icon strokeImageWithColor:self.tintColor]; // FIXME: Fill instead of stroke?
        [items addObject:item];
        
        item.target = self;
        item.action = @selector(handleTap:);
    }
    
    toolbar.items = items;
    
//    [scrollView addSubview: toolbar];
    [self addSubview: toolbar];
    [self bringSubviewToFront: toolbar];
}

-(void)attachAnnotationView:(OTAnnotationView*)annotationView {
    [_annotationViews addObject: annotationView];
    [annotationView setColor:_selectedColor];
}

@end
