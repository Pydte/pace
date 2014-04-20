//
//  HistoryTableViewController.h
//  EpicRunner
//
//  Created by Jeppe on 25/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <MapKit/MapKit.h>
#import "Run.h"

@interface HistoryTableViewController : UITableViewController

@property AppDelegate *mainDelegate;
@property NSMutableArray *runs;
- (void)deleteRun;

@end
