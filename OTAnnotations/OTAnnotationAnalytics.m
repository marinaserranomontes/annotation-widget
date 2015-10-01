//
//  OTAnnotationAnalytics.m
//  OTAnnotations
//
//  Created by Trevor Boyer on 10/1/15.
//  Copyright © 2015 TokBox, Inc. All rights reserved.
//

#import "OTAnnotationAnalytics.h"

@implementation OTAnnotationAnalytics

NSString *const kLoggingUrl = @"https://hlg.tokbox.com/prod/logging/ClientEvent";

+(void)logEvent:(NSDictionary*)data {
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString: kLoggingUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // TODO: Do we need to check the response?
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
    }];
    
    [postDataTask resume];
}
    
@end
