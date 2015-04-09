//
//  GenerateRunViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 10/10/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit

class GenerateRunViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate {
    let screenName = "generateRun";
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnReady: UIButton!;
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!;
    
    let iosVersion = NSString(string: UIDevice.currentDevice().systemVersion).doubleValue;
    var locationManager: CLLocationManager = CLLocationManager();
    let db = SQLiteDB.sharedInstance();
    var btnReadyWorking: Bool = false;
    var countDownCounter: Int = 5;
    var countDownTimer: NSTimer? = nil;
    
    var runId: Int = 0;              //Is set from other controller
    var runTypeId: Int = 0;          //Is set from other controller
    var medalBronze: Int = 0;        //Is set from other controller
    var medalSilver: Int = 0;        //Is set from other controller
    var medalGold: Int = 0;          //Is set from other controller
    var estimatedDistance: Int = 1;
    
    var totalNeededPoints: Int = 0;
    var distancePerPoint: [Double] = [];
    
    // Location Run
    var locRunPointA: CLLocationCoordinate2D? = nil;
    var locRunPointB: CLLocationCoordinate2D? = nil;
    var locRunDistance: Double = 0.0; //Is set from other controller
    var locRunGenPointTotalTries: Int = 0;
    var locRunGenPointTries: Int = 0;
    var locRunGenPointAccumDist: Double = 0.0;
    var locRunShootOutDistance: Double = 0.0;
    
    // Collector Run
    var runPointHome: CLLocationCoordinate2D? = nil;
    var runPoints: [CLLocationCoordinate2D] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init location manager
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
        self.locationManager.pausesLocationUpdatesAutomatically = false;
        
        if (self.iosVersion >= 8) {
            self.locationManager.requestWhenInUseAuthorization(); // Necessary for iOS 8 and crashes iOS 7...
        }
        self.locationManager.startUpdatingLocation();
        self.mapView.showsUserLocation = true;
        
        //Center to location when available
        showLocWhenAvailable();
    }

    func showLocWhenAvailable() {
        if (self.locationManager.location != nil) {
            let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate,
                2500, 2500);
            self.mapView.setRegion(region, animated:true);
        } else {
            NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "showLocWhenAvailable", userInfo: nil, repeats: false);
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnReadyTouchUp(sender: AnyObject) {
        if (self.btnReadyWorking == false) {
            if (self.btnReady.titleLabel!.text == "Run now") {
                // RUN NOW
                let pU = CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude);
                let pA = CLLocation(latitude: self.locRunPointA!.latitude, longitude: self.locRunPointA!.longitude);
                if (pU.distanceFromLocation(pA) >= 50.0) {
                    // Get back to starting location!
                    var alert: UIAlertView = UIAlertView()
                    alert.title = "Get back!"
                    alert.message = "You have moved too far away from your chosen start location. Move back to start the run."
                    alert.addButtonWithTitle("Ok")
                    alert.show()
                } else {
                    // START
                    self.btnReadyWorking = true;
                    self.countDownTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "countDown", userInfo: nil, repeats: true);
                }
            } else if (self.btnReady.titleLabel!.text == "Ready"){
                // READY
                var alert: UIAlertView = UIAlertView();
                alert.title = "Be aware!";
                alert.message = "Your current location will be the start location of the run, this cannot be changed.";
                alert.addButtonWithTitle("Ok");
                alert.addButtonWithTitle("Cancel");
                alert.delegate = self;
                alert.show();
            } else {
                // TRY AGAIN
                self.locRunGenPointTotalTries = 0;
                preGenerateRoute(false);
            }
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex:NSInteger) {
        if (buttonIndex == 0)
        {
            // Ok
            preGenerateRoute(true);
        }
        else if(buttonIndex == 1)
        {
            // Cancel
        }
    }
    
    func preGenerateRoute(firstTime: Bool) {
        // Loading state
        self.btnReadyWorking = true;
        self.btnReady.setTitle("Preparing your run..", forState: UIControlState.Normal);
        self.btnReady.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0);
        self.loadingIndicator.startAnimating();
        
        if (firstTime) {
            // Lock start point
            self.locRunPointA = self.mapView.userLocation.coordinate;
            self.runPointHome = self.mapView.userLocation.coordinate;
        
            // Draw start point on map
            var pointAAnno: MKPointAnnotation = MKPointAnnotation();
            pointAAnno.coordinate = self.locRunPointA!;
            self.mapView.addAnnotation(pointAAnno);
        
            // Set region on map
            let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate,
                self.locRunDistance * 1.5,
                self.locRunDistance * 1.5);
            self.mapView.setRegion(region, animated:true);
        
            
            switch self.runTypeId {
            case 1:
                println("LocRun");
                self.totalNeededPoints = 1;
                self.distancePerPoint.append(self.locRunDistance/2);
                
            case 2:
                println("IntRun");
                
            case 3:
                println("ColRun");
                self.totalNeededPoints = 5;
                self.distancePerPoint.append(self.locRunDistance/2/5); //Very simple split, we could find something more interesting!
                self.distancePerPoint.append(self.locRunDistance/2/5);
                self.distancePerPoint.append(self.locRunDistance/2/5);
                self.distancePerPoint.append(self.locRunDistance/2/5);
                self.distancePerPoint.append(self.locRunDistance/2/5);
                
            case 4:
                println("CalRun");
                self.totalNeededPoints = 12;
                self.distancePerPoint.append(200);
                self.distancePerPoint.append(400);
                self.distancePerPoint.append(600);
                self.distancePerPoint.append(200);
                self.distancePerPoint.append(400);
                self.distancePerPoint.append(600);
                self.distancePerPoint.append(200);
                self.distancePerPoint.append(400);
                self.distancePerPoint.append(600);
                self.distancePerPoint.append(200);
                self.distancePerPoint.append(400);
                self.distancePerPoint.append(600);
                
            default:
                println("Unkown runTypeId in GenerateRunViewController");
            }
        }
    
        
        // Generate point B
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "generateRoute", userInfo: nil, repeats: false);
    }
    
    func generateRoute() {
        println("Generating interesting goal points!!");
        
        if (self.distancePerPoint.count == 0) {
            // Finish up!
            
            // Save data in database
            self.db.execute("UPDATE active_runs SET disabled=1 WHERE runId=\(self.runId)");
            
            // Change btn state
            self.btnReady.setTitle("Run now", forState: UIControlState.Normal);
            self.btnReady.backgroundColor = UIColor(red: 0, green: 1.0, blue: 0, alpha: 1.0);
            self.loadingIndicator.stopAnimating();
            self.btnReadyWorking = false;
        } else {
            for dist in self.distancePerPoint {
                println("Gen for point with dist: \(dist)");
                generateRoute_worker(dist, shootOutDist: dist, accumDist: 0.0, totalTried: 1, totalFail: 0);
            }
        }
    }
    
    func generateRoute_worker(wishedDist: Double, shootOutDist: Double, accumDist: Double, totalTried: Int, totalFail: Int) {
        println("dist:\(wishedDist) - shootOutDist:\(shootOutDist) - accumDist:\(accumDist) - totalTried:\(totalTried)");
        
        //Acceptable distance (200m + 5%)
        var acceptableDeltaDistInMeters: Double = 200.0 + wishedDist*0.05;

        
        // Generate random point, x distance away
        let bearing: Double = Double(arc4random_uniform(360000))/1000.0;
        var autopoint1Annotation: MKPointAnnotation = MKPointAnnotation();
        autopoint1Annotation.coordinate = HelperFunctions().coordinateFromCoord(self.locRunPointA!, distanceKm: shootOutDist/1000.0, bearingDegrees: bearing);
        
        
        // Get point on nearest road
        let placemarkSource: MKPlacemark = MKPlacemark(coordinate: self.mapView.userLocation.coordinate, addressDictionary: nil);
        let mapItemSource: MKMapItem = MKMapItem(placemark: placemarkSource);
        
        let placemarkDest: MKPlacemark = MKPlacemark(coordinate: autopoint1Annotation.coordinate, addressDictionary: nil);
        let mapItemDest: MKMapItem = MKMapItem(placemark:placemarkDest);
        
        var walkingRouteRequest: MKDirectionsRequest = MKDirectionsRequest();
        walkingRouteRequest.transportType = MKDirectionsTransportType.Walking;
        walkingRouteRequest.setSource(mapItemSource);
        walkingRouteRequest.setDestination(mapItemDest);
        
        var walkingRouteDirections: MKDirections = MKDirections(request: walkingRouteRequest);
        walkingRouteDirections.calculateDirectionsWithCompletionHandler({(response:MKDirectionsResponse!, error: NSError!) in

            if (error != nil) {
                //Some error happened, try again :)
                if (error.code == 5) {
                    println("Directions not available");
                } else {
                    println("Error %@", error.description);
                }
                
                //If too many tries, do not continue
                if (totalTried <= 16) {
                    self.generateRoute_worker(wishedDist, shootOutDist: shootOutDist, accumDist: accumDist, totalTried: totalTried+1, totalFail: totalFail+1);
                } else {
                    println("I GIVE UP11!!!!");
                    // Change btn state
                    self.btnReady.setTitle("Try again (ready)", forState: UIControlState.Normal);
                    self.btnReady.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0);
                    self.loadingIndicator.stopAnimating();
                    self.btnReadyWorking = false;
                }
            } else {
                // Take the last MKRoute object
                let route: MKRoute = response.routes[response.routes.count-1] as MKRoute;
                let pointCount: Int = route.polyline.pointCount;
                
                // Allocate a array to hold 1 points/coordinates
                // - Important to add 1 dummy item, which will be overwritten
                var routeCoordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D(latitude: 0, longitude: 0)];
                
                // Get the last coordinate of the polyline
                route.polyline.getCoordinates(&routeCoordinates, range: NSMakeRange(pointCount-1, 1));
                
                if (route.distance < wishedDist+acceptableDeltaDistInMeters && route.distance > wishedDist-acceptableDeltaDistInMeters) {
                    
                    // Acceptable distance
                    self.estimatedDistance = Int(route.distance*2);
                    let routeDistanceFormat = NSString(format: "%.2f", route.distance);
                    let bearingFormat = NSString(format: "%.2f", bearing);
                    println("Acceptable distance - distance was: \(routeDistanceFormat), with bearing: \(bearingFormat)");
                    
                    // Update annotation  --THIS FAILS, or does it?
                    self.locRunPointB = routeCoordinates[0];
                    self.runPoints.append(routeCoordinates[0]);
                    
                    // Draw point on map
                    var pointBAnno: MKPointAnnotation = MKPointAnnotation();
                    pointBAnno.coordinate = self.locRunPointB!;
                    self.mapView.addAnnotation(pointBAnno);
                    
                    // Save data in database
                    // TODO: Save that the run is selected, pointA and pointB.
                    self.db.execute("UPDATE active_runs SET disabled=1 WHERE runId=\(self.runId)");
                    
                    // Change btn state
                    self.btnReady.setTitle("Run now", forState: UIControlState.Normal);
                    self.btnReady.backgroundColor = UIColor(red: 0, green: 1.0, blue: 0, alpha: 1.0);
                    self.loadingIndicator.stopAnimating();
                    self.btnReadyWorking = false;
                    
                } else {
                    // Not acceptable distance
                    let routeDistanceFormat = NSString(format: "%.2f", route.distance);
                    let bearingFormat = NSString(format: "%.2f", bearing);
                    println("NOT acceptable distance, retrying! - distance was: \(routeDistanceFormat), with bearing: \(bearingFormat)");
                    //Generate new rand point, test distance again.
                    //Maybe, if possible, take part of route to the discarded point?
                    
                    //This shoot out distance doesn't seems to work, adjust it
                    var newShootOutDist: Double = shootOutDist;
                    if ((totalTried-totalFail) % 5 == 0) {
                        //See how much we differ in average
                        let avgDistDiffer: Double = accumDist / Double(totalTried) - wishedDist;
                        newShootOutDist -= (avgDistDiffer/2);
                        
                        println("Adjusting shoot out length with -\(avgDistDiffer)");
                    }
                    
                    //If too many tries, do not continue
                    if (totalTried <= 16) {
                        self.generateRoute_worker(wishedDist, shootOutDist: newShootOutDist, accumDist: accumDist+route.distance, totalTried: totalTried+1, totalFail: totalFail);
                    } else {
                        println("I GIVE UP22!!!!");
                        // Change btn state
                        self.btnReady.setTitle("Try again (ready)", forState: UIControlState.Normal);
                        self.btnReady.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0);
                        self.loadingIndicator.stopAnimating();
                        self.btnReadyWorking = false;
                    }
                }
            }
        })
    }

    func countDown() {
        if (self.countDownCounter == 0) {
            self.countDownTimer?.invalidate();
            self.performSegueWithIdentifier("segueLocationRun", sender: self);
        } else {
            self.btnReady.setTitle("Go in \(self.countDownCounter) seconds!", forState: UIControlState.Normal);
            self.countDownCounter -= 1;
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    
    
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // General
        let runScreenViewController: RunScreenViewController = segue.destinationViewController as RunScreenViewController;
        runScreenViewController.runId = self.runId;
        runScreenViewController.runTypeId = self.runTypeId;
        runScreenViewController.medalBronze = self.medalBronze;
        runScreenViewController.medalSilver = self.medalSilver;
        runScreenViewController.medalGold = self.medalGold;
        runScreenViewController.runPointHome = self.runPointHome;
        runScreenViewController.runPoints = self.runPoints;
        
        if (segue.identifier == "segueLocationRun") {
            // Do something specific
            runScreenViewController.locRunActive = true;
            runScreenViewController.locRunPointA = self.locRunPointA;
            runScreenViewController.locRunPointB = self.locRunPointB;
            runScreenViewController.estimatedDistanceInM = self.estimatedDistance;
        } else if (segue.identifier == "segueCollectorRun") {
            // Do something specific
            runScreenViewController.estimatedDistanceInM = self.estimatedDistance;
        }
    }
    
}
