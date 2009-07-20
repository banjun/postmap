//
//  postmapViewController.h
//  postmap
//
//  Created by jun on 09/06/28.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class PostAnnotation;

@interface postmapViewController : UIViewController {
    IBOutlet MKMapView *mapView;
    
    NSOperationQueue *requestQueue;
    
    PostAnnotation *parsingPost;
}

- (IBAction)gotoCurrentLocation:(id)sender;
- (IBAction)takeMapTypeFrom:(id)sender;

@end

