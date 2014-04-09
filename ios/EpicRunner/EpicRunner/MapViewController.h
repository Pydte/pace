//
//  MapViewController.h
//  EpicRunner
//
//  Created by Jeppe on 18/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController

@property AppDelegate *mainDelegate;
- (IBAction)unwindToMap:(UIStoryboardSegue *)segue;

@end
