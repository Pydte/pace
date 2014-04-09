//
//  RunFinishedSummaryViewController.m
//  EpicRunner
//
//  Created by Jeppe on 26/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//
//#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RunFinishedSummaryViewController.h"
#import <MapKit/MapKit.h>
#import "sqlite3.h"

@interface RunFinishedSummaryViewController ()
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation RunFinishedSummaryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mainDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    // Save run to database
    sqlite3 *database;
    sqlite3_stmt *statement;
    
    /// Open database
    if(sqlite3_open(self.mainDelegate.databasePath, &database) != SQLITE_OK) {
        NSLog(@"[ERROR] SQLITE: Failed to open database! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad", sqlite3_errmsg(database));
		return;
    }
    
    /// Prepare insert of run
	if(sqlite3_prepare_v2(database, "INSERT INTO runs (startDate, endDate, distance) VALUES(?,?,?)", -1, &statement, nil) != SQLITE_OK){
		NSLog(@"[ERROR] SQLITE: Failed to prepare statement! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad", sqlite3_errmsg(database));
		return;
	}
	
    /// Bind parametres
	sqlite3_bind_int(statement, 1, [self.finishedRun.start timeIntervalSince1970]);
	sqlite3_bind_int(statement, 2, [self.finishedRun.end timeIntervalSince1970]);
	sqlite3_bind_double(statement, 3, self.finishedRun.distance);
	
    /// Execute insert of run
	if (sqlite3_step(statement) == SQLITE_ERROR) {
		NSLog(@"[ERROR] SQLITE: Failed to insert into database! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad", sqlite3_errmsg(database));
		return;
	}
	sqlite3_finalize(statement);
	int runId = (int)sqlite3_last_insert_rowid(database);
    
    for (CLLocation *location in self.finishedRun.locations) {
        /// Prepare insert of locations of run
        if(sqlite3_prepare_v2(database, "INSERT INTO runs_location (latitude, runId, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed, timestamp) VALUES(?,?,?,?,?,?,?,?)", -1, &statement, nil) != SQLITE_OK){
            NSLog(@"[ERROR] SQLITE: Failed to prepare statement! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad;locations", sqlite3_errmsg(database));
            return;
        }
        
        /// Bind parametres
        sqlite3_bind_int(statement, 2, runId);                                      //runId SOMETHING IS NOT WORKING?
        sqlite3_bind_double(statement, 1, location.coordinate.latitude);            //latitude
        sqlite3_bind_double(statement, 3, location.coordinate.longitude);           //longitude
        sqlite3_bind_double(statement, 4, location.horizontalAccuracy);             //horizontalAccuracy
        sqlite3_bind_double(statement, 5, location.altitude);                       //altitude
        sqlite3_bind_double(statement, 6, location.verticalAccuracy);               //verticalAccuracy
        sqlite3_bind_double(statement, 7, location.speed);                          //speed
        sqlite3_bind_int(statement, 8, [location.timestamp timeIntervalSince1970]); //timestamp
        
        /// Execute insert of location
        if (sqlite3_step(statement) == SQLITE_ERROR) {
            NSLog(@"[ERROR] SQLITE: Failed to insert into database! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad", sqlite3_errmsg(database));
            return;
        }
        sqlite3_finalize(statement);
    }
    
    /// Close database
    sqlite3_close(database);
    database = nil;

	
    
    // Populate view
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM. dd, yyyy, HH:mm"];
    
    NSTimeInterval runTimeInSeconds = [self.finishedRun.end timeIntervalSinceDate:self.finishedRun.start];
    int runTimeInMinutes = runTimeInSeconds/60;
    int runTimeRemainingSeconds = fmod(runTimeInSeconds, 60);
    NSMutableString *runText = [[NSMutableString alloc] init];
    [runText appendFormat:@"Run start:  "];
    [runText appendString:[dateFormatter stringFromDate:self.finishedRun.start]];
    [runText appendString:@"\nDistance:  "];
    [runText appendString:[NSString stringWithFormat:@"%.2f",self.finishedRun.distance/1000]];
    [runText appendString:@" km\nDuration:  "];
    [runText appendString:[NSString stringWithFormat:@"%d",runTimeInMinutes]];
    [runText appendString:@":"];
    [runText appendString:[NSString stringWithFormat:@"%d",runTimeRemainingSeconds]];
    [runText appendString:@" min\n\nAvg. Speed:  "];
    [runText appendString:[NSString stringWithFormat:@"%.2f",runTimeInMinutes/(self.finishedRun.distance/1000)]];
    [runText appendString:@" min/km"];
    self.detailsLabel.text = runText;
    
    
    // Find extreme coordinates
    double latTop    = -999999;
    double lonRight  = -999999;
    double latBottom = 999999;
    double lonLeft   = 999999;
    
    for (CLLocation *location in self.finishedRun.locations) {
        if (location.coordinate.latitude > latTop)
            latTop = location.coordinate.latitude;
        if (location.coordinate.latitude < latBottom)
            latBottom = location.coordinate.latitude;
        
        if (location.coordinate.longitude > lonRight)
            lonRight = location.coordinate.longitude;
        if (location.coordinate.longitude < lonLeft)
            lonLeft = location.coordinate.longitude;
    }
      
    // Find longest distance horizontal and vertical
    CLLocation *locTopLeft    = [[CLLocation alloc] initWithLatitude:(latTop)longitude:(lonLeft)];
    CLLocation *locBottomLeft = [[CLLocation alloc] initWithLatitude:(latTop)longitude:(lonLeft)];
    CLLocation *locTopRight   = [[CLLocation alloc] initWithLatitude:(latTop)longitude:(lonRight)];
    double distanceLat        = [locTopLeft distanceFromLocation:locBottomLeft];
    double distanceLon        = [locTopLeft distanceFromLocation:locTopRight];
    double distanceMargin;
    if (distanceLat > distanceLon)
        distanceMargin = distanceLat/20;
    else
        distanceMargin = distanceLon/20;
    
    // Center map
    CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake((latTop+latBottom)/2, (lonRight+lonLeft)/2);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoord, distanceLat+distanceMargin, distanceLon+distanceMargin)];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    //Draw route
    [self drawRoute];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)drawRoute {
    CLLocationCoordinate2D *pointsCoordinate = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * self.finishedRun.locations.count);
    
    for (int i=0; i<self.finishedRun.locations.count; i++) {
        CLLocation *location = self.finishedRun.locations[i];
        pointsCoordinate[i] = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:pointsCoordinate count:self.finishedRun.locations.count];
    free(pointsCoordinate);
    
    [self.mapView addOverlay:polyline];
}

// For earlier than iOS7: - (MKPolylineRenderer *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay{
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor blueColor];
        return routeRenderer;
    }
    else return nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
