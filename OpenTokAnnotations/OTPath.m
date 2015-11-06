//
//  OTPath.m
//  OTAnnotations
//
//  Created by Trevor Boyer on 9/26/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import "OTPath.h"

@implementation OTPath

-(instancetype)init {
    if (self = [super init]) {
        _bezierPath = [UIBezierPath bezierPath];
    }
    return self;
}

@end
