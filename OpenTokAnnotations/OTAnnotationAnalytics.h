//
//  OTAnnotationAnalytics.h
//  OTAnnotations
//
//  Created by Trevor Boyer on 10/1/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTAnnotationAnalytics : NSObject

+(void)logEvent:(NSDictionary*)data;

@end
