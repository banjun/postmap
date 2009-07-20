//
//  postmapAppDelegate.h
//  postmap
//
//  Created by jun on 09/06/28.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class postmapViewController;

@interface postmapAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IBOutlet UINavigationController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;

@end

