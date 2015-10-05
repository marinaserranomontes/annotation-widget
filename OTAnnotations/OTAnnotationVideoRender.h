//
//  OTAnnotationVideoRender.h
//  OTAnnotations
//
//  Created by Trevor Boyer on 10/3/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>

@interface OTAnnotationVideoRender : NSObject<OTVideoRender>

@property (nonatomic) Boolean mirrored;

@end
