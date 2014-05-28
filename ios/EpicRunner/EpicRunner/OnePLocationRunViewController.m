//
//  1PLocationRunViewController.m
//  EpicRunner
//
//  Created by Jeppe on 14/05/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "OnePLocationRunViewController.h"
#import "MapViewController.h"

@interface OnePLocationRunViewController ()
@property (weak, nonatomic) IBOutlet UITextField *approxDistField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *LoadingIcon_endPos;
@property CLLocation *location;
@property BOOL endPostAuto;

@end

@implementation OnePLocationRunViewController
- (IBAction)startPosAutoSwitch:(id)sender {
    [sender setOn:YES animated:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not an option!"
                                                    message:@"You really don't wanna do that.."
                                                   delegate:nil
                                          cancelButtonTitle:@"I accept my faith"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)endPosAutoSwitch:(id)sender {
    BOOL state = [sender isOn];
    self.endPostAuto = state;
    
    if (state) {
        [self.LoadingIcon_endPos startAnimating];
        self.mapView.hidden = YES;
        self.approxDistField.enabled = YES;
        [self.LoadingIcon_endPos stopAnimating];
    } else {
        [self.LoadingIcon_endPos startAnimating];
        
        // Skip to location, without animation
        MKUserLocation *userLocation = self.mapView.userLocation;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 2000, 2000);
        [self.mapView setRegion:region animated:NO];
        
        self.mapView.hidden = NO;
        self.approxDistField.enabled = NO;
        [self.LoadingIcon_endPos stopAnimating];
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
    // Hide NavigationBar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:YES];
    
    // Create a gesture recognizer for long presses (for example in viewDidLoad)
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //user needs to press for half a second.
    [self.mapView addGestureRecognizer:lpgr];

    // Done button above keypad
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                           nil];
    [numberToolbar sizeToFit];
    self.approxDistField.inputAccessoryView = numberToolbar;
    
    // Init properties
    self.endPostAuto = YES;
    
    // Bind mapView delegate to this controller
    self.mapView.delegate = (id)self;
    
    // Turn on user tracking
    self.mapView.showsUserLocation = YES;
    
    // Skip to rough location, without animation (to avoid animating from USA overview)
    MKUserLocation *userLocation = self.mapView.userLocation;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 2000, 2000);
    [self.mapView setRegion:region animated:NO];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //Start loading icon
    [self.LoadingIcon_endPos startAnimating];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = touchMapCoordinate;
    for (id annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    
    
    // Get point on nearest road
    MKPlacemark *placemarkSource = [[MKPlacemark alloc] initWithCoordinate:self.mapView.userLocation.coordinate
                                                         addressDictionary:nil];
    MKMapItem *mapItemSource = [[MKMapItem alloc] initWithPlacemark:placemarkSource];
    
    MKPlacemark *placemarkDest = [[MKPlacemark alloc] initWithCoordinate:point.coordinate
                                                       addressDictionary:nil];
    MKMapItem *mapItemDest = [[MKMapItem alloc] initWithPlacemark:placemarkDest];
    
    MKDirectionsRequest *walkingRouteRequest = [[MKDirectionsRequest alloc] init];
    walkingRouteRequest.transportType = MKDirectionsTransportTypeWalking;
    [walkingRouteRequest setSource:mapItemSource];
    [walkingRouteRequest setDestination:mapItemDest];
    
    MKDirections *walkingRouteDirections = [[MKDirections alloc] initWithRequest:walkingRouteRequest];
    [walkingRouteDirections calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error) {
             //Some error happened
             NSLog(@"Error %@", error.description);
         } else {
             // Take the last MKRoute object
             MKRoute *route = response.routes.lastObject;
             NSUInteger pointCount = route.polyline.pointCount;
             
             // Allocate a C array to hold 1 points/coordinates
             CLLocationCoordinate2D *routeCoordinates = malloc(sizeof(CLLocationCoordinate2D));
             
             // Get the last coordinate of the polyline
             [route.polyline getCoordinates:routeCoordinates
                                      range:NSMakeRange(pointCount-1, 1)];
             
             // Set point on nearest road
             self.location = [[CLLocation alloc] initWithLatitude:routeCoordinates[0].latitude
                                                        longitude:routeCoordinates[0].longitude];
             point.coordinate = routeCoordinates[0];
             [self.mapView addAnnotation:point];
             
             // Set distance
             self.approxDistField.text = [NSString stringWithFormat:@"%.2f", route.distance/1000];
             
             free(routeCoordinates);
             
         }
         [self.LoadingIcon_endPos stopAnimating];
     }];
    

    
}

-(void)doneWithNumberPad{
    [self.approxDistField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([identifier isEqualToString:@"SegueStartRun"])
    {
        if (!self.endPostAuto) {
            // There should be a point chosen, otherwise abort
            if (self.location == Nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid goal"
                                                                message:@"You should pick a goal (press and hold on map)."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Got it!"
                                                      otherButtonTitles:nil];
                [alert show];
                return NO;
            }
        }
        
        if ([self.approxDistField.text doubleValue] < 0.4) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid distance"
                                                             message:@"You should enter a distance longer than 400 meters."
                                                            delegate:nil
                                                   cancelButtonTitle:@"Got it!"
                                                   otherButtonTitles:nil];
            [alert show];
            return NO;
        }
        if ([self.approxDistField.text doubleValue] > 60.0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid distance"
                                                             message:@"You should enter a distance shorter than 60 km."
                                                            delegate:nil
                                                   cancelButtonTitle:@"Got it!"
                                                   otherButtonTitles:nil];
            [alert show];
            return NO;
        }
        
    }
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"SegueStartRun"])
    {
        MapViewController *mapViewController = segue.destinationViewController;
        mapViewController.autoroute1 = true;
        mapViewController.onePointLocationRunDistance = (int)([self.approxDistField.text doubleValue]*1000);
        
        if (!self.endPostAuto) {
            mapViewController.onePointLocationLocation = self.location;
        }
        
        NSLog(@"start run");
    }
}


@end
