//
//  DetailViewViewControllerSwift.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class DetailViewViewControllerSwift: UIViewController {
    let screenName = "historyDetailView";
    
    var selectedRun: Run?;
    let db = SQLiteDB.sharedInstance();
    var userId: Int = 0;
    var sessionToken: String?;
    
    @IBOutlet var mapView: MKMapView!;
    @IBOutlet var lblDate: UILabel!;
    @IBOutlet var lblDistance: UILabel!;
    @IBOutlet var lblDuration: UILabel!;
    @IBOutlet var lblAvgSpeed: UILabel!;
    @IBOutlet var lblMaxSpeed: UILabel!;
    @IBOutlet var lblMinAltitude: UILabel!;
    @IBOutlet var lblMaxAltitude: UILabel!;
    @IBOutlet var btnDelete: UIBarButtonItem!;
    @IBOutlet weak var lblRun: UILabel!;
    @IBOutlet weak var imgMedal: UIImageView!;
    
    @IBOutlet weak var mapOverlay: UIView!;
    @IBOutlet weak var mapOverlayText: UILabel!;
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Load User Id
        let queryId = db.query("SELECT loggedInUserId, loggedInSessionToken FROM settings");
        self.userId = queryId[0]["loggedInUserId"]!.asInt();
        self.sessionToken = queryId[0]["loggedInSessionToken"]!.asString();
        
        
        // Load all data points into memory
        loadRouteData();
        
        // Present info
        presentInfo();
        
        // Draw route
        drawRoute();
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if (overlay.isKindOfClass(MKPolyline)){
            let route: MKPolyline = overlay as MKPolyline;
            var routeRenderer: MKPolylineRenderer = MKPolylineRenderer(polyline: route);
            routeRenderer.strokeColor = UIColor.blueColor();
            return routeRenderer;
        } else {
            return nil;
        }
    }
    
    func loadRouteData() {
        func callbackSuccess(data: AnyObject?) {
            //Extract data into db
            let dic: NSDictionary = data as NSDictionary;
            let runs: NSArray = dic.objectForKey("runs") as NSArray;
            
            for run in runs {
                let la: Double = run.objectForKey("la")!.doubleValue;
                let lo: Double = run.objectForKey("lo")!.doubleValue;
                let ho: Double = run.objectForKey("ho")!.doubleValue;
                let al: Double = run.objectForKey("al")!.doubleValue;
                let ve: Double = run.objectForKey("ve")!.doubleValue;
                let sp: Double = run.objectForKey("sp")!.doubleValue;
                let ti: Int = run.objectForKey("ti")!.integerValue;
                
                
                // INSERT IF NOT EXISTS
                self.db.execute("INSERT INTO runs_location (runid, latitude, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed, timestamp) VALUES (" +
                    "\(self.selectedRun!.dbId!), \(la), \(lo), \(ho), \(al), \(ve), \(sp), \(ti))");
            }
            
            loadRouteData();
            drawRoute();
        }
        
        func callbackFail(err: String) {
            self.loadingIndicator.stopAnimating();
            self.mapOverlayText.text = "Route unavailable.";
        }
        
        // Check if the data points already is in memory
        if (self.selectedRun!.locations.count == 0) {
            // Check if is available in local db, if so, load it
            let queryLocs = db.query("SELECT latitude, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed FROM runs_location WHERE runId = \(self.selectedRun!.dbId!) ORDER BY id");
            
            if (queryLocs.count > 0) {
                for locInDb in queryLocs {
                    // Retrieve loc data
                    let lat = locInDb["latitude"]!.asDouble();
                    let lon = locInDb["longitude"]!.asDouble();
                    let horizontalAcc = locInDb["horizontalAccuracy"]!.asDouble();
                    let altitude = locInDb["altitude"]!.asDouble();
                    let verticalAcc = locInDb["verticalAccuracy"]!.asDouble();
                    let speed = locInDb["speed"]!.asDouble();
                    let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        altitude: altitude,
                        horizontalAccuracy: horizontalAcc,
                        verticalAccuracy: verticalAcc,
                        course: 0,
                        speed: speed,
                        timestamp: nil)
                    
                    self.selectedRun!.locations.append(loc);
                }
                removeMapOverlay();
            } else {
                // Load from webservice
                HelperFunctions().callWebService("old-run-locations", params: "runid=\(self.selectedRun!.realRunId!)&userid=\(self.userId)&session_token=\(self.sessionToken)", callbackSuccess: callbackSuccess, callbackFail: callbackFail);
            }
        } else {
            removeMapOverlay();
        }
    }
    
    func removeMapOverlay() {
        self.mapOverlay.hidden = true;
        //self.mapOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0);
    }
    
    func presentInfo() {
        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MMM. dd, yyyy, HH:mm";
        self.lblDate.text = dateFormatter.stringFromDate(self.selectedRun!.start!);
        self.lblDistance.text = NSString(format: "%.2f", self.selectedRun!.distance/1000);
        self.lblRun.text = HelperFunctions().runHeadline[self.selectedRun!.runTypeId];
        self.imgMedal.image = UIImage(named: "medal_\(HelperFunctions().runMedal[self.selectedRun!.medal])");
        
        //let runTimeInSeconds: NSNumber = self.selectedRun!.end!.timeIntervalSinceDate(self.selectedRun!.start!);
        let runTimeInSeconds: NSNumber = NSNumber(double: self.selectedRun!.duration);
        let runTimeInMinutes: Double = Double(runTimeInSeconds) / Double(60);
        let runRemainingTimeInSeconds: Double = fmod(Double(runTimeInSeconds), 60);
        let runTimeInMinutesFormat = NSString(format: "%02d", Int(runTimeInMinutes));
        let runRemainingTimeInSecondsFormat = NSString(format: "%02d", Int(runRemainingTimeInSeconds));
        self.lblDuration.text = "\(runTimeInMinutesFormat):\(runRemainingTimeInSecondsFormat)";
        
        
        // Extreme coordinates
        var avgSpeed: Double    = 0.0; // In min/km
        var minAltitude: Double = 999999;
        var maxAltitude: Double = -999999;
        
        for loc in self.selectedRun!.locations {
            // Plus all speed entries
            //avgSpeed = avgSpeed + loc.speed;
            
            
            // Find min and max altitude
            if (loc.altitude < minAltitude) {
                minAltitude = loc.altitude;
            }
            if (loc.altitude > maxAltitude) {
                maxAltitude = loc.altitude;
            }
        }
        
        // Divide accumulated speeds with number of entries
        //avgSpeed = avgSpeed/Double(self.selectedRun!.locations.count);
        
        // Use avg speed from db (IN M/S!)
        avgSpeed = self.selectedRun!.avgSpeed;
        
        // Convert avg. speed from m/s to min/km
        avgSpeed = 16.66666666666667/avgSpeed;
        self.lblAvgSpeed.text = NSString(format: "%.2f", avgSpeed);
        
        // Set altitude
        self.lblMinAltitude.text = NSString(format: "%.0f", minAltitude);
        self.lblMaxAltitude.text = NSString(format: "%.0f", maxAltitude);
    }
    
    func drawRoute() {
        var pointsCoordinate: [CLLocationCoordinate2D] = [];
        
        for (var i=0; i<self.selectedRun!.locations.count; i++) {
            let location: CLLocation = self.selectedRun!.locations[i];
            pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
        }
        
        let polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: self.selectedRun!.locations.count);
        self.mapView.addOverlay(polyline);
        
        // Extreme coordinates
        var latTop: Double    = -999999;
        var lonRight: Double  = -999999;
        var latBottom: Double = 999999;
        var lonLeft: Double   = 999999;
    
        for loc in self.selectedRun!.locations {
            //Find extreme coordinates
            if (loc.coordinate.latitude > latTop) {
                latTop = loc.coordinate.latitude;
            }
            if (loc.coordinate.latitude < latBottom) {
                latBottom = loc.coordinate.latitude;
            }
            
            if (loc.coordinate.longitude > lonRight) {
                lonRight = loc.coordinate.longitude;
            }
            if (loc.coordinate.longitude < lonLeft) {
                lonLeft = loc.coordinate.longitude;
            }
        }
        
        // Find longest distance horizontal and vertical
        let locTopLeft: CLLocation    = CLLocation(latitude: latTop, longitude: lonLeft);
        let locBottomLeft: CLLocation = CLLocation(latitude: latTop, longitude: lonLeft);
        let locTopRight: CLLocation   = CLLocation(latitude: latTop, longitude: lonRight);
        let distanceLat: Double       = locTopLeft.distanceFromLocation(locBottomLeft);
        let distanceLon: Double       = locTopLeft.distanceFromLocation(locTopRight);
        
        // Works terrible
        var distanceMargin: Double;
        if (distanceLat > distanceLon) {
            distanceMargin = distanceLat*1;
        }
        else {
            distanceMargin = distanceLon*1;
        }

        // Center map
        let startCoord: CLLocationCoordinate2D = CLLocationCoordinate2DMake((latTop+latBottom)/2, (lonRight+lonLeft)/2);
        let adjustedRegion = MKCoordinateRegionMakeWithDistance(startCoord, Double(distanceLat+distanceMargin), Double(distanceLon+distanceMargin));
        self.mapView.setRegion(adjustedRegion, animated: true);
    }
    
    @IBAction func deleteRun(sender: AnyObject) {
        var alert: UIAlertView = UIAlertView()
            alert.delegate = self
            alert.title = "Are you sure?"
            alert.message = "The run and its data will be deleted permanently."
            alert.addButtonWithTitle("Cancel")
            alert.addButtonWithTitle("Yes")
            
            alert.show()
    }
    
    func alertView(View: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        switch buttonIndex{
        case 1:
            NSLog("Delete (yes)");
            self.performSegueWithIdentifier("unwindToHistory", sender: self);
            break;
        default:
            NSLog("Default");
            break;
        }
    }
    
    //NOT USED ANYMORE
    @IBAction func btnUpload(sender: AnyObject) {
        func callbackSuccess(data: AnyObject) {
            println("Upload successful");
            
            // Update realRunId, synced
            let dic: NSDictionary = data as NSDictionary;
            let realRunId: Int = dic.objectForKey("posted_id")!.integerValue;
            self.db.execute("UPDATE Runs SET realRunId=\(realRunId), synced=1 WHERE id=\(self.selectedRun!.dbId)");
            
            // Remove from active_runs (run selector) IF NOT free run AND Locked
            if (self.selectedRun!.realRunId? != nil) {
                self.db.execute("DELETE FROM active_runs WHERE locked=1 AND runId=\(self.selectedRun!.realRunId!)");
            }
            
            println("Synchronized");
        }
        
        func callbackError(err: String) {
            println(err);
            println("Synchronize failed");
        }
        
        // If not already synced
        let runDataQuery = self.db.query("SELECT s.loggedInUserId, r.realRunId, r.distance, r.duration, r.avgSpeed, r.maxSpeed, r.minAltitude, r.maxAltitude, r.synced FROM Settings s, Runs r WHERE r.id=\(self.selectedRun!.dbId)");
        let userId: Int = runDataQuery[0]["loggedInUserId"]!.asInt();
        let realRunId: Int = runDataQuery[0]["realRunId"]!.asInt();
        let distance: Double = runDataQuery[0]["distance"]!.asDouble();
        let duration: Double = runDataQuery[0]["duration"]!.asDouble();
        let avgSpeed: Double = runDataQuery[0]["avgSpeed"]!.asDouble();
        let maxSpeed: Double = runDataQuery[0]["maxSpeed"]!.asDouble();
        let minAltitude: Double = runDataQuery[0]["minAltitude"]!.asDouble();
        let maxAltitude: Double = runDataQuery[0]["maxAltitude"]!.asDouble();
        let synced: Bool = Bool(runDataQuery[0]["synced"]!.asInt());
        
        if (synced) {
            println("Already synced!!");
        } else {
            println("Sync started..");
            var run_locations: String = "";
            for loc in selectedRun!.locations {
                run_locations += "&la[]=\(loc.coordinate.latitude)&lo[]=\(loc.coordinate.longitude)&ho[]=\(loc.horizontalAccuracy)&ve[]=\(loc.verticalAccuracy)&al[]=\(loc.altitude)&sp[]=\(loc.speed)&ti[]=\(Int(loc.timestamp.timeIntervalSince1970))";
            }
            
            var params: String = "user_id=\(userId)&max_speed=\(maxSpeed)&min_altitude=\(minAltitude)&max_altitude=\(maxAltitude)&avg_speed=\(avgSpeed)&distance=\(distance)&duration=\(duration)\(run_locations)";
            var webService: String = "post-free-run";
            if (self.selectedRun!.runTypeId != 0) {
                webService = "post-run";
                params = "run_id=\(realRunId)&" + params;
            }
            HelperFunctions().callWebService(webService, params: params, callbackSuccess: callbackSuccess, callbackFail: callbackError);
        }
    }
    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        // Delete run (LOCAL ONLY)
        if (segue.identifier == "unwindToHistory") {
            // Get reference to the destination view controller
            let hvc: HistoryTableViewControllerSwift = segue.destinationViewController as HistoryTableViewControllerSwift;
            
            // Tell history controller to delete run
            hvc.deleteRun();
        }
    }

}
