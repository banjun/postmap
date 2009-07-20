//
//  PostAnnotation.m
//  postmap
//
//  Created by jun on 09/06/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PostAnnotation.h"


@implementation PostAnnotation

@synthesize coordinate;
@synthesize title, subtitle;
@synthesize postID;

- (id)initWithCoordinate:(CLLocationCoordinate2D)theCoordinate
{
    if (self = [super init]) {
        coordinate = theCoordinate;
    }
    return self;
}
@end
