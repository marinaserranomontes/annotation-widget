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
    
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:_lineWidth];
    [_paths addObject:path];
}

- (void)clearCanvas:(NSString*)connectionId {
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
    [self startTouch:p];
}

- (void)startTouch:(CGPoint)point {
    [[self activePath] moveToPoint:point];
    _lastPoint = point;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self moveTouch:p incoming:false];
}

- (void)moveTouch:(CGPoint)point incoming:(Boolean) incoming {
    [[self activePath] addLineToPoint:point];
    [self setNeedsDisplay];
    
    if (!incoming) {
        NSLog(@"%f, %f", _lastPoint.x, _lastPoint.y);
        NSLog(@"%f, %f", point.x, point.y);
        
        // INFO: This should only be an issue for publishers, but check subscribers too just in case
        if (_canvasId == nil) {
            if (_publisher != nil) {
                _canvasId = _publisher.stream.connection.connectionId;
                _videoDimensions = _publisher.stream.videoDimensions;
            } else if (_subscriber != nil) {
                _canvasId = _subscriber.stream.connection.connectionId;
                _videoDimensions = _subscriber.stream.videoDimensions;
            }
        }
        
        // Send the signal
        NSDictionary* jsonObject = @{
                                         @"id" : _canvasId == nil ? @"" : _canvasId, // FIXME: Should never be nil here
                                         @"fromId" : _mycid,
                                         @"fromX" : [NSNumber numberWithFloat:_lastPoint.x],
                                         @"fromY" : [NSNumber numberWithFloat:_lastPoint.y],
                                         @"toX" : [NSNumber numberWithFloat:point.x],
                                         @"toY" : [NSNumber numberWithFloat:point.y],
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
    }
    
    _lastPoint = point;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)didReceiveSignal:(NSString*)signal withType:(NSString*)type fromConnection:(OTConnection*)connection {
    NSLog(@"Canvas signal received");
    if (![connection.connectionId isEqualToString:_mycid]) {
        if ([type isEqualToString:@"otAnnotation_pen"]) {
            NSError *jsonError;
            NSData *objectData = [signal dataUsingEncoding:NSUTF8StringEncoding];
            NSArray* jsonArray = [NSJSONSerialization JSONObjectWithData:objectData
                                            options:NSJSONReadingMutableContainers
                                              error:&jsonError];
            
            for (NSDictionary* json in jsonArray) {
                NSString* canvasId = json[@"id"];
                
                if (_canvasId == nil) {
                    if (_publisher != nil) {
                        _canvasId = _publisher.stream.connection.connectionId;
                        _videoDimensions = _publisher.stream.videoDimensions;
                    } else if (_subscriber != nil) {
                        _canvasId = _subscriber.stream.connection.connectionId;
                        _videoDimensions = _subscriber.stream.videoDimensions;
                    }
                }
                
                if ([_canvasId isEqualToString:canvasId]) {
                    Boolean signalMirrored = [json[@"mirrored"] boolValue];
                    
                    [self setColor: [UIColor colorFromHexString: json[@"color"]]];
                    [self setLineWidth: [(NSNumber *)json[@"lineWidth"] floatValue]];
                    
    //                OTVideoRender* renderer;
    //                
    //                if (_publisher != nil) {
    //                    renderer = _publisher.videoRender;
    //                } else if (_subscriber != nil) {
    //                    renderer = _subscriber.videoRender;
    //                }
                    
    //                NSLog(@"CanvasOffset CanvasSize: %f, %f", self.frame.size.width, self.frame.size.height);
                    
    //                if (renderer != nil) {
                        // Handle scale
                        float scale = 1;
                        
                        CGSize canvas = CGSizeMake(self.frame.size.width, self.frame.size.height);
                        CGSize video = CGSizeMake(self.frame.size.width, self.frame.size.height);
                        CGSize iCanvas = CGSizeMake([(NSNumber*)json[@"canvasWidth"] floatValue], [(NSNumber*)json[@"canvasHeight"] floatValue]);
                        CGSize iVideo = CGSizeMake([(NSNumber*)json[@"videoWidth"] floatValue], [(NSNumber*)json[@"videoHeight"] floatValue]);
                        
                        NSLog(@"CanvasOffset Sizes [Canvas: %f, %f Video: %f, %f iCanvas: %f, %f iVideo: %f, %f]",
                                canvas.width, canvas.height,
                                video.width, video.height,
                                iCanvas.width, iCanvas.height,
                                iVideo.width, iVideo.height);
                    
                        float canvasRatio = canvas.width / canvas.height;
                        float videoRatio = video.width / video.height;
                        float iCanvasRatio = iCanvas.width / iCanvas.height;
                        float iVideoRatio = iVideo.width / iVideo.height;
                        
                        /**
                         * This assumes that if the width is the greater value, video frames
                         * can be scaled so that they have equal widths, which can be used to
                         * find the offset in the y axis. Therefore, the offset on the x axis
                         * will be 0. If the height is the greater value, the offset on the y
                         * axis will be 0.
                         */
                        if (canvasRatio < 0) {
                            scale = canvas.width / iCanvas.width;
                        } else {
                            scale = canvas.height / iCanvas.height;
                        }
                        
                        NSLog(@"CanvasOffset Scale: %f", scale);
                        
                        // FIXME If possible, the scale should also scale the line width (use a min width value?)
                        
                        float centerX = canvas.width / 2;
                        float centerY = canvas.height / 2;
                        
                        float iCenterX = iCanvas.width / 2;
                        float iCenterY = iCanvas.height / 2;
                        
                        float fromX = centerX - (scale * (iCenterX - [(NSNumber*) json[@"fromX"] floatValue]));
                        float fromY = centerY - (scale * (iCenterY - [(NSNumber*) json[@"fromY"] floatValue]));
                        
                        float toX = centerX - (scale * (iCenterX - [(NSNumber*) json[@"toX"] floatValue]));
                        float toY = centerY - (scale * (iCenterY - [(NSNumber*) json[@"toY"] floatValue]));
                        
                        NSLog(@"CanvasOffset From: %f, %f", fromX, fromY);
                        NSLog(@"CanvasOffset To: %f, %f", toX, toY);
                        
                        if (signalMirrored) {
                            NSLog(@"CanvasOffset Signal is mirrored");
                            fromX = self.frame.size.width - fromX;
                            toX = self.frame.size.width - toX;
                        }
                        
                        if (_mirrored) {
                            NSLog(@"CanvasOffset Feed is mirrored");
                            // Revert (Double negative)
                            fromX = self.frame.size.width - fromX;
                            toX = self.frame.size.width - toX;
                        }
                    
                        [self startTouch: CGPointMake(fromX, fromY)];
                        [self moveTouch: CGPointMake(toX, toY) incoming:true];
                    }
    //            }
            }
        } else if ([type isEqualToString:@"otAnnotation_clear"]) {
            [self clearCanvas:connection.connectionId];
        }
    }
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
            [self clearCanvas: _mycid];
        } else if ([item.identifier isEqualToString:@"ot_capture"]) {
            
        }


    }
}

@end
