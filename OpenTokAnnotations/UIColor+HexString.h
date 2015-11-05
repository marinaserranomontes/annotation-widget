//
//  UIColor+HexString.h
//  OTAnnotations
//
//  Created by Trevor Boyer on 9/28/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(HexString)

+ (NSString *)hexStringFromColor:(UIColor *)color;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIColor *)colorFromHex:(int)hex;

@end
