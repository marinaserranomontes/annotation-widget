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
#import "UIColor+HexString.h"

@implementation OTAnnotationView {
    NSMutableArray *_paths;
    CGPoint _current;
    CGPoint _lastPoint;
    
    UIColor *_color;
    UIColor *_incomingColor;
    
    CGFloat _lineWidth;
    CGFloat _incomingLineWidth;
    
    OTSubscriber *_subscriber;
    OTPublisher *_publisher;
    
    NSString* _sessionId;
    NSString* _mycid;
    NSString* _canvasId;
    
    CGSize _videoDimensions;
    
    Boolean _mirrored;
    
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
        _sessionId = subscriber.session.sessionId;
        _mycid = subscriber.session.connection.connectionId;
        _canvasId = subscriber.stream.connection.connectionId;
        _videoDimensions = subscriber.stream.videoDimensions;
        [self setupView];
    }
    return self;
}

- (id)initWithPublisher:(OTPublisher *)publisher {
    if (self = [super initWithFrame:publisher.view.frame]) {
        _publisher = publisher;
        _sessionId = publisher.session.sessionId;
        _mycid = publisher.session.connection.connectionId;
        // FIXME: Publisher stream is nil when initialized
        _canvasId = publisher.stream.connection.connectionId;
        _videoDimensions = publisher.stream.videoDimensions;
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
    
    _lineWidth = 2.f;
    
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:_lineWidth];
    [_paths addObject:path];
    
    // Ensure the canvas is always the top layer
    [self.superview bringSubviewToFront:self];
    self.userInteractionEnabled = true;
}

-(UIBezierPath*)activePath {
    return [_paths lastObject];
}

- (void)drawRect:(CGRect)rect {
    for (OTPath* path in _paths) {
        [path.color setStroke];
        [path stroke];
    }
}

- (void)setColor:(UIColor *)color {
    _color = color;
    
    OTPath* path = [OTPath bezierPath];
    [path setColor:color];
    [path setLineWidth:_lineWidth];
    [_paths addObject:path];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
}

- (void)clearCanvas {
    // TODO: Only clear annotations drawn by the specified user (add param for ID to method signature)
    [_paths removeAllObjects];
    [self setNeedsDisplay];
    
    // Initialize a new path so that we can still draw
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:_lineWidth];
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
                                    @"id" : _canvasId == nil ? @"" : _canvasId, // FIXME: Should never be nil here
                                    @"fromId" : _mycid,
                                    @"fromX" : [NSNumber numberWithFloat:_lastPoint.x],
                                    @"fromY" : [NSNumber numberWithFloat:_lastPoint.y],
                                    @"toX" : [NSNumber numberWithFloat:p.x],
                                    @"toY" : [NSNumber numberWithFloat:p.y],
                                    @"color" : [UIColor hexStringFromColor:_color],
                                    @"lineWidth" : [NSNumber numberWithFloat:_lineWidth],
                                    @"videoWidth" : [NSNumber numberWithFloat:_videoDimensions.width],
                                    @"videoHeight" : [NSNumber numberWithFloat:_videoDimensions.height],
                                    @"canvasWidth" : [NSNumber numberWithFloat:self.frame.size.width],
                                    @"canvasHeight" : [NSNumber numberWithFloat:self.frame.size.height],
                                    @"mirrored" : _mirrored ? @true : @false
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
    // INFO: The color setter is handled in the toolbar, not here
    
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
