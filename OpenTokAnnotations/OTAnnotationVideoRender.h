//
//  OTAnnotationVideoRender.h
//  OTAnnotations
//
//  Created by Trevor Boyer on 10/15/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>

@interface OTAnnotationVideoRender : NSObject<OTVideoRender>

@property (nonatomic, assign) BOOL mirroring;

@end