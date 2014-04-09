//
//  RunFinishedSummaryViewController.h
//  EpicRunner
//
//  Created by Jeppe on 26/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Run.h"
#import "AppDelegate.h"

@interface RunFinishedSummaryViewController : UIViewController

@property AppDelegate *mainDelegate;
@property Run *finishedRun;

@end
