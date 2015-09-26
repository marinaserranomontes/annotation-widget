//
//  OTAnnotationView.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import "OTAnnotationView.h"
#import "OTAnnotationButtonItem.h"
#import "OTColorButtonItem.h"
#import "OTPath.h"

@implementation OTAnnotationView {
    NSMutableArray *_paths;
    CGPoint _current;
    CGPoint _lastPoint;
    
    UIColor *_color;
    UIColor *_incomingColor;
    
    OTSubscriber *_subscriber;
    OTPublisher *_publisher;
    
    /* TODO: Enum or similar
     Pen("otAnnotation_pen"),
     Clear("otAnnotation_clear"),
     Shape("otAnnotation_shape"),
     Line("otAnnotation_line"),
     Text("otAnnotation_text");
     */
}

- (id)initWithSubscriber:(OTSubscriber *)subscriber {
    if (self = [super initWithFrame:subscriber.view.frame]) {
        _subscriber = subscriber;
        [self setupView];
    }
    return self;
}

- (id)initWithPublisher:(OTPublisher *)publisher {
    if (self = [super initWithFrame:publisher.view.frame]) {
        _publisher = publisher;
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    [self setMultipleTouchEnabled:NO];
    [self setBackgroundColor:[UIColor clearColor]];
    
    _paths = [[NSMutableArray alloc] init];
    
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:2.0];
    [_paths addObject:path];
}

-(UIBezierPath*)activePath {
    return [_paths lastObject];
}

- (void)drawRect:(CGRect)rect {
    for (OTPath* path in _paths) {
        // TODO: Path object - OTPath? - should include color
        [path.color setStroke];
        [path stroke];
    }
}

- (void)setColor:(UIColor *)color {
    _color = color;
    
    // TODO: Create a new OTPath object
    OTPath* path = [OTPath bezierPath];
    [path setColor:color];
    [path setLineWidth:2.0];
    [_paths addObject:path];
}

- (void)setLineWidth:(CGFloat *)lineWidth {

}

- (void)clearCanvas {
    NSLog(@"Clearing canvas");
    // TODO: Only clear annotations drawn by the specified user (add param for ID to method signature)
    [_paths removeAllObjects];
    [self setNeedsDisplay];
    
    // Initialize a new path so that we can still draw
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:2.0];
    [_paths addObject:path];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [[self activePath] moveToPoint:p];
    _lastPoint = p;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [[self activePath] addLineToPoint:p];
    [self setNeedsDisplay];
    
    NSLog(@"%f, %f", _lastPoint.x, _lastPoint.y);
    NSLog(@"%f, %f", p.x, p.y);

    // Send the signal
    NSDictionary* jsonObject = @{
                                    @"id" : @"ios-test", //session.sessionId & session.connection.connectionId
                                    @"fromX" : [NSNumber numberWithFloat:_lastPoint.x],
                                    @"fromY" : [NSNumber numberWithFloat:_lastPoint.y],
                                    @"toX" : [NSNumber numberWithFloat:p.x],
                                    @"toY" : [NSNumber numberWithFloat:p.y],
                                    @"color" : @"#ff0000", // TODO: Dynamic color
                                    @"lineWidth" : [NSNumber numberWithFloat:6.f], // TODO: Dynamic line width
                                };

    NSArray* jsonArray = [NSArray arrayWithObjects:jsonObject, nil];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                       options:0
                                                         error:&error];
    
    NSString* update = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self sendUpdate:update forType:@"otAnnotation_pen"];
    
    _lastPoint = p;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)sendUpdate:(NSString *)update forType:(NSString *)type {
    NSError *error;
    
    NSLog(@"%@", update);
    
    if (_publisher != nil) {
        [_publisher.session signalWithType:type string:update connection:_publisher.session.connection error:&error];
    } else if (_subscriber != nil) {
        [_subscriber.session signalWithType:type string:update connection:_publisher.session.connection error:&error];
    } else {
        // TODO: Throw an error - either a publisher or subscriber should have been supplied
        NSLog(@"Please provide either a subscriber or publisher.");
    }
}

- (void)didTapAnnotationItem:(UIBarButtonItem *)sender {
    NSLog(@"Canvas delegate click");
    
    // The color setter is handled in the toolbar, directly
//    if ([sender isKindOfClass: OTColorButtonItem.self]) {
//        // Update the annotation color
//        OTColorButtonItem* item = (OTColorButtonItem*) sender;
//        [self setColor:item.color];
//    } else
    if ([sender isKindOfClass: OTAnnotationButtonItem.self]) {
        OTAnnotationButtonItem* item = (OTAnnotationButtonItem*) sender;
        // TODO: Handle the click
        
        if ([item.identifier isEqualToString:@"ot_pen"]) {
            
        } else if ([item.identifier isEqualToString:@"ot_line"]) {
            
        } else if ([item.identifier isEqualToString:@"ot_shapes"]) {
            
        } else if ([item.identifier isEqualToString:@"ot_clear"]) {
            [self clearCanvas];
        } else if ([item.identifier isEqualToString:@"ot_capture"]) {
            
        }


    }
}

@end
