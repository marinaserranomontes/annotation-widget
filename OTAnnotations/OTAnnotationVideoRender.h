//
//  OTAnnotationVideoRender.h
//  OTAnnotations
//
//  Created by Trevor Boyer on 10/3/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>

@protocol OTAnnotationVideoRender <OTVideoRender>

@property (nonatomic, assign) BOOL mirrored;

@end
