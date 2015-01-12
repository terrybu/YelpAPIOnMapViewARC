//
//  MapViewController.h
//  Week 5 MapView Terry
//
//  Created by Terry Bu on 9/25/14.
//  Copyright (c) 2014 NM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WebViewController.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue])

@interface MapViewController : UIViewController
<CLLocationManagerDelegate, MKMapViewDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *myMapView;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSMutableData *responseData;

@property (strong, nonatomic) NSString *restaurantName;
@property (strong, nonatomic) NSString* url;

- (IBAction)segmentMapSelection:(id)sender;



- (void) requestDataFromYelpAPI:(MKUserLocation *)userLocation;


@end
