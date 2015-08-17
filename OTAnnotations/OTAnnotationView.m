//
//  OTAnnotationView.m
//  Annotations Demo
//
//  Created by Trevor Boyer on 8/3/15.
//  Copyright (c) 2015 TokBox Inc. All rights reserved.
//

#import "OTAnnotationView.h"

@implementation OTAnnotationView {
    UIBezierPath *path;
    NSMutableArray *paths; // TODO: Use this array to store bezier paths
    CGPoint current;
    CGPoint lastPoint;
    
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
    path = [UIBezierPath bezierPath];
    [path setLineWidth:2.0];
}

- (void)drawRect:(CGRect)rect {
    [[UIColor blackColor] setStroke];
    [path stroke];
}

- (void)setLineWidth:(CGFloat *)lineWidth {
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [path moveToPoint:p];
    lastPoint = p;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [path addLineToPoint:p];
    [self setNeedsDisplay];
    
    NSLog(@"%f, %f", lastPoint.x, lastPoint.y);
    NSLog(@"%f, %f", p.x, p.y);

    // Send the signal
    NSDictionary* jsonObject = @{
                                    @"id" : @"ios-test", //session.sessionId & session.connection.connectionId
                                    @"fromX" : [NSNumber numberWithFloat:lastPoint.x],
                                    @"fromY" : [NSNumber numberWithFloat:lastPoint.y],
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
    
    lastPoint = p;
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

@end
