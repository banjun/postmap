//
//  postmapViewController.m
//  postmap
//
//  Created by jun on 09/06/28.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "postmapViewController.h"
#import "PostAnnotation.h"
#import "PostDetailViewController.h"
#import "ProgressiveOperation.h"
#import <CoreLocation/CoreLocation.h>

@interface postmapViewController ()

- (void)readDefaults;
- (void)saveDefaults;

@end

@implementation postmapViewController

// The designated initializer. Override to perform setup that is required before the view is loaded.
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
//        // Custom initialization
//    }
//    return self;
//}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    requestQueue = [[NSOperationQueue alloc] init];
    [requestQueue setMaxConcurrentOperationCount:1];
    
    [super viewDidLoad];
    
    self.title = @"Map";
    
    mapView.showsUserLocation = YES;
    mapViewFrame = mapView.frame;
    [self readDefaults];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = 100.0;
    NSLog(@"headingAvailable = %d", locationManager.headingAvailable);
    [locationManager startUpdatingLocation];
    if (locationManager.headingAvailable) {
        mapView.contentMode = UIViewContentModeCenter;
        mapViewFrame.size.width = sqrt(pow(mapViewFrame.size.width, 2) + pow(mapViewFrame.size.height, 2));
        mapViewFrame.size.height = mapViewFrame.size.width;
        
        CGPoint center = mapView.center;
        mapView.frame = mapViewFrame;
        mapView.center = center;
        
        locationManager.headingFilter = 2.0;
        [locationManager startUpdatingHeading];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
//    CGAffineTransform transform = mapView.transform;
    if (locationManager.headingAvailable) {
        mapView.transform = CGAffineTransformIdentity;
        CGPoint center = mapView.center;
        mapView.frame = mapViewFrame; 
        mapView.center = center;
    }
//    mapView.transform = transform;
}    

- (IBAction)gotoCurrentLocation:(id)sender
{
    static CLLocationDegrees kZoomedSpan = 0.005;
    
    if (mapView.region.span.latitudeDelta > kZoomedSpan) {
        MKCoordinateSpan span = MKCoordinateSpanMake(kZoomedSpan, kZoomedSpan);
        [mapView setRegion:MKCoordinateRegionMake(mapView.userLocation.coordinate, span) animated:YES];
    } else {
        [mapView setCenterCoordinate:mapView.userLocation.coordinate animated:YES];
    }
    
    if (locationManager.headingAvailable) {
        [locationManager performSelector:@selector(startUpdatingHeading) withObject:nil afterDelay:0.1];
    }
}

- (IBAction)takeMapTypeFrom:(id)sender
{
    mapView.mapType = [(UISegmentedControl *)sender selectedSegmentIndex];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [locationManager stopUpdatingLocation];
    [locationManager stopUpdatingHeading];
    [locationManager release], locationManager = nil;
    [super dealloc];
}


- (void)readDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hasLastRegion"]) {
        MKCoordinateRegion region;
        region.center.latitude = [defaults doubleForKey:@"lastLatitude"];
        region.center.longitude = [defaults doubleForKey:@"lastLongitude"];
        region.span.latitudeDelta = [defaults doubleForKey:@"lastLatitudeDelta"];
        region.span.longitudeDelta = [defaults doubleForKey:@"lastLongitudeDelta"];
        [mapView setRegion:region animated:YES];
    }
}
- (void)saveDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"hasLastRegion"];
    [defaults setDouble:mapView.region.center.latitude forKey:@"lastLatitude"];
    [defaults setDouble:mapView.region.center.longitude forKey:@"lastLongitude"];
    [defaults setDouble:mapView.region.span.latitudeDelta forKey:@"lastLatitudeDelta"];
    [defaults setDouble:mapView.region.span.longitudeDelta forKey:@"lastLongitudeDelta"];
    [defaults synchronize];
}

- (void)fetchPostsOperation:(ProgressiveOperation *)op
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    MKCoordinateRegion region = mapView.region;
        
    CLLocationDegrees minX = region.center.longitude - region.span.longitudeDelta;
    CLLocationDegrees maxX = region.center.longitude + region.span.longitudeDelta;
    CLLocationDegrees minY = region.center.latitude - region.span.latitudeDelta;
    CLLocationDegrees maxY = region.center.latitude + region.span.latitudeDelta;
    
    NSURL *markersURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://postmap.org/ajax?type=map%%7cbounds&maxX=%.13f&minX=%.13f&maxY=%.13f&minY=%.13f",
                                              maxX, minX, maxY, minY]];
    NSLog(@"markersURL: %@", markersURL);
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:markersURL] autorelease];
    [parser setDelegate:self];
    BOOL parsed = [parser parse];
    NSLog(@"parsed: %d", parsed);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
//    NSLog(@"start [%@], attrs = %@", elementName, attributeDict);
    
    NSString *postID = [attributeDict objectForKey:@"id"];
    
    // check if already loaded
    NSArray *annotations = [NSArray arrayWithArray:mapView.annotations];
    for (id annotation in annotations) {
        if ([annotation respondsToSelector:@selector(postID)]) {
            if ([postID isEqualToString:[annotation postID]]) return;
        }
    }        
    CLLocationCoordinate2D center;
    center.latitude = [[attributeDict objectForKey:@"lat"] doubleValue];
    center.longitude = [[attributeDict objectForKey:@"lng"] doubleValue];
    
    PostAnnotation *post = [[[PostAnnotation alloc] initWithCoordinate:center] autorelease];
    post.title = @"Info";
    post.postID = postID;
    post.iconString = [attributeDict objectForKey:@"icon"];
    
    if ([mapView.annotations count] > 255) {
        id firstPost = nil;
        for (id annotation in annotations) {
            if ([annotation isKindOfClass:[PostAnnotation class]]) {
                firstPost = annotation;
                break;
            }
        }
        [mapView performSelectorOnMainThread:@selector(removeAnnotation:) withObject:firstPost waitUntilDone:YES];
    }
    [mapView performSelectorOnMainThread:@selector(addAnnotation:) withObject:post waitUntilDone:NO];
}

#pragma mark -
#pragma mark MKMapView Delegate

- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated:(BOOL)animated
{
    if (!animated) {
        [UIView beginAnimations:@"mapViewRotateAnimation" context:nil];
        mapView.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
        [locationManager stopUpdatingHeading];
    }
    
    static CLLocationDegrees kZoomedSpan = 0.050;
    if (mapView.region.span.latitudeDelta > kZoomedSpan) return;
    
    ProgressiveOperation *op = [[ProgressiveOperation alloc] initWithTitle:@"fetch posts" target:self selector:@selector(fetchPostsOperation:) object:nil];
    [requestQueue addOperation:op];
    [op autorelease];
    
    [self saveDefaults];
}
MKPinAnnotationColor pinColorFromIconString(NSString *iconString)
{
    if ([iconString isEqualToString:@"green"]) return MKPinAnnotationColorGreen;
    if ([iconString isEqualToString:@"jp"]) return MKPinAnnotationColorPurple;
    if ([iconString isEqualToString:@"jp_red"]) return MKPinAnnotationColorPurple;
    return MKPinAnnotationColorRed;
}
- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[PostAnnotation class]]) return nil;
    PostAnnotation *post = (PostAnnotation *)annotation;
    
    MKPinAnnotationView *view = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:@"post"];
    if (!view) {
        view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"post"] autorelease];
    }
    view.annotation = post;
    view.canShowCallout = YES;
    view.animatesDrop = YES;
    view.pinColor = pinColorFromIconString(post.iconString);
    if (!view.rightCalloutAccessoryView) {
        view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    
    return view;
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    PostDetailViewController *vc = [[PostDetailViewController alloc] initWithNibName:@"PostDetailViewController" bundle:nil];
    vc.post = view.annotation;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}


#pragma mark -
#pragma mark CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate,
                                                                   2*newLocation.horizontalAccuracy,
                                                                   2*newLocation.horizontalAccuracy);
    static CLLocationDegrees kZoomedSpan = 0.005;
    if (region.span.latitudeDelta < kZoomedSpan) {
        region.span = MKCoordinateSpanMake(kZoomedSpan, kZoomedSpan);
    }
    [mapView setRegion:region animated:YES];
    [mapView setCenterCoordinate:newLocation.coordinate animated:YES];
    
    [locationManager stopUpdatingLocation];
}
- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    [UIView beginAnimations:@"mapViewRotateAnimation" context:nil];
    mapView.transform = CGAffineTransformMakeRotation(- newHeading.trueHeading * M_PI / 180.0);    
    [UIView commitAnimations];
}


@end
