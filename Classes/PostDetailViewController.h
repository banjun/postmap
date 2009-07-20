//
//  PostDetailViewController.h
//  postmap
//
//  Created by jun on 09/07/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PostAnnotation;

@interface PostDetailViewController : UITableViewController {
    PostAnnotation *post;
    
    IBOutlet UIImageView *postPictureView;
    IBOutlet UILabel *postNameLabel;
    
    NSMutableArray *timesGathered; // array of (name, times) NSDictionary
    
    NSInteger parsingKind;
    NSInteger parsingTDIndex;
}

@property (retain) PostAnnotation *post;

@end
