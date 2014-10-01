//
//  MapViewControllerSwift.swift
//  EpicRunner
//
//  Created by Jeppe on 24/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation

class MapViewControllerSwift: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var btnMenu: UIBarButtonItem
    @IBOutlet var mapView: MKMapView
    @IBOutlet var runButton: UIButton
    
    let iosVersion = NSString(string: UIDevice.currentDevice().systemVersion).doubleValue
    var locationManager: CLLocationManager = CLLocationManager();
    
    var multiplayer: Bool = false;
    var autoroute1: Bool = false;
    var onePointLocationRunDistance: Double = 0.0;
    var onePointLocationLocation: CLLocation? = nil;
    
    var capturing: Bool = false;
    var currentRun: Run? = nil;
    var mapZoomlevel: Double = 1000;
    
    var avCoinSound: AVAudioPlayer? = nil;
    
    var prevLoc: CLLocation? = nil;
    var totalDistance: Double = 0.0;
    var recordedDistance: Double = 0.0;
    var coinedDistance: Double = 0.0;
    
    var player2timestamp: Double = 0.0;
    var player2Annotation: MKPointAnnotation?;
    
    var autopoint1Generated: Bool = false;
    var autopoint1Annotation: MKPointAnnotation? = nil;
    var onePointLocationRunGenPointTotalTries: Int = 0;
    var onePointLocationRunGenPointTries: Int = 0;
    var onePointLocationRunGenPointAccumDist: Double = 0.0;
    var onePointLocationRunShootOutDistance: Double = 0.0;
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)  {
        let userLocation: CLLocation = locations[0] as CLLocation;
        let isInBackground: Bool = UIApplication.sharedApplication().applicationState == UIApplicationState.Background;
        
        
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
            self.locationManager.requestWhenInUseAuthorization(); // Necessary for iOS 8 and crashes iOS 7...
        }
        self.locationManager.startUpdatingLocation();
        
        
        // Always show navigationBar
        self.navigationController.setNavigationBarHidden(false, animated: false);
        super.viewWillAppear(false);
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        
        // Bind mapView delegate to this controller
        self.mapView.delegate = self;
        
        // Set default zoom level
        if (self.autoroute1) {
            self.mapZoomlevel = self.onePointLocationRunDistance+800.0;
        }
        
        // Turn on user tracking
        self.mapView.showsUserLocation = true;
        
        // Skip to rough location, without animation (to avoid animating from USA overview)
        // Used userLocation.location.coordinate before, but that is nil in swift?
        let userLocation: MKUserLocation = self.mapView.userLocation;
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 6000, 6000)
        self.mapView.setRegion(region, animated:false);

            
        
        // Set coin sound
        //let soundURL: NSURL = NSBundle.URLForResource("213423__taira-komori__coin05", withExtension: "mp3", subdirectory: nil, inBundleWithURL: nil);
        //self.avCoinSound = AVAudioPlayer(contentsOfURL: soundURL, error: nil);
        
        
        
        // Init multiplayer (/second player)
        if(self.multiplayer) {
            self.player2timestamp = 0;
            self.player2Annotation = MKPointAnnotation();
            self.mapView.addAnnotation(self.player2Annotation);        }
        
        
        // Init 1-point location run
        if (self.autoroute1) {
            println("autoroute1 START");
            self.autopoint1Generated = false;
            self.autopoint1Annotation = MKPointAnnotation();
            self.onePointLocationRunGenPointTries = 0;
            self.onePointLocationRunGenPointTotalTries = 0;
            self.onePointLocationRunGenPointAccumDist = 0;
            self.onePointLocationRunShootOutDistance = self.onePointLocationRunDistance;
            
            if (self.onePointLocationLocation == nil) {
                autoroute1_generate_route();
            } else {
                println("Using custom location");
                var autopoint1Annotation: MKPointAnnotation = MKPointAnnotation();
                autopoint1Annotation.coordinate = self.onePointLocationLocation!.coordinate;
                
                // Draw point on map
                self.autopoint1Annotation = autopoint1Annotation;
                self.mapView.addAnnotation(self.autopoint1Annotation);
                self.autopoint1Generated = true;
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        // Make dot not selectable
        userLocation.title = "";
        
        // Update region with new location in center
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate,
            self.mapZoomlevel,
            self.mapZoomlevel);
        self.mapView.setRegion(region, animated:true);
        
        
        // -- Mode specific below --
        // Update Player 2 location
        // Maybe eiher interpolate position or slowly grey-out point, to symbolize time since last updated
        if (self.multiplayer) {
            let timeNowInS = NSDate().timeIntervalSince1970;
            if (timeNowInS - self.player2timestamp > 3) {
                self.player2timestamp = timeNowInS;
                
                let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
                let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
                
                let url: NSURL = NSURL.URLWithString("http://marci.dk/epicrunner/locping.php");
                let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
                let coord = userLocation.location.coordinate;
                let params: String = NSString(format: "lat=%f&lon=%f", coord.latitude, coord.longitude);
                urlRequest.HTTPMethod = "POST";
                urlRequest.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false);
                
                let dataTask: NSURLSessionDataTask = defaultSession.dataTaskWithRequest(urlRequest, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
                    //println("Response:\(response) \(error)\n");
                    if (error == nil) {
                        //let text: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                        //println(text);
                    
                        var error: NSError?
                        let dic: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as NSDictionary;
                    
                        let player2lat: Double = dic.objectForKey("lat").doubleValue;
                        let player2lon: Double = dic.objectForKey("lon").doubleValue;
                        let p2: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: player2lat, longitude: player2lon);
                        self.player2Annotation!.coordinate = p2;
                    }
                });
                dataTask.resume();
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
        self.runButton.setTitle("Done", forState: .Normal);
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
    
    func autoroute1_generate_route() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {_ in
            println("Generating interesting goal point!!");
            
            //Wished distance
            var wishedDistInMeters: Double = self.onePointLocationRunDistance;
            //Shoot out distance
            var shootOutDistInMeters: Double = self.onePointLocationRunShootOutDistance;
            //Acceptable distance (200m + 5%)
            var acceptableDeltaDistInMeters: Double = 200.0 + self.onePointLocationRunDistance*0.05;
            
            
            //Wait a little, so the map has a fix on the user's position
            //Very ugly, but works for now..
            NSThread.sleepForTimeInterval(1.0);
            
            
            // Generate random point x distance away
            let bearing: Double = Double(arc4random_uniform(360000))/1000.0;
            var autopoint1Annotation: MKPointAnnotation = MKPointAnnotation();
            autopoint1Annotation.coordinate = self.coordinateFromCoord(self.mapView.userLocation.coordinate, distanceKm: (shootOutDistInMeters-acceptableDeltaDistInMeters)/1000.0, bearingDegrees: bearing);
            
            
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
                self.onePointLocationRunGenPointTotalTries++;
                
                if (error) {
                    //Some error happened, try again :)
                    println("Error %@", error.description);
                    
                    //If too many tries, do not continue
                    if (self.onePointLocationRunGenPointTotalTries <= 16) {
                        self.autoroute1_generate_route();
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
                    
                    // Save data to adjust distance to "shoot out"
                    self.onePointLocationRunGenPointTries++;
                    self.onePointLocationRunGenPointAccumDist += route.distance;
                    
                    if (route.distance < wishedDistInMeters+acceptableDeltaDistInMeters && route.distance > wishedDistInMeters-acceptableDeltaDistInMeters) {
                        //Acceptable distance
                        let routeDistanceFormat = NSString(format: "%.2f", route.distance);
                        let bearingFormat = NSString(format: "%.2f", bearing);
                        println("Acceptable distance - distance was: \(routeDistanceFormat), with bearing: \(bearingFormat)");
                        
                        //Update annotation -THIS FAILS
                        autopoint1Annotation.coordinate = routeCoordinates[0];
                        
                        // Draw point on map
                        self.autopoint1Annotation = autopoint1Annotation;
                        self.mapView.addAnnotation(self.autopoint1Annotation);
                        self.autopoint1Generated = true;
                    } else {
                        //Not acceptable distance
                        let routeDistanceFormat = NSString(format: "%.2f", route.distance);
                        let bearingFormat = NSString(format: "%.2f", bearing);
                        println("NOT acceptable distance, retrying! - distance was: \(routeDistanceFormat), with bearing: \(bearingFormat)");
                        //Generate new rand point, test distance again.
                        //Maybe, if possible, take part of route to the discarded point?
                        
                        //This shoot out distance doesn't seems to work, adjust it
                        if (self.onePointLocationRunGenPointTries == 5) {
                            //See how much we differ in average
                            let avgDistDiffer: Double = self.onePointLocationRunGenPointAccumDist / Double(self.onePointLocationRunGenPointTries) - self.onePointLocationRunDistance;
                            self.onePointLocationRunShootOutDistance -= (avgDistDiffer/2);
                            
                            self.onePointLocationRunGenPointTries = 0;
                            self.onePointLocationRunGenPointAccumDist = 0;
                            println("Adjusting shoot out length with -\(avgDistDiffer)");
                        }
                        
                        //If too many tries, do not continue
                        if (self.onePointLocationRunGenPointTotalTries <= 16) {
                            self.autoroute1_generate_route();
                        }
                    }
                }
            })
        });
    }

    
    @IBAction func plusZoom(sender: AnyObject) {
        self.mapZoomlevel += 500;
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
        self.mapZoomlevel,
            self.mapZoomlevel);
        self.mapView.setRegion(region, animated: true);
    }
    
    @IBAction func minusZoom(sender: AnyObject) {
        if (self.mapZoomlevel > 500) {
            self.mapZoomlevel -= 500;
        }
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
            self.mapZoomlevel,
            self.mapZoomlevel);
        self.mapView.setRegion(region, animated: true);
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
        if (segue.identifier == "SegueRunFinished")        {
            var runFinishedSummaryViewController: RunFinishedSummaryViewControllerSwift = segue.destinationViewController as RunFinishedSummaryViewControllerSwift;
            runFinishedSummaryViewController.finishedRun = self.currentRun;
        }
    }

    
    func radiansFromDegrees(degrees: Double) -> Double {
        return degrees * (M_PI/180.0);
    }
    
    func degreesFromRadians(radians: Double) -> Double {
        return radians * (180.0/M_PI);
    }
    
    func coordinateFromCoord(fromCoord: CLLocationCoordinate2D, distanceKm: Double, bearingDegrees: Double) -> CLLocationCoordinate2D {
        let distanceRadians: Double = distanceKm / 6371.0;
        //6,371 = Earth's radius in km
        let bearingRadians: Double = radiansFromDegrees(bearingDegrees);
        let fromLatRadians: Double = radiansFromDegrees(fromCoord.latitude);
        let fromLonRadians: Double = radiansFromDegrees(fromCoord.longitude);
        
        let toLatRadians: Double = asin( sin(fromLatRadians) * cos(distanceRadians)
        + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
        
        var toLonRadians: Double = fromLonRadians + atan2(sin(bearingRadians)
        * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
        - sin(fromLatRadians) * sin(toLatRadians));
        
        // adjust toLonRadians to be in the range -180 to +180...
        toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
        
        let result: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:  degreesFromRadians(toLatRadians), longitude: degreesFromRadians(toLonRadians));
        return result;
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // If you are showing the users location on the map you don't want to change it
        var view: MKAnnotationView? = nil;
        if (!annotation.isEqual(mapView.userLocation)) {
            // This is not the users location indicator (the blue dot)
            view = mapView.dequeueReusableAnnotationViewWithIdentifier("myAnnotationIdentifier");
            if (!view) {
                // Could not reuse a view ...
                
                // Creating a new annotation view
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotationIdentifier")
                
                // This will rescale the annotation view to fit the image
                view!.image = UIImage(named: "player2_dot");
            }
        }
        return view;
    }

    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
    }

}
