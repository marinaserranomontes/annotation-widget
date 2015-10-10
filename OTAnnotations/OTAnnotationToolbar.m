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
//    UIView* _view;
    UIToolbar* _subToolbar;
    NSMutableArray* _annotationViews;
    
    UIColor* _backgroundColor;
    
    OTColorButtonItem* _colorPickerItem;
    
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
    _mainToolbar = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"OTAnnotationToolbar" owner:self options:nil] firstObject];

    _bounds = self.bounds;
    
    self.opaque = false;
    super.backgroundColor = [UIColor clearColor];
    
    _annotationViews = [[NSMutableArray alloc] init];

    _lineWidths = [[NSMutableArray alloc] init];
    
    [self initDefaultColors];
    [self initDefaultLineWidths];
}

- (void)prepareForInterfaceBuilder {
    NSLog(@"Updating for IB");
    [self updateLayout];
}

-(void)updateLayout {
    UIScrollView* scrollView = [[UIScrollView alloc] init];
    scrollView.frame = _bounds;
    scrollView.bounds = _bounds;
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.bounces = false;
    scrollView.userInteractionEnabled = YES;
    
    _mainToolbar.barTintColor = _barTintColor;
    _mainToolbar.tintColor = _tintColor;
    
    CGFloat contentWidth = 0;
    
    for (UIBarButtonItem* item in _mainToolbar.items) {
        UIView *view = [item valueForKey:@"view"];
        CGFloat width = view ? view.frame.size.width + 10.f : (CGFloat)0.f; // Buttons have 10 pixel padding
        contentWidth += width;
    }
    
    CGRect toolbarFrame = _mainToolbar.frame;
    toolbarFrame.size.width = contentWidth < _mainToolbar.frame.size.width ? _mainToolbar.frame.size.width : contentWidth + 20.f;
    _mainToolbar.frame = toolbarFrame;
    
    scrollView.contentSize = toolbarFrame.size;
    
    [scrollView addSubview: _mainToolbar];
    [self addSubview: scrollView];
    [self bringSubviewToFront: scrollView];
}

- (void)initDefaultColors {
    _colors = [NSArray arrayWithObjects:
               [UIColor colorFromHex:0x000000],  // Black
               [UIColor colorFromHex:0x0000FF],  // Blue
               [UIColor colorFromHex:0xFF0000],  // Red
               [UIColor colorFromHex:0x00FF00],  // Green
               [UIColor colorFromHex:0xFF8C00],  // Orange
               [UIColor colorFromHex:0xFFD700],  // Yellow
               [UIColor colorFromHex:0x4B0082],  // Purple
               [UIColor colorFromHex:0x800000],  // Brown
               nil];
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
    [self updateLayout];
    
    // INFO: We can't resize the toolbar (when subtoolbars are added) when auto layout is enabled
    self.translatesAutoresizingMaskIntoConstraints = YES;
    
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

- (void)setColors:(NSArray<UIColor*> *)colors {
    _colors = colors;
    _selectedColor = [_colors objectAtIndex:0];
    
    // Update the color of the main menu item
    for (UIBarButtonItem* item in _mainToolbar.items) {
        if ([item isKindOfClass: OTColorButtonItem.self]) {
            OTColorButtonItem* colorItem = (OTColorButtonItem*) item;
            [colorItem setColor:[_colors objectAtIndex:0]];
        }
    }
}

-(void)addColor:(UIColor*)color {
    NSMutableArray* existingColors = [NSMutableArray arrayWithArray:_colors];
    [existingColors addObject:color];
    _colors = [NSArray arrayWithArray:existingColors];
}

// INFO: This is a workaround to ensure that the background view is drawn with UIColor.clearColor
- (void)setBackgroundColor:(UIColor *)newColor {
    if (newColor != _backgroundColor) {
        _backgroundColor = newColor;
    }
}

- (void)handleTap:(UIBarButtonItem*)sender {
    NSLog(@"Did tap item..");
    
    [self hideToolbar];
    
    // Delegate callback
    if (_delegate != nil) {
        [_delegate didTapItem:sender];
    }

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
        
        // Reset the original frame
//        self.frame = _bounds;
    }
    
    NSLog(@"%f, %f, %f, %f", self.frame.size.width, self.frame.size.height, self.frame.origin.x, self.frame.origin.y);
}

- (void)showToolbar:(UIToolbar*) toolbar {
    // Retains a copy so that it can be removed from the view later
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
    UIScrollView* scrollView = [[UIScrollView alloc] init];
    scrollView.frame = toolbar.frame;
    scrollView.bounds = toolbar.bounds;
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.bounces = false;
    scrollView.userInteractionEnabled = YES;
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = scrollView.frame;
    frame.origin.y = _bounds.size.height;
    scrollView.frame = frame;
    
    CGFloat contentWidth = 0;
    
    for (UIBarButtonItem* item in toolbar.items) {
        item.target = self;
        item.action = @selector(handleTap:);
        
        UIView *view = [item valueForKey:@"view"];
        CGFloat width = view ? view.frame.size.width + 10.f : (CGFloat)0.f; // Buttons have 10 pixel padding
        contentWidth += width;
    }
    
//    CGRect mainframe = _bounds;
//    mainframe.size.height = 2 * _bounds.size.height;
//    self.frame = mainframe;
    
    CGRect toolbarFrame = toolbar.frame;
    toolbarFrame.size.width = contentWidth < toolbar.frame.size.width ? toolbar.frame.size.width : contentWidth + 20.f;
    toolbar.frame = toolbarFrame;
    
    scrollView.contentSize = toolbarFrame.size;
    
    [scrollView addSubview: toolbar];
    [self addSubview: scrollView];
    [self bringSubviewToFront: scrollView];
    
    NSLog(@"%f, %f, %f, %f", _mainToolbar.frame.size.width, _mainToolbar.frame.size.height, _mainToolbar.frame.origin.x, _mainToolbar.frame.origin.y);
}

- (void)showColorToolbar {
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:_bounds];
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
    UIScrollView* scrollView = [[UIScrollView alloc] init];
    scrollView.frame = toolbar.frame;
    scrollView.bounds = toolbar.bounds;
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.bounces = false;
    scrollView.userInteractionEnabled = YES;
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = scrollView.frame;
    frame.origin.y = _bounds.size.height;
    scrollView.frame = frame;
    
//    CGRect mainframe = _bounds;
//    mainframe.size.height = 2 * _bounds.size.height;
//    self.frame = mainframe;
    
    CGFloat contentWidth = 0;
    
    NSMutableArray* items = [[NSMutableArray alloc] init];
    
    for (UIColor* color in _colors) {
        OTColorButtonItem* colorItem = [[OTColorButtonItem alloc] init];
        [colorItem setColor:color];
        [items addObject:colorItem];
        
        colorItem.target = self;
        colorItem.action = @selector(handleTap:);
        
        UIView *view = [colorItem valueForKey:@"view"];
        CGFloat width = view ? view.frame.size.width + 10.f : (CGFloat)0.f;
        contentWidth += width;
    }
    
    toolbar.items = items;
    
    CGRect toolbarFrame = toolbar.frame;
    toolbarFrame.size.width = contentWidth < toolbar.frame.size.width ? toolbar.frame.size.width : contentWidth + 20.f;
    toolbar.frame = toolbarFrame;
    
    scrollView.contentSize = toolbarFrame.size;
    
    [scrollView addSubview: toolbar];
    [self addSubview: scrollView];
    
    NSLog(@"%f, %f, %f, %f", _mainToolbar.frame.size.width, _mainToolbar.frame.size.height, _mainToolbar.frame.origin.x, _mainToolbar.frame.origin.y);
}

- (void)showLineWidthToolbar {
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:_bounds];
    _subToolbar = toolbar;
    
    toolbar.barTintColor = _barTintColor;
    toolbar.tintColor = _tintColor;
    toolbar.userInteractionEnabled = YES;
    [toolbar sizeToFit];
    
    UIScrollView* scrollView = [[UIScrollView alloc] init];
    scrollView.frame = toolbar.frame;
    scrollView.bounds = toolbar.bounds;
    scrollView.showsVerticalScrollIndicator = false;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.bounces = false;
    scrollView.userInteractionEnabled = YES;
    
    // Ensure that the sub toolbar is drawn below the main toolbar
    CGRect frame = scrollView.frame;
    frame.origin.y = _bounds.size.height;
    scrollView.frame = frame;

//    CGRect mainframe = _bounds;
//    mainframe.size.height = 2 * _bounds.size.height;
//    self.frame = mainframe;
    
    CGFloat contentWidth = 0;
    
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
        
        UIView *view = [item valueForKey:@"view"];
        CGFloat width = view ? view.frame.size.width + 10.f : (CGFloat)0.f;
        contentWidth += width;
    }
    
    toolbar.items = items;

    CGRect toolbarFrame = toolbar.frame;
    toolbarFrame.size.width = contentWidth < toolbar.frame.size.width ? toolbar.frame.size.width : contentWidth + 20.f;
    toolbar.frame = toolbarFrame;
    
    scrollView.contentSize = toolbarFrame.size;
    
    [scrollView addSubview: toolbar];
    [self addSubview: scrollView];
    [self bringSubviewToFront: scrollView];
}

-(void)attachAnnotationView:(OTAnnotationView*)annotationView {
    annotationView->toolbar = self;
    [_annotationViews addObject: annotationView];
    [annotationView setColor:_selectedColor];
}

- (void)attachSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
    if ([type rangeOfString:@"otAnnotation"].location != NSNotFound) {
        for (OTAnnotationView* annotationView in _annotationViews) {
            [annotationView didReceiveSignal:string withType:type fromConnection:connection];
        }
    }
}

-(void)didCaptureImage:(UIImage*)image forConnection:(NSString*)connectionId {
    NSLog(@"Screenshot callback");
    
    if (_screenCaptureDelegate != nil) {
        [_screenCaptureDelegate didCaptureImage:image forConnection:connectionId];
    }
}

@end
