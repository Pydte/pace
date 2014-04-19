//
//  DetailViewViewController.m
//  EpicRunner
//
//  Created by Jeppe on 19/04/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "DetailViewViewController.h"
#import <MapKit/MapKit.h>

@interface DetailViewViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;
@property (weak, nonatomic) IBOutlet UILabel *lblDuration;
@property (weak, nonatomic) IBOutlet UILabel *lblAvgSpeed;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxSpeed;
@property (weak, nonatomic) IBOutlet UILabel *lblMinAltitude;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxAltitude;

@end

@implementation DetailViewViewController

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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM. dd, yyyy, HH:mm"];
    self.lblDate.text = [dateFormatter stringFromDate:self.selectedRun.start];
    
    self.lblDistance.text = [NSString stringWithFormat:@"%.2f",self.selectedRun.distance/1000];
    
    NSTimeInterval runTimeInSeconds = [self.selectedRun.end timeIntervalSinceDate:self.selectedRun.start];
    int runTimeInMinutes = runTimeInSeconds/60;
    int runTimeRemainingSeconds = fmod(runTimeInSeconds, 60);
    NSMutableString *runDuration = [[NSMutableString alloc] init];
    [runDuration appendString:[NSString stringWithFormat:@"%d",runTimeInMinutes]];
    [runDuration appendString:@":"];
    [runDuration appendString:[NSString stringWithFormat:@"%d",runTimeRemainingSeconds]];
    self.lblDuration.text = runDuration;
    
    
    // Find extreme coordinates
    double latTop    = -999999;
    double lonRight  = -999999;
    double latBottom = 999999;
    double lonLeft   = 999999;
    
    double avgSpeed = 0.0; // In min/km
    
    for (CLLocation *location in self.selectedRun.locations) {
        //Find extreme coordinates
        if (location.coordinate.latitude > latTop)
            latTop = location.coordinate.latitude;
        if (location.coordinate.latitude < latBottom)
            latBottom = location.coordinate.latitude;
        
        if (location.coordinate.longitude > lonRight)
            lonRight = location.coordinate.longitude;
        if (location.coordinate.longitude < lonLeft)
            lonLeft = location.coordinate.longitude;
        
        
        // Plus all speed entries
        avgSpeed = avgSpeed + location.speed;
    }
    
    // Divide accumulated speeds with number of entries
    avgSpeed = avgSpeed/[self.selectedRun.locations count];
    
    // Convert avg. speed from m/s to min/km
    avgSpeed = 16.66666666666667/avgSpeed;
    self.lblAvgSpeed.text = [NSString stringWithFormat:@"%.2f",avgSpeed];
    
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
    CLLocationCoordinate2D *pointsCoordinate = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * self.selectedRun.locations.count);
    
    for (int i=0; i<self.selectedRun.locations.count; i++) {
        CLLocation *location = self.selectedRun.locations[i];
        pointsCoordinate[i] = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:pointsCoordinate count:self.selectedRun.locations.count];
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
