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
    @IBOutlet var btnMenu: UIBarButtonItem!;
    @IBOutlet var btnRun: UIButton!;
    @IBOutlet var container: UIView!;
    @IBOutlet var lblCurrentObj: UILabel!;
    @IBOutlet var lblTotalPossibleProgress: UILabel!;
    @IBOutlet weak var btnTotalMadeProgress: UIButton!;
    @IBOutlet var btnGps: UIButton!;;
    @IBOutlet weak var btnChallenge: UIButton!;
    @IBOutlet weak var btnShare: UIButton!;
    @IBOutlet weak var btnEnd: UIButton!;
    @IBOutlet weak var btnLock: UIButton!;
    
    let iosVersion = NSString(string: UIDevice.currentDevice().systemVersion).doubleValue;
    var locationManager: CLLocationManager = CLLocationManager();
    let db = SQLiteDB.sharedInstance();
    var active: Bool = true;
    
    var multiplayer: Bool = false;
    var autoroute1: Bool = false;
    var onePointLocationRunDistance: Double = 0.0;
    var onePointLocationLocation: CLLocation? = nil;
    
    var capturing: Bool = false;
    var currentRun: Run? = nil;
    var run_locations: String = "";
    var synchronized: Bool = false;
    
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
    var modals: [UIViewController] = [];
    var handlePanBlock: UIPanGestureRecognizer? = nil;
    
    // Lock
    var locked: Bool = false;
    var lockOverlayBlocker: UIButton? = nil;
    var lockOverlaySlide: UIButton? = nil;
    var lockOverlaySlideText: UIButton? = nil;
    var currentLocX: CGFloat = 0.0;
    
    // Location Run
    var locRunActive: Bool = false;
    var locRunPointA: CLLocationCoordinate2D? = nil;
    var locRunPointB: CLLocationCoordinate2D? = nil;
    var locRunPointBReached: Bool = false;
    var locRunNextPointAnno: MKPointAnnotation = MKPointAnnotation();
    
    // Collector Run
    var carryingPoint: Bool = false;
    var totalNumOfPoints: Int = 1;

    var runScreenContainerViewController: RunScreenContainerViewController?;
    var timerContainerUpdater: NSTimer? = nil;
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)  {
        let userLocation: CLLocation = locations[0] as CLLocation;
        let isInBackground: Bool = UIApplication.sharedApplication().applicationState == UIApplicationState.Background;
        
        if (!isInBackground) {
            switch userLocation.horizontalAccuracy {
            case let x where x <= 7:
                btnGps.setTitle("GPS (V)", forState: UIControlState.Normal);
                btnGps.setTitleColor(UIColor(red: 0, green: 1, blue: 0, alpha: 1), forState: UIControlState.Normal);
            case let x where x > 7 && x <= 20:
                btnGps.setTitle("GPS (-)", forState: UIControlState.Normal);
                btnGps.setTitleColor(UIColor(red: 1, green: 1, blue: 0, alpha: 1), forState: UIControlState.Normal);
            default:
                btnGps.setTitle("GPS (X)", forState: UIControlState.Normal);
                btnGps.setTitleColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1), forState: UIControlState.Normal);
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
                
                UIView.animateWithDuration(0.5,
                    delay: 0.0,
                    options: .CurveLinear,
                    animations: { _ in
                        self.btnTotalMadeProgress.frame = CGRect(origin: self.btnTotalMadeProgress.frame.origin, size: CGSize(width: CGFloat(progress), height: self.btnTotalMadeProgress.frame.height));
                    },
                    completion: { _ in ()}
                );
                
                
                
            } else if (self.runTypeId == 3) {
                // Collector Run
                let acceptableDeltaDistInMeters: Double = 25;
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
                            addProgressToProgressBar(1/CGFloat(self.totalNumOfPoints*2));
                        } else {
                            // More points to collect
                            self.carryingPoint = false;
                            self.runScreenContainerViewController!.hideHomeAnno();
                            self.runScreenContainerViewController!.showPointsAnno();
                            self.lblCurrentObj.text = "Collect a new point..";
                            addProgressToProgressBar(1/CGFloat(self.totalNumOfPoints*2));
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
                            addProgressToProgressBar(1/CGFloat(self.totalNumOfPoints*2));
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
        self.navigationController!.setNavigationBarHidden(false, animated: false);
        super.viewWillAppear(false);
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
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
        
        
        // For Each Run Type
        if (self.runTypeId == 1) {
            // Location run
            
            // Draw progress labels
            addProgressLabel("A", offsetProcent: 0);
            addProgressLabel("B", offsetProcent: 0.5);
            addProgressLabel("A", offsetProcent: 1);
            
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
            self.totalNumOfPoints = self.runPoints.count;
            
            // Draw progress labels
            let numOfPoints: CGFloat = CGFloat(self.totalNumOfPoints*2);
            addProgressLabel("A", offsetProcent: 0);
            for (var i:Int=1; i<=runPoints.count; i++) {
                addProgressLabel(String(i), offsetProcent: 1/numOfPoints*CGFloat(i*2-1));
                addProgressLabel("A", offsetProcent: 1/numOfPoints*CGFloat(i*2));
            }
            
            // Start run
            startCapturing();
            
            // Set run-specific values
            self.currentRun!.realRunId = self.runId;
            
            // Set current objective
            lblCurrentObj.text = "Collect a point..";
            
        }
        
        
        // Register long press
        var longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:");
        longPress.minimumPressDuration = 0.1;
        self.btnLock.addGestureRecognizer(longPress);
        
        
        self.timerContainerUpdater = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "tickContainer", userInfo: nil, repeats: true);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addProgressLabel(text: String, offsetProcent: CGFloat) {
        var offsetX = self.btnTotalMadeProgress.frame.origin.x - 5 + (offsetProcent * self.lblTotalPossibleProgress.frame.size.width);
        
        // "Snap" to edges
        if (offsetX < self.lblTotalPossibleProgress.frame.origin.x) {
            offsetX = self.lblTotalPossibleProgress.frame.origin.x;
        }
        if (offsetX > self.lblTotalPossibleProgress.frame.origin.x+self.lblTotalPossibleProgress.frame.size.width-10) {
            offsetX = self.lblTotalPossibleProgress.frame.origin.x+self.lblTotalPossibleProgress.frame.size.width-10;
        }
        
        let lbl = UILabel(frame: CGRectMake(offsetX, self.btnTotalMadeProgress.frame.origin.y-18, 10, 18));
        lbl.font = UIFont.systemFontOfSize(12.0);
        lbl.textAlignment = NSTextAlignment.Center;
        lbl.text = text;
        self.view.addSubview(lbl);
    }
    
    func addProgressToProgressBar(procent: CGFloat) {
        var newWidth: CGFloat = self.btnTotalMadeProgress.frame.size.width + self.lblTotalPossibleProgress.frame.width * procent;
        if (newWidth > self.lblTotalPossibleProgress.frame.width) {
            newWidth = self.lblTotalPossibleProgress.frame.width;
        }
        
        UIView.animateWithDuration(0.5,
            delay: 0.0,
            options: .CurveLinear,
            animations: { _ in
                self.btnTotalMadeProgress.frame = CGRect(origin: self.btnTotalMadeProgress.frame.origin,
                                                           size: CGSize(width: newWidth,
                                                                       height: self.btnTotalMadeProgress.frame.height));
            },
            completion: { _ in ()}
        );
    }
    
    func tickContainer() {
        // Updates the container view periodically
        if (self.currentRun != nil) {
            // Update distance
            self.runScreenContainerViewController!.lblDistance.text = NSString(format: "%.2f km", self.totalDistance/1000);
            
            // Update time
            let runTimeInSeconds: NSNumber = NSDate().timeIntervalSinceDate(self.currentRun!.start!);
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
            self.btnRun.setTitle("Done", forState: .Normal);
        } else {
            self.btnRun.setTitle("Abort run", forState: .Normal);
        }
        self.btnRun.backgroundColor = UIColor(red: 1.0, green:0.0, blue:0.0, alpha:1.0);
        self.capturing = true;
        
        self.btnMenu.target = self;
        self.btnMenu.action = "menuBlocked";
        self.navigationController!.navigationBar.removeGestureRecognizer(self.revealViewController().panGestureRecognizer());
        self.handlePanBlock = UIPanGestureRecognizer(target: self, action: "handlePanBlock:");
        self.navigationController!.navigationBar.addGestureRecognizer(self.handlePanBlock!);
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
        self.btnRun.setTitle("Run", forState: .Normal);
        self.btnRun.backgroundColor = UIColor(red: 0.0, green:1.0, blue:0.0, alpha:0.50);
        self.capturing = false;
        
        
        // * Stop timer
        self.timerContainerUpdater?.invalidate();
        
        // * Change title
        if (currentRun!.aborted) {
            lblCurrentObj.text = "Run aborted";
        } else {
            lblCurrentObj.text = "Run completed";
        }
        lblCurrentObj.font = UIFont.systemFontOfSize(25.0);
        
        // * Change buttons
        btnRun.hidden = true;
        btnChallenge.hidden = false;
        btnShare.hidden = false;
        btnEnd.hidden = false;
        btnLock.hidden = true;
        
        // * Save run in db
        saveRunInDb();
        
        // * Update container
        self.runScreenContainerViewController!.runFinished(self.currentRun!);
        
        // * Upload run
        uploadRun();
        
        // * Show relevant modals
        if (!self.currentRun!.aborted) {
            let modalMedal = self.storyboard?.instantiateViewControllerWithIdentifier("modalMedal") as modalMedalViewController;
            modalMedal.runTimeInSeconds = self.currentRun!.end!.timeIntervalSinceDate(self.currentRun!.start!);
            if (Int(modalMedal.runTimeInSeconds) < self.medalGold) {
                modalMedal.wonMedal = 1;
            } else if (Int(modalMedal.runTimeInSeconds) < self.medalSilver) {
                modalMedal.wonMedal = 2;
            } else if (Int(modalMedal.runTimeInSeconds) < self.medalBronze || self.medalBronze == 0) {
                modalMedal.wonMedal = 3;
            }
            modalMedal.runTimeInSeconds = self.currentRun!.end!.timeIntervalSinceDate(self.currentRun!.start!);
            self.modals.append(modalMedal);
        }
        
        // Add more modals to queue
        //let modalLeague = self.storyboard?.instantiateViewControllerWithIdentifier("modalLeague") as UIViewController;
        //self.modals.append(modalLeague);
        
        // Activate first modal
        if (self.modals.count > 0) {
            self.addChildViewController(self.modals[0]);
            self.view.addSubview(self.modals[0].view);
            self.navigationController?.navigationBar.hidden = true;
        }
        
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";
        self.navigationController!.navigationBar.removeGestureRecognizer(self.handlePanBlock!);
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
    }
    
    func saveRunInDb() {
        // realRunId = nil if "Free run", format to db null/int
        var realRunIdDbFormat:String = "null";
        if (currentRun?.realRunId != nil) {
            realRunIdDbFormat = String(self.currentRun!.realRunId!);
            // Get and set runTypeId from db
            let realRunIdQuery = db.query("SELECT runTypeId FROM active_runs WHERE runId = \(currentRun!.realRunId!)");
            self.currentRun!.runTypeId = realRunIdQuery[0]["runTypeId"]!.asInt();
        }
        
        // Save run to database
        db.execute("INSERT INTO runs (userId, realRunId, startDate, endDate, distance, runTypeId, aborted) VALUES((SELECT loggedInUserId FROM Settings),\(realRunIdDbFormat),\(Int(currentRun!.start!.timeIntervalSince1970)),\(Int(currentRun!.end!.timeIntervalSince1970)),\(currentRun!.distance),\(currentRun!.runTypeId),\(Int(currentRun!.aborted)))");
        self.runId = Int(self.db.lastInsertedRowID());
        
        // Save all logged locations
        for loc in currentRun!.locations {
            self.db.execute("INSERT INTO runs_location (latitude, runId, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed, timestamp) VALUES(\(loc.coordinate.latitude),\(runId),\(loc.coordinate.longitude),\(loc.horizontalAccuracy),\(loc.altitude),\(loc.verticalAccuracy),\(loc.speed),\(Int(loc.timestamp.timeIntervalSince1970)))");
            run_locations += "&la[]=\(loc.coordinate.latitude)&lo[]=\(loc.coordinate.longitude)&ho[]=\(loc.horizontalAccuracy)&ve[]=\(loc.verticalAccuracy)&al[]=\(loc.altitude)&sp[]=\(loc.speed)&ti[]=\(Int(loc.timestamp.timeIntervalSince1970))";
        
            
            //Find extreme coordinates
            if (loc.coordinate.latitude > self.runScreenContainerViewController!.latTop) {
                self.runScreenContainerViewController!.latTop = loc.coordinate.latitude;
            }
            if (loc.coordinate.latitude < self.runScreenContainerViewController!.latBottom) {
                self.runScreenContainerViewController!.latBottom = loc.coordinate.latitude;
            }
            
            if (loc.coordinate.longitude > self.runScreenContainerViewController!.lonRight) {
                self.runScreenContainerViewController!.lonRight = loc.coordinate.longitude;
            }
            if (loc.coordinate.longitude < self.runScreenContainerViewController!.lonLeft) {
                self.runScreenContainerViewController!.lonLeft = loc.coordinate.longitude;
            }
            
            
            // Plus all speed entries
            self.runScreenContainerViewController!.avgSpeed = self.runScreenContainerViewController!.avgSpeed + loc.speed;
            
            
            // Find min and max altitude
            if (loc.altitude < self.runScreenContainerViewController!.minAltitude) {
                self.runScreenContainerViewController!.minAltitude = loc.altitude;
            }
            if (loc.altitude > self.runScreenContainerViewController!.maxAltitude) {
                self.runScreenContainerViewController!.maxAltitude = loc.altitude;
            }
        }
        
        // Divide accumulated speeds with number of entries
        self.runScreenContainerViewController!.avgSpeed = self.runScreenContainerViewController!.avgSpeed/Double(self.currentRun!.locations.count);
        
        // Convert avg. speed from m/s to min/km
        self.runScreenContainerViewController!.avgSpeed = 16.66666666666667/self.runScreenContainerViewController!.avgSpeed;
        
        // Update db with more info
        let runTimeInSeconds: NSNumber = self.currentRun!.end!.timeIntervalSinceDate(self.currentRun!.start!);
        self.db.execute("UPDATE runs SET duration=\(runTimeInSeconds), avgSpeed=\(self.runScreenContainerViewController!.avgSpeed), maxSpeed=0, minAltitude=\(self.runScreenContainerViewController!.minAltitude), maxAltitude=\(self.runScreenContainerViewController!.maxAltitude) WHERE id=\(self.runId)");
    }
    
    func uploadRun() {
        func callbackSuccess(data: AnyObject) {
            println("Upload successful");
            
            // Update realRunId, synced
            let dic: NSDictionary = data as NSDictionary;
            let realRunId: Int = dic.objectForKey("posted_id")!.integerValue;
            self.db.execute("UPDATE Runs SET realRunId=\(realRunId), synced=1 WHERE id=\(self.runId)");
            
            // Remove from active_runs (run selector) IF NOT free run AND Locked
            if (self.currentRun!.realRunId != nil) {
                self.db.execute("DELETE FROM active_runs WHERE locked=1 AND runId=\(self.currentRun!.realRunId!)");
            }
            
            // Done
            btnGps.hidden = true;
            self.synchronized = true;
        }
        
        func callbackError(err: String) {
            println(err);
            btnGps.titleLabel!.font = UIFont.systemFontOfSize(9.0);
            btnGps.setTitle("Sync failed", forState: UIControlState.Normal);
            btnGps.setTitleColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1), forState: UIControlState.Normal);
            self.synchronized = true;
        }
        
        btnGps.titleLabel!.font = UIFont.systemFontOfSize(9.0);
        btnGps.setTitle("Sync'ing", forState: UIControlState.Normal);
        btnGps.setTitleColor(UIColor(red: 0, green: 0, blue: 0, alpha: 1), forState: UIControlState.Normal);
        
        let runDataQuery = self.db.query("SELECT s.loggedInUserId, r.realRunId, r.distance, r.duration, r.avgSpeed, r.maxSpeed, r.minAltitude, r.maxAltitude FROM Settings s, Runs r WHERE r.id=\(self.runId)");
        let userId: Int = runDataQuery[0]["loggedInUserId"]!.asInt();
        let realRunId: Int = runDataQuery[0]["realRunId"]!.asInt();
        let distance: Double = runDataQuery[0]["distance"]!.asDouble();
        let duration: Double = runDataQuery[0]["duration"]!.asDouble();
        let avgSpeed: Double = runDataQuery[0]["avgSpeed"]!.asDouble();
        let maxSpeed: Double = runDataQuery[0]["maxSpeed"]!.asDouble();
        let minAltitude: Double = runDataQuery[0]["minAltitude"]!.asDouble();
        let maxAltitude: Double = runDataQuery[0]["maxAltitude"]!.asDouble();
        
        
        var params: String = "user_id=\(userId)&max_speed=\(maxSpeed)&min_altitude=\(minAltitude)&max_altitude=\(maxAltitude)&avg_speed=\(avgSpeed)&distance=\(distance)&duration=\(duration)\(run_locations)";
        var webService: String = "post-free-run";
        if (self.currentRun!.runTypeId != 0) {
            webService = "post-run";
            params = "run_id=\(realRunId)&" + params;
        }
        HelperFunctions().callWebService(webService, params: params, callbackSuccess: callbackSuccess, callbackFail: callbackError);
    }
    
    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier != nil) {
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
    
    override func shouldPerformSegueWithIdentifier(identifier: String!, sender: AnyObject!) -> Bool {
        if (identifier == "SegueToMain") {
            if (self.synchronized == false) {
                var alert: UIAlertView = UIAlertView();
                alert.title = "Easy there cowboy!";
                alert.message = "We havn't uploaded the run to our servers yet, please wait a second.";
                alert.addButtonWithTitle("I understand");
                
                alert.show();
                return false;
            }
        }
        return true;
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
    
    func nextModal() {
        // Remove modal
        self.modals[0].view.removeFromSuperview();
        self.modals[0].removeFromParentViewController();
        self.modals.removeAtIndex(0);
        
        if (self.modals.count > 0) {
            // If there are more modals in the list show the next in line
            self.addChildViewController(self.modals[0]);
            self.view.addSubview(self.modals[0].view);
        } else {
            // We are done, show nav bar again
            self.navigationController?.navigationBar.hidden = false;
        }
    }
    
    func menuBlocked() {
        if (!self.locked) {
            var alert: UIAlertView = UIAlertView();
            alert.title = "I'm sorry Dave";
            alert.message = "You have to end the current run to navigate away.";
            alert.addButtonWithTitle("Okay");
            
            alert.show();
        }
    }
    
    func handlePanBlock(recognizer:UIPanGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            menuBlocked();
        }
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if (self.locked) {
            let point: CGPoint = recognizer.locationInView(self.view);
            var toUnlock: Bool = false;
            
            // Check for dropzone
            if (self.btnLock.frame.origin.x >= 263) {
                //Unlock
                toUnlock = true
                self.customUnlock();
            } else {
                toUnlock = false;
            }
            
            switch recognizer.state {
            case UIGestureRecognizerState.Changed:
                if (!toUnlock) {
                    // Move to touched position
                    self.btnLock.center.x += point.x - self.currentLocX;
                }

            case UIGestureRecognizerState.Ended:
                if (self.locked && !toUnlock) {
                    //Restore pos
                    UIView.animateWithDuration(0.5,
                        delay: 0.1,
                        options: .CurveEaseOut,
                        animations: { _ in
                            self.btnLock.frame.origin.x = 30.0;
                        },
                        completion: { _ in
                    });
                }
                
                
            default:
                ();
            }
                
            self.currentLocX = point.x;
        }
    }
    
    func customLock() {
        // Lock
        self.locked = true;
        
        self.btnMenu.target = nil;
        self.btnMenu.action = nil;
        self.navigationController!.navigationBar.removeGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        self.lockOverlayBlocker = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height-55));
        lockOverlayBlocker!.backgroundColor = UIColor(white: 0, alpha: 0.06);
        self.view.addSubview(lockOverlayBlocker!);
        
        self.lockOverlaySlide = UIButton(frame: CGRect(x: 0, y: self.view.frame.size.height-55, width: self.view.frame.size.width, height: 55));
        lockOverlaySlide!.backgroundColor = UIColor(white: 0, alpha: 0.2);
        self.view.addSubview(lockOverlaySlide!);
        
        self.lockOverlaySlideText = UIButton(frame: CGRect(x: self.view.frame.size.width/2-75, y: self.view.frame.size.height-37, width: 150, height: 20));
        lockOverlaySlideText!.titleLabel?.textColor = UIColor(white: 0.5, alpha: 0);
        lockOverlaySlideText!.titleLabel?.textAlignment = NSTextAlignment.Center;
        lockOverlaySlideText!.setTitle("Slide to unlock", forState: UIControlState.Normal);
        self.view.addSubview(lockOverlaySlideText!);
        
        self.view.bringSubviewToFront(self.btnLock);
        
        //Ani to left
        UIView.animateWithDuration(0.5,
            delay: 0.0,
            options: .CurveLinear,
            animations: { _ in
                self.btnLock.frame.origin.x = 30;
                self.lockOverlaySlide!.backgroundColor = UIColor(white: 0, alpha: 0.8);
                self.lockOverlaySlideText!.titleLabel?.textColor = UIColor(white: 0.5, alpha: 0.5);
            },
            completion: { _ in ()}
        );
    }
    
    func customUnlock() {
        // Unlock
        self.locked = false;
        //self.toUnlock = false
        
        //Ani to right
        UIView.animateWithDuration(0.5,
            delay: 0.0,
            options: .CurveLinear,
            animations: { _ in
                self.btnLock.frame.origin.x = 263;
                self.lockOverlaySlide!.backgroundColor = UIColor(white: 0, alpha: 0);
                self.lockOverlaySlideText!.titleLabel?.textColor = UIColor(white: 0.5, alpha: 0);
            },
            completion: { _ in
                self.lockOverlayBlocker?.removeFromSuperview();
                self.lockOverlaySlide?.removeFromSuperview();
                self.lockOverlaySlideText?.removeFromSuperview();
                
                self.btnMenu.target = self;
                self.btnMenu.action = "menuBlocked";
                self.navigationController!.navigationBar.removeGestureRecognizer(self.revealViewController().panGestureRecognizer());
                self.handlePanBlock = UIPanGestureRecognizer(target: self, action: "handlePanBlock:");
                self.navigationController!.navigationBar.addGestureRecognizer(self.handlePanBlock!);
            }
        );
    }
    
    override func viewWillDisappear(animated:Bool) {
        // Clean up
        self.timerContainerUpdater?.invalidate();
        self.timerContainerUpdater = nil;
        self.locationManager.stopUpdatingLocation();
    }
    
    @IBAction func runClicked(sender: AnyObject) {
        if (self.capturing) {
            endCapturing();
        } else {
            startCapturing();
        }
    }
    
    @IBAction func btnGpsTouch(sender: AnyObject) {
        // Show pop up containing relevant info
        if (self.active) {
            var alert: UIAlertView = UIAlertView();
            alert.title = "GPS indicator";
            switch btnGps.titleLabel!.textColor {
            case UIColor(red: 0, green: 1, blue: 0, alpha: 1):
                alert.message = "GPS Signal is strong and you will recieve the full experience. (x-ym)"
            case UIColor(red: 1, green: 1, blue: 0, alpha: 1):
                alert.message = "GPS Signal is mediocre. The app will work but may be imprecise, which may affect the experience. You could try to move away from tall buildings. (x-ym)"
            default:
                alert.message = "No GPS Signal. You will have to get better reception for the app to work. You could try to move away from tall buildings. (x-ym)"
            }
        
            alert.addButtonWithTitle("Ok");
            alert.show();
        }
    }
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
    }
    
    @IBAction func btnLockClicked(sender: AnyObject) {
        if (!self.locked) {
            self.customLock();
        }
    }
    
    @IBAction func btnEnd(sender: AnyObject) {
        println("end");
        self.performSegueWithIdentifier("SegueToMain", sender: self);
    }
    
    @IBAction func btnShare(sender: AnyObject) {
        println("share");
    }
    
    @IBAction func btnChallenge(sender: AnyObject) {
        println("challenge");
    }
}
