//
//  TWGeocodeHelper
//  TruckWiser
//
//  Created by Andrey Tabachnik on 6/27/12 from
//  http://blog.corywiles.com/forward-geocoding-in-ios4-and-ios5.
//  Copyright (c) 2012 TruckWiser. All rights reserved.
//

#import "AddressBookUI/AddressBookUI.h"
#import "TWGeocodeHelper.h"
#import "NSObject+SBJson.h"

#define kTWGoogleGeocodeURL @"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=false"

#define kTWOpenMapsReverseGeocodeURL @"http://nominatim.openstreetmap.org/reverse?format=json&zoom=18&addressdetails=1&lat=%f&lon=%f"

@implementation TWGeocodeHelper

// for ios < 5
+ (CLLocation *)googleGeocodeAddress:(NSString *)address
{
    
    __block CLLocation *location = nil;
    
    NSString *gUrl = [NSString stringWithFormat:kTWGoogleGeocodeURL, address];
    
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

+ (NSString *)openMapReverseGeocodeLocation:(CLLocation *)location
{
    __block NSString *address = @"";
    
    NSString *url = [NSString stringWithFormat:kTWOpenMapsReverseGeocodeURL, location.coordinate.latitude, location.coordinate.longitude];
    
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *infoData = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:url]
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    
    if (infoData) {
        NSDictionary *jsonObject = [infoData JSONValue];
        
        if (jsonObject == nil) {
            return nil;
        }
        
        NSDictionary *result = [jsonObject objectForKey:@"address"];
        
        if (result) {
            NSString *road     = [result objectForKey:@"road"];
            NSString *city     = [result objectForKey:@"city"];
            NSString *postcode = [result objectForKey:@"postcode"];
            
            if (!city) {
               city = [result objectForKey:@"village"]; 
            }
            
            if (!city) {
                city = [result objectForKey:@"county"];
            }
            
            if (road && city && postcode) {
                address = [NSString stringWithFormat:@"%@, %@, %@", road, city, postcode];
            }
        }
    }
    
    return address;
}

+ (void)geocodeAddress:(NSString *)address withCompletionHanlder:(ForwardGeoCompletionBlock)completion
{
    if (NSClassFromString(@"CLGeocoder")) {
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        CLGeocodeCompletionHandler completionHandler = ^(NSArray *placemarks, NSError *error) {
            
            if (error) {
                NSLog(@"Error finding placemarks: %@", [error localizedDescription]);
            }
            
            if (placemarks) {
                
                [placemarks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    CLPlacemark *placemark = (CLPlacemark *)obj;
                    
                    NSLog(@"Found coords for zip: %f %f", placemark.location.coordinate.latitude,placemark.location.coordinate.longitude);
                    
                    if (completion) {
                        completion(placemark.location.coordinate);
                    }
                    
                    *stop = YES;
                }];
            }
        };
        
        [geocoder geocodeAddressString:address completionHandler:completionHandler];
        
    } else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        
        dispatch_async(queue, ^{
            
            CLLocation *location = [TWGeocodeHelper googleGeocodeAddress:address];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(location.coordinate);
                }
            });
        });
    }
}

+ (void)reverseGeocodeLocation:(CLLocation *)location withCompletionHanlder:(ReverseGeoCompletionBlock)completion
{
    if (NSClassFromString(@"CLGeocoder")) {
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        CLGeocodeCompletionHandler completionHandler = ^(NSArray *placemarks, NSError *error) {
            
            if (error) {
                NSLog(@"Error finding placemarks: %@", [error localizedDescription]);
            }
            
            if (placemarks) {
                
                [placemarks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    CLPlacemark *placemark = (CLPlacemark *)obj;
           
                    if ([placemark.country isEqualToString:@"United States"]) {
                        
                        NSLog(@"Found coords for zip: %f %f", placemark.location.coordinate.latitude,placemark.location.coordinate.longitude);
                        
                        if (completion && [placemark.addressDictionary count]) {
                            NSString *formattedAddress = [NSString stringWithFormat:@"%@ %@, %@, %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality, placemark.postalCode];
                            
                            NSLog(@"%@", formattedAddress);
                            completion(formattedAddress);
                        }
                        
                        *stop = YES;
                    }
                }];
            }
        };
        
        [geocoder reverseGeocodeLocation:location completionHandler:completionHandler]; 
    } else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        
        dispatch_async(queue, ^{
            
            NSString *formattedAddress = [TWGeocodeHelper openMapReverseGeocodeLocation:location];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(formattedAddress);
                }
            });
        });
    }
}

@end
