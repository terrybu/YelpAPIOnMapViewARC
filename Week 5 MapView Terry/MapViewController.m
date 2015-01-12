//
//  MapViewController.m
//  Week 5 MapView Terry
//
//  Created by Terry Bu on 9/25/14.
//  Copyright (c) 2014 NM. All rights reserved.
//

#import "MapViewController.h"
#import "WebViewController.h"
#import "RestaurantPointAnnotation.h"
#import "YPAPISample.h"
#import "OAConsumer.h"
#import "OAToken.h"
#import "OAMutableURLRequest.h"
#import "NSURLRequest+OAuth.h"
#import "YourKeysAndTokens.h"

@interface MapViewController ()

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.locationManager = [[CLLocationManager alloc]init];
    [self.locationManager setDelegate:self];
    if (IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        //[self.locationManager requestAlwaysAuthorization];
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.myMapView.delegate = self;
    self.myMapView.showsUserLocation = YES;
    [self.myMapView setMapType:MKMapTypeStandard];
    [self.myMapView setZoomEnabled:YES];
    [self.myMapView setScrollEnabled:YES];
    
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)segmentMapSelection:(id)sender {
    
    switch (((UISegmentedControl*)sender).selectedSegmentIndex) {
        case 0:
            self.myMapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.myMapView.mapType = MKMapTypeHybrid;
            break;
        case 2:
            self.myMapView.mapType = MKMapTypeSatellite;
            break;
    }
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    //Everytime the location gets updated, we start from a clean mapview - clear out all annotations
    [mapView removeAnnotations:mapView.annotations];
    
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 2000, 2000);
    //you can set zoom to 50000 on each to make it nicely zoomed out
    [self.myMapView setRegion:region animated:YES];
    
    [self requestDataFromYelpAPI:userLocation];
}


- (void) requestDataFromYelpAPI:(MKUserLocation *)userLocation {
    CLGeocoder *clgeocoder = [[CLGeocoder alloc]init];
    [clgeocoder geocodeAddressString:@"TurnToTech, New York, NY" completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
        else {
            
            //Location Version
            //            NSString *location = @"flatiron%20NY";
            //            //note that spaces can't be directly substitued into the URL because it will break the URL
            //            //%20 denotes spaces
            //            NSString *address = [[NSString alloc]initWithFormat:@"http://api.yelp.com/v2/search?term=%@&location=%@&limit=%@", term, location, searchLimit];
            
            //Configuration
            NSString *term = @"asian";
            NSString *radiusFilter = @"300";
            NSString *searchLimit= @"20";
            
            NSString *address = [[NSString alloc]initWithFormat:@"http://api.yelp.com/v2/search?term=%@&ll=%f,%f&radius_filter=%@&limit=%@", term, userLocation.coordinate.latitude, userLocation.coordinate.longitude,radiusFilter, searchLimit];
            
            NSURL *URL = [NSURL URLWithString:address];
            //Some boiler plate code to make with OAuth
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kConsumerKey secret:kConsumerSecret];
            //Generates the key we pass for OAuth
            OAToken *token = [[OAToken alloc] initWithKey:kToken secret:kTokenSecret];
            //Generates the token we pass for OAuth
            id<OASignatureProviding, NSObject> provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
            //Encypts the key & token to send it over the Internet
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:URL consumer:consumer token:token realm:nil signatureProvider:provider];
            //Makes the URL request for our url with key, token and other info we set
            [request prepare];
            //OAuth boilerplate
            
            self.responseData = [[NSMutableData alloc] init];
            //Allocates the NSData object that will handle our asynchronous request
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; //This is the part we make (fire) url request
        }
    }];

}




#pragma mark NSURLConnection Delegate Methods

- (void) connection:(NSURLConnection* )connection didReceiveResponse:(NSURLResponse *)response {
    //this handler, gets hit ONCE
}

- (void)connection: (NSURLConnection *)connection didReceiveData:(NSData *) data {
    //this handler, gets hit SEVERAL TIMES
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    //Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //this handler gets hit ONCE
    // The request is complete and data has been received
    // You can parse the stuff in your data variable now or do whatever you want

    NSLog(@"connection finished");
    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[self.responseData length]);
    
    [self turnDataIntoWorkableJSONAndDropAnnotationsOnMapView:self.responseData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

- (void) turnDataIntoWorkableJSONAndDropAnnotationsOnMapView:(NSMutableData *) responseData {
    //Convert your responseData object
    NSError *myError = nil;
    NSDictionary *responseDataInNSDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&myError];
    
    if (myError) {
        NSLog(@"error: %@", myError);
        return;
    }
    else {
        NSArray *resultsArray = [responseDataInNSDictionary objectForKey:@"businesses"];
        //        NSLog(@"%@", resultsArray);
        
        for (int i = 0; i < resultsArray.count; i++) {
            NSDictionary *restaurantObject = resultsArray[i];
            NSString *restaurantName = [restaurantObject objectForKey:@"name"];
            NSDictionary *locationObject = [restaurantObject objectForKey:@"location"];
            NSDictionary *coordinateObject = [locationObject objectForKey:@"coordinate"];
            double latitude = [[coordinateObject objectForKey:@"latitude"] doubleValue];
            double longitude = [[coordinateObject objectForKey:@"longitude"] doubleValue];
            CLLocationCoordinate2D restaurantCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
            RestaurantPointAnnotation *annotation = [[RestaurantPointAnnotation alloc]init];
            [annotation setCoordinate:restaurantCoordinate];
            [annotation setTitle:restaurantName];
            [self.myMapView addAnnotation:annotation];
            
            NSString *yelpURL = [restaurantObject objectForKey:@"url"];
            annotation.url = yelpURL;
            
            NSLog(@"%@", restaurantName);
        }
        
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[RestaurantPointAnnotation class]]) {
        MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"loc"];
        annotationView.canShowCallout = YES;
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        return annotationView;
    }
    else {
        MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"loc"];
        annotationView.canShowCallout = YES;
        return annotationView;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    RestaurantPointAnnotation *thisAnnotation = (RestaurantPointAnnotation *) view.annotation;
    self.restaurantName = thisAnnotation.title;
    self.url = thisAnnotation.url;
    [self performSegueWithIdentifier:@"webViewSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    WebViewController *webVC = [segue destinationViewController];
    webVC.title = self.restaurantName;
    webVC.url = self.url;

}




@end
