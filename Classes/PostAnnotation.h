//
//  PostAnnotation.h
//  postmap
//
//  Created by jun on 09/06/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface PostAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    
    NSString *title;
    NSString *subtitle;
    
    NSString *postID;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@property (retain) NSString *title;
@property (retain) NSString *subtitle;

@property (retain) NSString *postID;

@end
