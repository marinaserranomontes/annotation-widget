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
#import "OTShape.h"

#define kTolerance 5

@implementation OTAnnotationView {
    NSMutableArray *_paths;
    CGPoint _currentPoint;
    CGPoint _lastPoint;
    CGPoint _startPoint;
    
    UIColor *_color;
    UIColor *_incomingColor;
    
    CGFloat _lineWidth;
    CGFloat _incomingLineWidth;
    
    OTSubscriber *_subscriber;
    OTPublisher *_publisher;
    
    NSString *_sessionId;
    NSString *_mycid;
    NSString *_canvasId;
    
    CGSize _videoDimensions;
    
    Boolean _mirrored;
    
    OTAnnotationButtonItem *_selectedItem;
    
    Boolean _isDrawing;
    
    UITapGestureRecognizer *_tap;
    
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
    
    if (_isDrawing) {
        if (_selectedItem != nil && _selectedItem.points != nil) {
            [self drawPoints:_selectedItem.points withSmoothing:_selectedItem.enableSmoothing];
        }
    }
}

- (void)drawPoints:(NSArray*)points withSmoothing:(Boolean)smoothingEnabled {
    float dx = fabsf(_currentPoint.x - _lastPoint.x);
    float dy = fabsf(_currentPoint.y - _lastPoint.y);
    
    if (dx >= kTolerance || dy >= kTolerance) {
        CGPoint scale = [self scaleForPoints: points];
        
        OTPath* path = [OTPath bezierPath];
        [path setColor:_color];
        [path setLineWidth:_lineWidth];
        
        if (_selectedItem.points.count == 2) {
            // We have a line
            [path moveToPoint: _startPoint];
            [path addLineToPoint: _currentPoint];
        } else {
            float lastX = -1;
            float lastY = -1;
            for (int i = 0; i < _selectedItem.points.count; i++) {
                // Scale the points according to the difference between the start and end points
                float pointX = _startPoint.x + (scale.x * [(NSValue*)[points objectAtIndex:i] CGPointValue].x);
                float pointY = _startPoint.y + (scale.y * [(NSValue*)[points objectAtIndex:i] CGPointValue].y);
                
                if (smoothingEnabled) {
                    if (i == 0) {
                        // Do nothing
                    } else if (i == 1) {
                        [path moveToPoint: CGPointMake((pointX + lastX) / 2, (pointY + lastY) / 2)];
                    } else {
                        // FIXME: This isn't drawing properly
                        [path addQuadCurveToPoint: CGPointMake(lastX, lastY) controlPoint: CGPointMake((pointX + lastX) / 2, (pointY + lastY) / 2)];
                    }
                } else {
                    if (i == 0) {
                        [path moveToPoint: CGPointMake(pointX, pointY)];
                    } else {
                        [path addLineToPoint: CGPointMake(pointX, pointY)];
                    }
                }
                
                lastX = pointX;
                lastY = pointY;
            }
        }
        
        // Ensure that this is only drawn temporarily
        [path.color setStroke];
        [path stroke];
    }
}

- (CGPoint)scaleForPoints: (NSArray*)points {
    // mX and mY refer to the end point of the enclosing rectangle (touch up)
    float minX = FLT_MAX;
    float minY = FLT_MAX;
    float maxX = 0;
    float maxY = 0;
    
    for (int i = 0; i < _selectedItem.points.count; i++) {
        CGPoint point = [(NSValue*)[points objectAtIndex:i] CGPointValue];
        
        if (point.x < minX) {
            minX = point.x;
        } else if (point.x > maxX) {
            maxX = point.x;
        }
        
        if (point.y < minY) {
            minY = point.y;
        } else if (point.y > maxY) {
            maxY = point.y;
        }
    }
    float dx = fabsf(maxX - minX);
    float dy = fabsf(maxY - minY);
    
    float scaleX = (_currentPoint.x - _startPoint.x) / dx;
    float scaleY = (_currentPoint.y - _startPoint.y) / dy;
    
//    Log.i("AnnotationView", "Scale: " + scaleX + ", " + scaleY);
    
    return CGPointMake(scaleX, scaleY);
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

- (void)clearCanvas:(NSString*)connectionId incoming:(Boolean)incoming {
    // TODO: Only clear annotations drawn by the specified user (add param for ID to method signature)
    [_paths removeAllObjects];
    [self setNeedsDisplay];
    
    // Initialize a new path so that we can still draw
    OTPath* path = [OTPath bezierPath];
    [path setColor:_color];
    [path setLineWidth:_lineWidth];
    [_paths addObject:path];
    
    if (!incoming) {
        
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    _startPoint = point;
    
    if (_selectedItem.points != nil) {
        _isDrawing = true;
    } else {
        [self startTouch:point];
    }
}

- (void)startTouch:(CGPoint)point {
    [[self activePath] moveToPoint:point];
    _lastPoint = point;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    _currentPoint = point;
    
    if ([_selectedItem.identifier isEqualToString:@"ot_pen"]) {
        [self moveTouch:point smoothingEnabled:_selectedItem.enableSmoothing incoming:false];
    } else {
        if (_selectedItem.points != nil) {
            [self setNeedsDisplay];
        }
    }
}

- (void)moveTouch:(CGPoint)point smoothingEnabled:(Boolean)smoothingEnabled incoming:(Boolean) incoming {
    if (smoothingEnabled) {
        [[self activePath] addQuadCurveToPoint:point controlPoint: CGPointMake((point.x + _lastPoint.x) / 2, (point.y + _lastPoint.y) / 2)];
    } else {
        [[self activePath] addLineToPoint:point];
    }
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

- (void)drawShape {
    if (_selectedItem.points != nil) {
        _isDrawing = false;
        
        if (_selectedItem.points.count == 2) {
            // We have a line
            [self startTouch: CGPointMake(_startPoint.x, _startPoint.y)];
            [self moveTouch: CGPointMake(_currentPoint.x, _currentPoint.y) smoothingEnabled:_selectedItem.enableSmoothing incoming:false];
//            NSLog("Points: (%f, %f), (%f, %f)", mStartX, mStartY, mX, mY);
            [self sendUpdate:[self buildSignalFromPoint: _currentPoint] forType:@"otAnnotation_pen"];
        } else {
            CGPoint scale = [self scaleForPoints: _selectedItem.points];

            for (int i = 0; i < _selectedItem.points.count; i++) {
                CGPoint point = [(NSValue*)[_selectedItem.points objectAtIndex:i] CGPointValue];
                
                // Scale the points according to the difference between the start and end points
                float pointX = _startPoint.x + (scale.x * point.x);
                float pointY = _startPoint.y + (scale.y * point.y);

                if (_selectedItem.enableSmoothing) {
                    if (i == 0) {
                        // Do nothing
                    } else if (i == 1) {
                        [self startTouch: CGPointMake((pointX + _lastPoint.x) / 2, (pointY + _lastPoint.y) / 2)];
                    } else {
                        [self moveTouch: CGPointMake(_lastPoint.x, _lastPoint.y) smoothingEnabled:_selectedItem.enableSmoothing incoming:false];

                        if (i == _selectedItem.points.count == 1) {
                            [self moveTouch: CGPointMake(pointX, pointY) smoothingEnabled:_selectedItem.enableSmoothing incoming:false];
                        }
                    }
                } else {
                    if (i == 0) {
                        _lastPoint.x = pointX;
                        _lastPoint.y = pointY;
                        [self startTouch: CGPointMake(pointX, pointY)];
                    } else {
                        [self moveTouch: CGPointMake(pointX, pointY) smoothingEnabled:_selectedItem.enableSmoothing incoming:false];
                    }
                }

                [self sendUpdate:[self buildSignalFromPoint: CGPointMake(pointX, pointY)] forType:@"otAnnotation_pen"];

                _lastPoint.x = pointX;
                _lastPoint.y = pointY;
            }
        }
        
        NSDictionary* data = @{
                                   @"action" : @"Shape",
                                   @"variation" : @"Draw",
                                   @"payload" : @"",
                                   @"sessionId" : _sessionId,
                                   @"partnerId" : @"",
                                   @"connectionId" : _mycid
                               };
        
        //[OTAnnotationAnalytics logEvent: data];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([_selectedItem.identifier isEqualToString:@"ot_pen"]) {
        [self touchesMoved:touches withEvent:event];
    } else {
        [self drawShape];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (NSString*)buildSignalFromPoint:(CGPoint)point {
    Boolean mirrored = false;
    
    int videoWidth = 0;
    int videoHeight = 0;
    
    // FIXME: Figure out how to access the renderer - see if we need custom renderer like Android
//    OTVideoRender* renderer = nil;
    
    if (_publisher != nil) {
        _canvasId = _publisher.stream.connection.connectionId;
        _videoDimensions = _publisher.stream.videoDimensions;
    } else if (_subscriber != nil) {
        _canvasId = _subscriber.stream.connection.connectionId;
        _videoDimensions = _subscriber.stream.videoDimensions;
    }

//    if (mPublisher != null) {
//        renderer = ((AnnotationVideoRenderer) mPublisher.getRenderer());
//    } else if (mSubscriber != null) {
//        renderer = ((AnnotationVideoRenderer) mSubscriber.getRenderer());
//    }
//    
//    if (renderer != nil) {
//        mirrored = renderer.isMirrored();
//        videoWidth = renderer.getVideoWidth();
//        videoHeight = renderer.getVideoHeight();
//    } else {
//        // FIXME Throw exception?
//    }
    
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
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)didReceiveSignal:(NSString*)signal withType:(NSString*)type fromConnection:(OTConnection*)connection {
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
                        [self moveTouch: CGPointMake(toX, toY) smoothingEnabled:false incoming:true];
                    }
    //            }
            }
        } else if ([type isEqualToString:@"otAnnotation_clear"]) {
            [self clearCanvas:connection.connectionId incoming:true];
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

- (UIImage*)captureScreenshot {
    NSLog(@"Capturing screenshot");
    CGSize imageSize = CGSizeZero;
    
    imageSize = [UIScreen mainScreen].bounds.size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    UIView* videoView;
    
    if (_publisher != nil) {
        videoView = _publisher.view;
    } else if (_subscriber != nil) {
        videoView = _subscriber.view;
    }
    
    // First, draw the video
    if ([videoView respondsToSelector:
         @selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [videoView drawViewHierarchyInRect:videoView.bounds afterScreenUpdates:NO];
    }
    else {
        [videoView.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    // Then, overlay the annotations on top
    if ([self respondsToSelector:
         @selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [self drawViewHierarchyInRect:videoView.bounds afterScreenUpdates:NO];
    }
    else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Include a "flash" animation
    UIView* flash = [[UIView alloc] initWithFrame:self.bounds];
    flash.backgroundColor = [UIColor whiteColor];
    [self addSubview:flash];
    
    [UIView animateWithDuration:0.5 animations:^{
        flash.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [flash removeFromSuperview];
    }];
    
    [toolbar didCaptureImage:image forConnection:_canvasId];
    
    return image;
}

- (void)didTapAnnotationItem:(UIBarButtonItem *)sender {
    // INFO: The color setter is handled in the toolbar, not here
    
    [self removeGestureRecognizer:_tap];
    
    if ([sender isKindOfClass: OTAnnotationButtonItem.self]) {
        OTAnnotationButtonItem* item = (OTAnnotationButtonItem*) sender;
        
        if ([item.identifier isEqualToString:@"ot_clear"]) {
            [self clearCanvas: _mycid incoming:false];
        } else if ([item.identifier isEqualToString:@"ot_capture"]) {
            NSLog(@"Adding gesture recognizer");
            _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureScreenshot)];
            _tap.numberOfTapsRequired = 1;
            [self addGestureRecognizer:_tap];
            
            _selectedItem = nil;
        } else if ([item.identifier rangeOfString:@"ot_line_width"].location != NSNotFound) {
            /* Do nothing */
        } else {
            if ([item.identifier isEqualToString:@"ot_arrow"]) {
                item.points = [OTShape arrow];
            } else if ([item.identifier isEqualToString:@"ot_rectangle"]) {
                item.points = [OTShape rectangle];
            } else if ([item.identifier isEqualToString:@"ot_oval"]) {
                item.points = [OTShape oval];
                item.enableSmoothing = true;
            } else if ([item.identifier isEqualToString:@"ot_line"]) {
                item.points = [OTShape line];
            }
            _selectedItem = item;
        }

    }
}

@end
