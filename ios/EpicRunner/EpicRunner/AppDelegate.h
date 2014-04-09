//
//  AppDelegate.h
//  EpicRunner
//
//  Created by Jeppe on 18/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) const char *databasePath;

@end
