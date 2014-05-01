//
//  MapViewController.m
//  EpicRunner
//
//  Created by Jeppe on 18/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MapViewController.h"
#import "Run.h"
#import "RunFinishedSummaryViewController.h"
#import "CJSONDeserializer.h"


@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *runButton;
@property BOOL capturing;
@property Run *currentRun;
@property (nonatomic) IBOutlet UIBarButtonItem *btnMenu;
@property int mapZoomlevel;

@property CLLocation *prevLoc;
@property double totalDistance;
@property double recordedDistance;
@property double coinedDistance;

@property AVAudioPlayer *avCoinSound;
@property double timeToCoin;

@property double player2timestamp;
@property MKPointAnnotation *player2Annotation;
@end

@implementation MapViewController

- (IBAction)runButtonClick:(id)sender {
    if (self.capturing) {
        //Stop the run
        self.currentRun.end = [NSDate date];
        
        //Calculate the total distance of the run
        if (self.currentRun.locations.count > 1) {
            for (int i=0; i < self.currentRun.locations.count-1; i++) {
                double distance = [self.currentRun.locations[i] distanceFromLocation:self.currentRun.locations[i+1]];
                self.currentRun.distance += distance;
            }
        }
        
        //Change visual
        [sender setTitle:@"Run" forState:UIControlStateNormal];
        self.runButton.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.50];
        self.capturing = NO;
        
        //Change view
        [self performSegueWithIdentifier: @"SegueRunFinished" sender: self];
    } else {
        //Start a new run
        self.currentRun = [[Run alloc] init];
        self.currentRun.start = [NSDate date];
        self.prevLoc = nil;
        self.totalDistance = 0.0;
        self.recordedDistance = 0.0;
        self.coinedDistance = 0.0;
        
        //Change visual
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        self.runButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.60];
        self.capturing = YES;
    }
}
- (IBAction)plusZoom:(id)sender {
    if (self.mapZoomlevel > 500)
        self.mapZoomlevel -= 500;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
                                                                   self.mapZoomlevel,
                                                                   self.mapZoomlevel);
    [self.mapView setRegion:region animated:YES];
}
- (IBAction)minusZoom:(id)sender {
    self.mapZoomlevel += 500;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
                                                                   self.mapZoomlevel,
                                                                   self.mapZoomlevel);
    [self.mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
    
    // Define distances (in meters)
    double minRecordDistance = 5.0;
    double coinDistance = 50.0;
    
    // Update region with new location in center
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate,
                                                                   self.mapZoomlevel,
                                                                   self.mapZoomlevel);
    [self.mapView setRegion:region animated:YES];

    if (self.capturing) {
        // Update total distance
        if (self.prevLoc != nil)
            self.totalDistance += [self.prevLoc distanceFromLocation:userLocation.location];
        
        
        // Record location if last recorded distance is further than "minRecordDistance" meters from the prev data point
        if (self.totalDistance - self.recordedDistance > minRecordDistance) {
            [self.currentRun.locations addObject:userLocation.location];
            self.recordedDistance += minRecordDistance;
        }
        
        
        // Gain coin if it is time
        if (self.totalDistance - self.coinedDistance > coinDistance) {
            [self.avCoinSound play];
            self.coinedDistance += coinDistance;
        }
        
        //Update prev loc
        self.prevLoc = userLocation.location;
    }
    
    
    // Update Player 2 location
    if (self.multiplayer){
        double timeNowInS = [[NSDate date] timeIntervalSince1970];
        if (timeNowInS - self.player2timestamp > 3) {
            self.player2timestamp = timeNowInS;
            
            NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
            
            NSURL * url = [NSURL URLWithString:@"http://marci.dk/epicrunner/locping.php"];
            NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
            NSString * params = ([NSString stringWithFormat:@"lat=%f&lon=%f", userLocation.location.coordinate.latitude,
                                                                              userLocation.location.coordinate.longitude]);
            [urlRequest setHTTPMethod:@"POST"];
            [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                   //NSLog(@"Response:%@ %@\n", response, error);
                   if(error == nil)
                   {
                       //NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                       //NSLog(@"Data = %@",text);
                       
                       NSError *error = nil;
                       NSDictionary *dic = [[CJSONDeserializer deserializer] deserializeAsDictionary:data error:&error];
                       
                       double player2lat = [[dic objectForKey:@"lat"] doubleValue];
                       double player2lon = [[dic objectForKey:@"lon"] doubleValue];
                       
                       CLLocationCoordinate2D p2 = {player2lat, player2lon};
                       self.player2Annotation.coordinate = p2;
                   }
               }];
            [dataTask resume];
        }
    }
}


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
    //self.mainDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //NSLog(self.mainDelegate.myTest);
    
    // Bind menu button
    [self.btnMenu setTarget: self.revealViewController];
    [self.btnMenu setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
    // Do not capture/record data
    self.capturing = NO;
    
    // Bind mapView delegate to this controller
    self.mapView.delegate = (id)self;
    
    // Set default zoom level
    self.mapZoomlevel = 1000;
    
    // Turn on user tracking
    self.mapView.showsUserLocation = YES;
    
    // Skip to rough location, without animation (to avoid animating from USA overview)
    MKUserLocation *userLocation = self.mapView.userLocation;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 6000, 6000);
    [self.mapView setRegion:region animated:NO];
    
    // Set coin sound
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"213423__taira-komori__coin05"
                                              withExtension:@"mp3"];
    self.avCoinSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    
    // Init multiplayer (/second player)
    if(self.multiplayer) {
        self.player2timestamp = 0;
        self.player2Annotation = [[MKPointAnnotation alloc] init];
        [self.mapView addAnnotation: self.player2Annotation];
    }
    
    // Init 1-point auto route
    if (self.autoroute1) {
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = [self coordinateFromCoord:self.mapView.userLocation.coordinate atDistanceKm:1 atBearingDegrees:90.0];
        [self.mapView addAnnotation: point];
        
//        MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
//        [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
//        [directionsRequest setDestination:[[MKMapItem alloc] init]];
//        directionsRequest.transportType = MKDirectionsTransportTypeAutomobile;
//        MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
//        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
//            if (error) {
//                NSLog(@"Error %@", error.description);
//            } else {
//                routeDetails = response.routes.lastObject;
//                [self.mapView addOverlay:routeDetails.polyline];
//                self.destinationLabel.text = [placemark.addressDictionary objectForKey:@"Street"];
//                self.distanceLabel.text = [NSString stringWithFormat:@"%0.1f Miles", routeDetails.distance/1609.344];
//                self.transportLabel.text = [NSString stringWithFormat:@"%u" ,routeDetails.transportType];
//                self.allSteps = @"";
//                for (int i = 0; i < routeDetails.steps.count; i++) {
//                    MKRouteStep *step = [routeDetails.steps objectAtIndex:i];
//                    NSString *newStep = step.instructions;
//                    self.allSteps = [self.allSteps stringByAppendingString:newStep];
//                    self.allSteps = [self.allSteps stringByAppendingString:@"\n\n"];
//                    self.steps.text = self.allSteps;
//                }
//            }
//        }];
        
        
//        
//        MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
//        
//        request.source = [MKMapItem mapItemForCurrentLocation];
//        request.destination = [self coordinateFromCoord:[MKMapItem mapItemForCurrentLocation] atDistanceKm:3 atBearingDegrees:90.0];
//        
//        request.requestsAlternateRoutes = YES;
//        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
//        
//        [directions calculateDirectionsWithCompletionHandler:
//         ^(MKDirectionsResponse *response, NSError *error) {
//             if (error) {
//                 // Handle Error
//             } else {
//                 [self showRoute:response];
//             }
//         }];
    }
}

-(void)showRoute:(MKDirectionsResponse *)response
{
    for (MKRoute *route in response.routes)
    {
        [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer =
    [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 5.0;
    return renderer;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"SegueRunFinished"])
    {
        RunFinishedSummaryViewController *runFinishedSummaryViewController = segue.destinationViewController;
        runFinishedSummaryViewController.finishedRun = self.currentRun;
    }
    
}

-(MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If you are showing the users location on the map you don't want to change it
    MKAnnotationView *view = nil;
    if (annotation != mapView.userLocation) {
        // This is not the users location indicator (the blue dot)
        view = [mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotationIdentifier"];
        if (!view) {
            // Could not reuse a view ...
            
            // Creating a new annotation view
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotationIdentifier"];
            
            // This will rescale the annotation view to fit the image
            view.image = [UIImage imageNamed:@"player2_dot"];
        }
    }
    return view;
}

- (double)radiansFromDegrees:(double)degrees
{
    return degrees * (M_PI/180.0);
}

- (double)degreesFromRadians:(double)radians
{
    return radians * (180.0/M_PI);
}

- (CLLocationCoordinate2D)coordinateFromCoord:(CLLocationCoordinate2D)fromCoord
                                 atDistanceKm:(double)distanceKm
                             atBearingDegrees:(double)bearingDegrees
{
    double distanceRadians = distanceKm / 6371.0;
    //6,371 = Earth's radius in km
    double bearingRadians = [self radiansFromDegrees:bearingDegrees];
    double fromLatRadians = [self radiansFromDegrees:fromCoord.latitude];
    double fromLonRadians = [self radiansFromDegrees:fromCoord.longitude];
    
    double toLatRadians = asin( sin(fromLatRadians) * cos(distanceRadians)
                              + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
    
    double toLonRadians = fromLonRadians + atan2(sin(bearingRadians)
                                                 * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
                                                 - sin(fromLatRadians) * sin(toLatRadians));
    
    // adjust toLonRadians to be in the range -180 to +180...
    toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
    
    CLLocationCoordinate2D result;
    result.latitude = [self degreesFromRadians:toLatRadians];
    result.longitude = [self degreesFromRadians:toLonRadians];
    return result;
}

- (IBAction)unwindToMap:(UIStoryboardSegue *)segue
{
}

@end
