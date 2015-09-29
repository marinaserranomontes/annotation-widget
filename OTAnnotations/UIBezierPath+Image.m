
//
//  UIBezierPath+UIImage.m
//  OTAnnotations
//
//  Created by Trevor Boyer on 9/28/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import "UIBezierPath+Image.h"

@implementation UIBezierPath (Image)

-(UIImage*) strokeImageWithColor:(UIColor*)color {
    // adjust bounds to account for extra space needed for lineWidth
    CGFloat width = self.bounds.size.width + self.lineWidth * 2;
    CGFloat height = self.bounds.size.height + self.lineWidth * 2;
    CGRect bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, width, height);

    UIView *view = [[UIView alloc] initWithFrame:bounds];
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -view.bounds.size.height);
    
    CGContextTranslateCTM(context, -(bounds.origin.x - self.lineWidth), -(bounds.origin.y - self.lineWidth));
    
    [color set];
    [self stroke];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

// TODO: May want to add a fillImageWithColor method

@end