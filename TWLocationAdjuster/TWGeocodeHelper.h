//
//  TWGeocodeHelper.h
//  TruckWiser
//
//  Created by Andrey Tabachnik on 6/27/12.
//  Copyright (c) 2012 TruckWiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^ForwardGeoCompletionBlock)(CLLocationCoordinate2D coords);
typedef void (^ReverseGeoCompletionBlock)(NSString *address);

@interface TWGeocodeHelper : NSObject

+ (void)geocodeAddress:(NSString *)address withCompletionHanlder:(ForwardGeoCompletionBlock)completion;
+ (void)reverseGeocodeLocation:(CLLocation *)location withCompletionHanlder:(ReverseGeoCompletionBlock)completion;
@end
