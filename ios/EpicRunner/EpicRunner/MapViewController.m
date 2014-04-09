//
//  MapViewController.m
//  EpicRunner
//
//  Created by Jeppe on 18/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "MapViewController.h"
#import "Run.h"
#import "RunFinishedSummaryViewController.h"

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *runButton;
@property BOOL capturing;
@property Run *currentRun;
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
        
        //Change visual
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        self.runButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.60];
        self.capturing = YES;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // Update region with new location in center
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 1000, 1000);
    [self.mapView setRegion:region animated:YES];

    if (self.capturing) {
        //Should only capture with some larger interval!
        [self.currentRun.locations addObject:userLocation.location];
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
    
    self.capturing = NO;
    
    // Bind mapView delegate to this controller
    self.mapView.delegate = (id)self;
    
    // Turn on user tracking
    self.mapView.showsUserLocation = YES;
    
    // Skip to rough location, without animation (to avoid animating from USA overview)
    MKUserLocation *userLocation = self.mapView.userLocation;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 6000, 6000);
    [self.mapView setRegion:region animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
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

- (IBAction)unwindToMap:(UIStoryboardSegue *)segue
{
}

@end
