//
//  AppDelegate.m
//  EpicRunner
//
//  Created by Jeppe on 18/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // SQLite setup
    // - Check to see if SQLite db file exists, else create
	sqlite3 *database = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
    NSString *sqlitePath = [documentsDirectory stringByAppendingPathComponent:@"epicDB.sqlite"];
	self.databasePath = strdup([sqlitePath UTF8String]); //Convert to UTF8 char* and malloc
    
    if (![fileManager fileExistsAtPath:sqlitePath]){
		if(![fileManager createFileAtPath:sqlitePath contents:nil attributes:nil]){
			NSLog(@"[ERROR] SQLITE Database failed to initialize! File could not be created in application.");
		} else {
			if(sqlite3_open(self.databasePath, &database) == SQLITE_OK) {
				sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS runs (id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                                                        "startDate INTEGER, "
                                                                        "endDate INTEGER, "
                                                                        "distance REAL)", NULL, NULL, NULL);
				sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS runs_location (id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                                                                 "runId INTEGER REFERENCES run(id) ON DELETE CASCADE, "
                                                                                 "latitude REAL, "
                                                                                 "longitude REAL, "
                                                                                 "horizontalAccuracy REAL, "
                                                                                 "altitude REAL, "
                                                                                 "verticalAccuracy REAL, "
                                                                                 "speed REAL, "
                                                                                 "timestamp INTEGER)",NULL, NULL, NULL);
				sqlite3_close(database);
				database = nil;
				NSLog(@"SQLITE Database created and is now a'okay.");
			} else {
				NSLog(@"[ERROR] SQLITE Could not seed tables!");
			}
            
		}
	}
    
    
    
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
