//
//  OTShape.m
//  OTAnnotations
//
//  Created by Trevor Boyer on 9/29/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import "OTShape.h"

// INFO: Use the points within the arrays as CGPoint b = [(NSValue *)[array objectAtIndex:0] CGPointValue];

@implementation OTShape

+ (NSArray*)line {
    return [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint: CGPointMake(0, 0)],
            [NSValue valueWithCGPoint: CGPointMake(0, 1)], nil];
}

+ (NSArray*)arrow {
    return [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint: CGPointMake(0, 1)],
            [NSValue valueWithCGPoint: CGPointMake(3, 1)],
            [NSValue valueWithCGPoint: CGPointMake(3, 0)],
            [NSValue valueWithCGPoint: CGPointMake(5, 2)],
            [NSValue valueWithCGPoint: CGPointMake(3, 4)],
            [NSValue valueWithCGPoint: CGPointMake(3, 3)],
            [NSValue valueWithCGPoint: CGPointMake(0, 3)],
            [NSValue valueWithCGPoint: CGPointMake(0, 1)], nil];
}

+ (NSArray*)rectangle {
    return [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint: CGPointMake(0, 0)],
            [NSValue valueWithCGPoint: CGPointMake(1, 0)],
            [NSValue valueWithCGPoint: CGPointMake(1, 1)],
            [NSValue valueWithCGPoint: CGPointMake(0, 1)],
            [NSValue valueWithCGPoint: CGPointMake(0, 0)], nil];
}

+ (NSArray*)oval {
    return [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint: CGPointMake(0, 0.5f)],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*(float) cos(5*M_PI/4), 0.5f + 0.5f*(float) sin(5*M_PI/4))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f, 0)],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*(float) cos(7*M_PI/4), 0.5f + 0.5f*(float) sin(7*M_PI/4))],
            [NSValue valueWithCGPoint: CGPointMake(1, 0.5f)],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*(float) cos(M_PI/4), 0.5f + 0.5f*(float) sin(M_PI/4))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f, 1)],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*(float) cos(3*M_PI/4), 0.5f + 0.5f*(float) sin(3*M_PI/4))],
            [NSValue valueWithCGPoint: CGPointMake(0, 0.5f)],
            // We need one extra to close this loop
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*(float) cos(5*M_PI/4), 0.5f + 0.5f*(float) sin(5*M_PI/4))], nil];
}

@end
