//
//  RunScreenViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 24/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation

class RunScreenViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet var btnMenu: UIBarButtonItem
    @IBOutlet var runButton: UIButton
    @IBOutlet var container: UIView
    @IBOutlet var lblGps: UILabel
    @IBOutlet var lblCurrentObj: UILabel
    @IBOutlet var lblTotalPossibleProgress: UILabel
    @IBOutlet var lblTotalMadeProgerss: UILabel
    
    let iosVersion = NSString(string: UIDevice.currentDevice().systemVersion).doubleValue
    var locationManager: CLLocationManager = CLLocationManager();
    var active: Bool = true;
    
    var multiplayer: Bool = false;
    var autoroute1: Bool = false;
    var onePointLocationRunDistance: Double = 0.0;
    var onePointLocationLocation: CLLocation? = nil;
    
    var capturing: Bool = false;
    var currentRun: Run? = nil;
    
    var avCoinSound: AVAudioPlayer? = nil;
    
    var prevLoc: CLLocation? = nil;
    var totalDistance: Double = 0.0;
    var recordedDistance: Double = 0.0;
    var coinedDistance: Double = 0.0;
    
    var player2timestamp: Double = 0.0;
    //var player2Annotation: MKPointAnnotation?;
    
    var autopoint1Generated: Bool = false;
    var autopoint1Annotation: MKPointAnnotation? = nil;
    var onePointLocationRunGenPointTotalTries: Int = 0;
    var onePointLocationRunGenPointTries: Int = 0;
    var onePointLocationRunGenPointAccumDist: Double = 0.0;
    var onePointLocationRunShootOutDistance: Double = 0.0;
    
    // Stuff
    var runId: Int = 0;           //Is set from other controller
    var runTypeId: Int = 0;       //Is set from other controller
    var medalBronze: Int = 0;     //Is set from other controller
    var medalSilver: Int = 0;     //Is set from other controller
    var medalGold: Int = 0;       //Is set from other controller
    var estimatedDistanceInM = 1; //Is set from other controller
    var runPointHome: CLLocationCoordinate2D? = nil; //Is set from other controller
    var runPoints: [CLLocationCoordinate2D] = [];    //Is set from other controller
    
    // Location Run
    var locRunActive: Bool = false;
    var locRunPointA: CLLocationCoordinate2D? = nil;
    var locRunPointB: CLLocationCoordinate2D? = nil;
    var locRunPointBReached: Bool = false;
    var locRunNextPointAnno: MKPointAnnotation = MKPointAnnotation();
    
    // Collector Run
    var carryingPoint: Bool = false;
    
    var runScreenContainerViewController: RunScreenContainerViewController?;
    var timerContainerUpdater: NSTimer? = nil;
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)  {
        let userLocation: CLLocation = locations[0] as CLLocation;
        let isInBackground: Bool = UIApplication.sharedApplication().applicationState == UIApplicationState.Background;
        
        if (!isInBackground) {
            switch userLocation.horizontalAccuracy {
            case let x where x <= 7:
                lblGps.text = "GPS (V)";
                lblGps.textColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1);
            case let x where x > 7 && x <= 20:
                lblGps.text = "GPS (-)";
                lblGps.textColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1);
            default:
                lblGps.text = "GPS (X)";
                lblGps.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1);
            }
        }
        
        if (self.active) {
            // Define distances (in meters)
            let minRecordDistance: Double = 5.0;
            let coinDistance: Double = 50.0;
            
            if (self.capturing) {
                // Update total distance
                if (self.prevLoc != nil) {
                    self.totalDistance += self.prevLoc!.distanceFromLocation(userLocation);
                }
                
                // Record location if last recorded distance is further than "minRecordDistance" meters from the prev data point
                if (self.totalDistance - self.recordedDistance > minRecordDistance) {
                    self.currentRun!.locations.append(userLocation);
                    self.recordedDistance += minRecordDistance;
                }
                
                // Gain coin if it is time
                if (self.totalDistance - self.coinedDistance > coinDistance) {
                    self.avCoinSound?.play();
                    self.coinedDistance += coinDistance;
                }
                
                //Update prev loc
                self.prevLoc = userLocation;
            }
        
            
            // -- Mode specific below --
            // Autoroute1
            if (self.autoroute1 && self.autopoint1Generated) {
                let acceptableDeltaDistInMeters: Double = 25;
                
                //Calc distance between current and goal point
                let startLocation: CLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude);
                let endLocation: CLLocation = CLLocation(latitude: self.autopoint1Annotation!.coordinate.latitude, longitude: self.autopoint1Annotation!.coordinate.longitude);
                let distanceToGoal: Double = startLocation.distanceFromLocation(endLocation);
                
                if (distanceToGoal < acceptableDeltaDistInMeters) {
                    println("YOU REACHED GOAL, WOOOOOHH!!");
                    if (self.capturing) {
                        endCapturing();
                    }
                }
            }
            
            
            // Specific for each run type
            if (self.runTypeId == 1) {
                // Location Run
                let acceptableDeltaDistInMeters: Double = 25;
                var progress: Float;
                
                // Update progressbar
                let multiplier: Float = Float(self.lblTotalPossibleProgress.frame.width)/Float(self.estimatedDistanceInM);
                progress = Float(self.totalDistance)*multiplier;
                
                // From point: A -> B -> A
                if (locRunPointBReached) {
                    // Point B reached, checking for Point A (GOAL)
                    let startLocation: CLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude);
                    let endLocation: CLLocation = CLLocation(latitude: self.runPointHome!.latitude, longitude: self.runPointHome!.longitude);
                    let distanceToGoal: Double = startLocation.distanceFromLocation(endLocation);
                    
                    //Calc distance between current and goal point
                    if (distanceToGoal < acceptableDeltaDistInMeters) {
                        // Final point reached, end game
                        println("Point Home reached!");
                        self.active = false;
                        self.currentRun!.aborted = false;
                        endCapturing();
                    }
                } else {
                    // Point B NOT reached, checking for Point B (checkpoint)
                    let startLocation: CLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude);
                    let endLocation: CLLocation = CLLocation(latitude: self.runPoints[0].latitude, longitude: self.runPoints[0].longitude);
                    let distanceToGoal: Double = startLocation.distanceFromLocation(endLocation);
                    
                    //Calc distance between current and point B
                    if (distanceToGoal < acceptableDeltaDistInMeters) {
                        println("Point B reached!");
                        self.locRunPointBReached = true;
                        
                        // Update map anno & Container
                        self.locRunNextPointAnno.setCoordinate(self.locRunPointA!);
                        self.runScreenContainerViewController!.locRunNextPointAnno = self.locRunNextPointAnno;
                        
                        // Update current objective
                        lblCurrentObj.text = "Run to A..";
                    }
                    
                    // Limit progressbar
                    if (Int(self.totalDistance) > self.estimatedDistanceInM/2) {
                        progress = Float(self.estimatedDistanceInM/2)*multiplier;
                    }
                    
                }
                
                self.lblTotalMadeProgerss.frame = CGRect(origin: self.lblTotalMadeProgerss.frame.origin, size: CGSize(width: progress, height: self.lblTotalMadeProgerss.frame.height));
                
                
                
            } else if (self.runTypeId == 3) {
                // Collector Run
                let acceptableDeltaDistInMeters: Double = 175;
                let startLocation: CLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude);
                
                
                if (self.carryingPoint) {
                    let endLocation: CLLocation = CLLocation(latitude: self.runPointHome!.latitude, longitude: self.runPointHome!.longitude);
                    let distanceToGoal: Double = startLocation.distanceFromLocation(endLocation);
                    
                    if (distanceToGoal < acceptableDeltaDistInMeters) {
                        if (self.runPoints.count == 0) {
                            // Final point delivered, end game
                            println("All points delivered!");
                            self.active = false;
                            self.currentRun!.aborted = false;
                            endCapturing();
                        } else {
                            // More points to collect
                            self.carryingPoint = false;
                            self.runScreenContainerViewController!.hideHomeAnno();
                            self.runScreenContainerViewController!.showPointsAnno();
                            self.lblCurrentObj.text = "Collect a new point..";
                        }
                    }
                } else {
                    var i: Int = 0;
                    for point in self.runPoints {
                        let endLocation: CLLocation = CLLocation(latitude: point.latitude, longitude: point.longitude);
                        let distanceToGoal: Double = startLocation.distanceFromLocation(endLocation);
                        if (distanceToGoal < acceptableDeltaDistInMeters) {
                            // Point collected, return to home
                            self.carryingPoint = true;
                            self.runScreenContainerViewController!.removePoint(point);
                            self.runPoints.removeAtIndex(i);
                            self.runScreenContainerViewController!.showHomeAnno();
                            self.runScreenContainerViewController!.hidePointsAnno();
                            self.lblCurrentObj.text = "Deliver the point at base..";
                        }
                        i++;
                    }
                }
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager!) {
        println("lc didPause??? Who the hell did that?!");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Init location manager
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
        self.locationManager.pausesLocationUpdatesAutomatically = false;

        if (self.iosVersion >= 8) {
            self.locationManager.requestWhenInUseAuthorization(); // Necessary for iOS 8 and crashes iOS 7... -.-
        }
        self.locationManager.startUpdatingLocation();
        
        // Always show navigationBar
        self.navigationController.setNavigationBarHidden(false, animated: false);
        super.viewWillAppear(false);
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Set title of navigationbar
        self.navigationItem.title = HelperFunctions().runHeadline[self.runTypeId];
        
        
        // Set coin sound
        //let soundURL: NSURL = NSBundle.URLForResource("213423__taira-komori__coin05", withExtension: "mp3", subdirectory: nil, inBundleWithURL: nil);
        //self.avCoinSound = AVAudioPlayer(contentsOfURL: soundURL, error: nil);
        
        

        
        
//        // Init 1-point location run
//        if (self.autoroute1) {
//            println("autoroute1 START");
//            self.autopoint1Generated = false;
//            self.autopoint1Annotation = MKPointAnnotation();
//            self.onePointLocationRunGenPointTries = 0;
//            self.onePointLocationRunGenPointTotalTries = 0;
//            self.onePointLocationRunGenPointAccumDist = 0;
//            self.onePointLocationRunShootOutDistance = self.onePointLocationRunDistance;
//            
//            if (self.onePointLocationLocation == nil) {
//                //autoroute1_generate_route();
//            } else {
//                println("Using custom location");
//                var autopoint1Annotation: MKPointAnnotation = MKPointAnnotation();
//                autopoint1Annotation.coordinate = self.onePointLocationLocation!.coordinate;
//                
//                // Draw point on map
//                self.autopoint1Annotation = autopoint1Annotation;
//                self.mapView.addAnnotation(self.autopoint1Annotation);
//                self.autopoint1Generated = true;
//            }
//        }
        
        // Location run
        if (self.runTypeId == 1) {
            println("location run START");
            
            // Draw point B on map
            self.locRunNextPointAnno.coordinate = self.locRunPointB!;
            
            // Start run
            startCapturing();
            
            // Set run-specific values
            self.currentRun!.realRunId = self.runId;
            
            // Set current objective
            lblCurrentObj.text = "Run to B..";
        } else if (self.runTypeId == 2) {
            // Interval run
            
        } else if (self.runTypeId == 3) {
            // Collector run
            
            // Start run
            startCapturing();
            
            // Set run-specific values
            self.currentRun!.realRunId = self.runId;
            
            // Set current objective
            lblCurrentObj.text = "Collect a point..";
            
        }
        
        self.timerContainerUpdater = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "tickContainer", userInfo: nil, repeats: true);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tickContainer() {
        // Updates the container view periodically
        if (self.currentRun) {
            // Update distance
            self.runScreenContainerViewController!.lblDistance.text = NSString(format: "%.2f km", self.totalDistance/1000);
            
            // Update time
            let runTimeInSeconds: NSNumber = NSDate().timeIntervalSinceDate(self.currentRun!.start);
            self.runScreenContainerViewController!.lblDuration.text = HelperFunctions().formatSecToMinSec(runTimeInSeconds.integerValue);
            
            // Update Speed
            if (self.currentRun!.locations.count > 0) {
                var speed: Double = (16.666666666667/(self.currentRun!.locations[self.currentRun!.locations.count-1].speed));
                // According to the emulator, it is very likely to be infinite sometimes.
                if (speed.isInfinite) {
                    speed = 0.0;
                }
                let speedInt: Int = Int(speed);
                let speedDec = Int((speed-Double(speedInt))*60);
                
                self.runScreenContainerViewController!.lblSpeed.text = "\(speedInt):" + NSString(format: "%.2d", speedDec);
            }
            
            // Update medal
            if (self.locRunActive) {
                if (Int(runTimeInSeconds) < self.medalGold) {
                    self.runScreenContainerViewController!.lblMedal.text = "Gold";
                } else if (Int(runTimeInSeconds) < self.medalSilver) {
                    self.runScreenContainerViewController!.lblMedal.text = "Silver";
                } else {
                    self.runScreenContainerViewController!.lblMedal.text = "Bronze";
                }
            }
        }
    }

    func startCapturing() {
        //Start a new run
        self.currentRun = Run();
        self.currentRun!.start = NSDate();
        self.prevLoc = nil;
        self.totalDistance = 0.0;
        self.recordedDistance = 0.0;
        self.coinedDistance = 0.0;
        
        //Change visual
        if (self.runTypeId == 0) {
            self.runButton.setTitle("Done", forState: .Normal);
        } else {
            self.runButton.setTitle("Abort run", forState: .Normal);
        }
        self.runButton.backgroundColor = UIColor(red: 1.0, green:0.0, blue:0.0, alpha:0.60);
        self.capturing = true;
    }
    
    func endCapturing() {
        //Stop the run
        self.currentRun!.end = NSDate();
        
        //Calculate the total distance of the run
        if (self.currentRun!.locations.count > 1) {
            for (var i:Int=0; i < self.currentRun!.locations.count-1; i++) {
                var distance: Double = self.currentRun!.locations[i].distanceFromLocation(self.currentRun!.locations[i+1]);
                self.currentRun!.distance += distance;
            }
        }
        
        //Change visual
        self.runButton.setTitle("Run", forState: .Normal);
        self.runButton.backgroundColor = UIColor(red: 0.0, green:1.0, blue:0.0, alpha:0.50);
        self.capturing = false;
        
        //Change view
        self.performSegueWithIdentifier("SegueRunFinished", sender: self);
    }
    

    @IBAction func runClicked(sender: AnyObject) {
        if (self.capturing) {
            endCapturing();
        } else {
            startCapturing();
        }
    }

    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier) {
            if (segue.identifier == "SegueRunFinished") {
                var runFinishedSummaryViewController: RunFinishedSummaryViewControllerSwift = segue.destinationViewController as RunFinishedSummaryViewControllerSwift;
                runFinishedSummaryViewController.finishedRun = self.currentRun;
            }
            if (segue.identifier == "toContainer") {
                self.runScreenContainerViewController = segue.destinationViewController as? RunScreenContainerViewController;
                updateContainer();
            }
        }
    }

    func updateContainer() {
        // General
        self.runScreenContainerViewController!.runTypeId = self.runTypeId;
        
        // Multiplayer
        if (self.multiplayer) {
            self.runScreenContainerViewController!.multiplayer = self.multiplayer;
        }
        
        // Specific for each run type
        if (self.runTypeId == 1) {
            // Location run
            self.runScreenContainerViewController!.locRunActive = self.locRunActive;
            self.runScreenContainerViewController!.locRunPointA = self.locRunPointA;
            self.runScreenContainerViewController!.locRunPointB = self.locRunPointB;
            self.runScreenContainerViewController!.locRunNextPointAnno = self.locRunNextPointAnno;
            
            self.runScreenContainerViewController!.runPointHome = self.runPointHome;
            self.runScreenContainerViewController!.runPoints = self.runPoints;
            self.runScreenContainerViewController!.medalGold = self.medalGold;
            self.runScreenContainerViewController!.medalSilver = self.medalSilver;
            self.runScreenContainerViewController!.medalBronze = self.medalBronze;
            
            
        } else if (self.runTypeId == 2) {
            // Interval run
            
        } else if (self.runTypeId == 3) {
            // Collector run
            
            self.runScreenContainerViewController!.runPointHome = self.runPointHome;
            self.runScreenContainerViewController!.runPoints = self.runPoints;
            self.runScreenContainerViewController!.medalGold = self.medalGold;
            self.runScreenContainerViewController!.medalSilver = self.medalSilver;
            self.runScreenContainerViewController!.medalBronze = self.medalBronze;
        }
    }
    
    override func viewWillDisappear(animated:Bool) {
        // Clean up
        self.timerContainerUpdater?.invalidate();
        self.timerContainerUpdater = nil;
    }
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
    }

}
