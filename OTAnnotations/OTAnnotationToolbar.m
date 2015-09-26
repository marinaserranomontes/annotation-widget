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

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation OTAnnotationToolbar {
    UIView* _view;
    UIToolbar* _subToolbar;
    NSMutableArray* _annotationViews;
    
    UIColor* _backgroundColor;
    
    OTColorButtonItem* _colorPickerItem;
    NSMutableArray* _colors;
    
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
    super.backgroundColor = [UIColor yellowColor];
    
    _annotationViews = [[NSMutableArray alloc] init];
    _colors = [[NSMutableArray alloc] init];
    [self initDefaultColors];
}

- (void)initDefaultColors {
    [_colors addObject:UIColorFromRGB(0x000000)];  // Black
    [_colors addObject:UIColorFromRGB(0x0000FF)];  // Blue
    [_colors addObject:UIColorFromRGB(0xFF0000)];  // Red
    [_colors addObject:UIColorFromRGB(0x00FF00)];  // Green
    [_colors addObject:UIColorFromRGB(0xFF8C00)];  // Orange
    [_colors addObject:UIColorFromRGB(0xFFD700)];  // Yellow
    [_colors addObject:UIColorFromRGB(0x4B0082)];  // Purple
    [_colors addObject:UIColorFromRGB(0x800000)];  // Brown
}

- (void)awakeFromNib {
    // FIXME: Find a way to override the height from IB and allow it to get set here, dynamically (needs to update when a sub toolbar is added/removed)
    CGRect mainframe = _bounds;
    mainframe.size.height = 2 * _bounds.size.height;
    self.frame = mainframe;

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
    
    _view.backgroundColor = [UIColor redColor];
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
    frame.origin.y = _bounds.size.height;
    toolbar.frame = frame;
    
//    scrollView.contentSize = toolbar.frame.size;
    
    _subToolbar = toolbar;
    
//        CGRect mainframe = _bounds;
//        mainframe.size.height = 2 * _bounds.size.height;
//        _view.frame = mainframe;
    
    NSMutableArray* items = [[NSMutableArray alloc] init];
    
    // TODO: Iterate over possible line widths and build items
    
    toolbar.items = items;
    
    //    [scrollView addSubview: toolbar];
    [self addSubview: toolbar];
    [self bringSubviewToFront: toolbar];
}

-(void)attachAnnotationView:(OTAnnotationView*)annotationView {
    [_annotationViews addObject: annotationView];
}

@end
