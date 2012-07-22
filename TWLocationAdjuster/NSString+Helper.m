//
//  NSString.h
//  TruckWiser
//
//  Created by Andrey Tabachnik on 6/27/12 from
//  http://blog.corywiles.com/forward-geocoding-in-ios4-and-ios5.
//  Copyright (c) 2012 Truckwiser. All rights reserved.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//   
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//   
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSString+Helper.h"
#import "NSObject+SBJson.h"

@implementation NSString (Helper)

- (CLLocation *)googleGeocodeAddress
{
    
    __block CLLocation *location = nil;
    
    NSString *gUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=false", self];
    
    gUrl = [gUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *infoData = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:gUrl]
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
    
    if ((infoData == nil) || ([infoData isEqualToString:@"[]"])) {
        return location;
    } else {
        
        NSDictionary *jsonObject = [infoData JSONValue]; 

        if (jsonObject == nil) {
            return nil;
        }
        
        NSArray *result = [jsonObject objectForKey:@"results"];
        
        [result enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *value = [[obj objectForKey:@"geometry"] valueForKey:@"location"];
            
            location = [[CLLocation alloc] initWithLatitude:[[value valueForKey:@"lat"] doubleValue]
                                                  longitude:[[value valueForKey:@"lng"] doubleValue]];
            
            *stop = YES;
        }];  
    }   
    
    return location;
}

- (void)fetchGeocodeAddressWithCompletionHanlder:(ForwardGeoCompletionBlock)completion
{
    
    if (NSClassFromString(@"CLGeocoder")) {
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        CLGeocodeCompletionHandler completionHandler = ^(NSArray *placemarks, NSError *error) {
            
            if (error) {
                NSLog(@"error finding placemarks: %@", [error localizedDescription]);
            }
            
            if (placemarks) {
                
                [placemarks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    CLPlacemark *placemark = (CLPlacemark *)obj;
                    
                    NSLog(@"PLACEMARK: %@", placemark);
                    
                    if ([placemark.country isEqualToString:@"United States"]) {
                        
                        NSLog(@"********found coords for zip: %f %f", placemark.location.coordinate.latitude,placemark.location.coordinate.longitude);
                        
                        if (completion) {
                            completion(placemark.location.coordinate);
                        }
                        
                        *stop = YES;
                    }
                }];
            }
        };
        
        [geocoder geocodeAddressString:self completionHandler:completionHandler];
        
    } else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        
        dispatch_async(queue, ^{
            
            CLLocation *location = [self googleGeocodeAddress];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(location.coordinate);
                }
            });
        });
    }
}

@end
