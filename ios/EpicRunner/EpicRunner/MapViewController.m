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


@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *runButton;
@property BOOL capturing;
@property Run *currentRun;
@property (nonatomic) IBOutlet UIBarButtonItem *btnMenu;

@property CLLocation *prevLoc;
@property double totalDistance;
@property double recordedDistance;
@property double coinedDistance;

@property AVAudioPlayer *avCoinSound;
@property double timeToCoin;
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // Define distances (in meters)
    double minRecordDistance = 5.0;
    double coinDistance = 50.0;
    
    // Update region with new location in center
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 1000, 1000);
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
