//
//  RunFinishedSummaryViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RunFinishedSummaryViewControllerSwift: UIViewController {
    
    @IBOutlet var lblDate: UILabel
    @IBOutlet var lblDistance: UILabel
    @IBOutlet var lblDuration: UILabel
    @IBOutlet var lblAvgSpeed: UILabel
    @IBOutlet var lblMaxSpeed: UILabel
    @IBOutlet var lblMinAltitude: UILabel
    @IBOutlet var lblMaxAltitude: UILabel
    @IBOutlet var mapView: MKMapView;
    let db = SQLiteDB.sharedInstance();
    var finishedRun: Run? = nil;
    var runId: Int = 0;
    var run_locations: String = "";
    
    @IBOutlet var lblSynchronizeStatus: UILabel
    @IBOutlet var idcSynchronizeStatus: UIActivityIndicatorView
    var synchronized: Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Save run to database
        db.execute("INSERT INTO runs (userId, startDate, endDate, distance) VALUES((SELECT loggedInUserId FROM Settings),\(Int(finishedRun!.start!.timeIntervalSince1970)),\(Int(finishedRun!.end!.timeIntervalSince1970)),\(finishedRun!.distance))");
        self.runId = Int(self.db.lastInsertedRowID());
        
        // Save all logged locations
        for loc in finishedRun!.locations {
            self.db.execute("INSERT INTO runs_location (latitude, runId, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed, timestamp) VALUES(\(loc.coordinate.latitude),\(runId),\(loc.coordinate.longitude),\(loc.horizontalAccuracy),\(loc.altitude),\(loc.verticalAccuracy),\(loc.speed),\(Int(loc.timestamp.timeIntervalSince1970)))");
            run_locations += "&latitude[]=\(loc.coordinate.latitude)&longitude[]=\(loc.coordinate.longitude)&horizontal_accuracy[]=\(loc.horizontalAccuracy)&vertical_accuracy[]=\(loc.verticalAccuracy)&altitude[]=\(loc.altitude)&speed[]=\(loc.speed)&timestamp[]=\(Int(loc.timestamp.timeIntervalSince1970))";
        }
        
        // Populate view
        presentInfo();
        
        // Draw route
        drawRoute()
        
        // Synchronize
        uploadRun();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func presentInfo() {
        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MMM. dd, yyyy, HH:mm";
        self.lblDate.text = dateFormatter.stringFromDate(self.finishedRun!.start);
        
        self.lblDistance.text = NSString(format: "%.2f", self.finishedRun!.distance/1000);
        
        let runTimeInSeconds: NSNumber = self.finishedRun!.end!.timeIntervalSinceDate(self.finishedRun!.start);
        let runTimeInMinutes: Double = Double(runTimeInSeconds) / Double(60);
        let runRemainingTimeInSeconds: Double = fmod(Double(runTimeInSeconds), 60);
        let runTimeInMinutesFormat = NSString(format: "%02d", Int(runTimeInMinutes));
        let runRemainingTimeInSecondsFormat = NSString(format: "%02d", Int(runRemainingTimeInSeconds));
        self.lblDuration.text = "\(runTimeInMinutesFormat):\(runRemainingTimeInSecondsFormat)";
        
        
        // Extreme coordinates
        var latTop: Double    = -999999;
        var lonRight: Double  = -999999;
        var latBottom: Double = 999999;
        var lonLeft: Double   = 999999;
        
        var avgSpeed: Double    = 0.0; // In min/km
        var minAltitude: Double = 999999;
        var maxAltitude: Double = -999999;
        
        for loc in self.finishedRun!.locations {
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
            
            
            // Plus all speed entries
            avgSpeed = avgSpeed + loc.speed;
            
            
            // Find min and max altitude
            if (loc.altitude < minAltitude) {
                minAltitude = loc.altitude;
            }
            if (loc.altitude > maxAltitude) {
                maxAltitude = loc.altitude;
            }
        }
        
        // Divide accumulated speeds with number of entries
        avgSpeed = avgSpeed/Double(self.finishedRun!.locations.count);
        
        // Convert avg. speed from m/s to min/km
        avgSpeed = 16.66666666666667/avgSpeed;
        self.lblAvgSpeed.text = NSString(format: "%.2f", avgSpeed);
        
        // Set altitude
        self.lblMinAltitude.text = NSString(format: "%.0f", minAltitude);
        self.lblMaxAltitude.text = NSString(format: "%.0f", maxAltitude);
        
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
        
        
        // Update database
        self.db.execute("UPDATE runs SET duration=\(runTimeInSeconds), avgSpeed=\(avgSpeed), maxSpeed=0, minAltitude=\(minAltitude), maxAltitude=\(maxAltitude) WHERE id=\(self.runId)");
    }
   
    func uploadRun() {
        func callbackSuccess(data: AnyObject) {
            println("Upload successful");
            
            // Update realRunId
            //let realRunId: Int = dic.objectForKey("id").integerValue;
            //self.db.execute("UPDATE Runs SET realRunId=\(realRunId) WHERE id=\(self.runId)");
            
            self.lblSynchronizeStatus.text = "Synchronized";
            self.idcSynchronizeStatus.stopAnimating();
            self.synchronized = true;
        }
        
        func callbackError(err: String) {
            println(err);
            self.lblSynchronizeStatus.text = "Synchronize failed";
            self.idcSynchronizeStatus.stopAnimating();
            self.synchronized = true;
        }
        
        let runDataQuery = self.db.query("SELECT s.loggedInUserId, r.distance, r.duration, r.avgSpeed, r.maxSpeed, r.minAltitude, r.maxAltitude FROM Settings s, Runs r WHERE r.id=\(self.runId)");
        let userId: Int = runDataQuery[0]["loggedInUserId"]!.integer;
        let distance: Double = runDataQuery[0]["distance"]!.double;
        let duration: Double = runDataQuery[0]["duration"]!.double;
        let avgSpeed: Double = runDataQuery[0]["avgSpeed"]!.double;
        let maxSpeed: Double = runDataQuery[0]["maxSpeed"]!.double;
        let minAltitude: Double = runDataQuery[0]["minAltitude"]!.double;
        let maxAltitude: Double = runDataQuery[0]["maxAltitude"]!.double;
        
        
        let params: String = "user_id=\(userId)&max_speed=\(maxSpeed)&min_altitude=\(minAltitude)&max_altitude=\(maxAltitude)&avg_speed=\(avgSpeed)&distance=\(distance)&duration=\(duration)\(run_locations)";
        HelperFunctions().callWebService("post-free-run", params: params, callbackSuccess: callbackSuccess, callbackFail: callbackError)
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
    
    func drawRoute() {
        var pointsCoordinate: [CLLocationCoordinate2D] = [];
        
        for (var i=0; i<self.finishedRun!.locations.count; i++) {
            let location: CLLocation = self.finishedRun!.locations[i];
            pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
        }
        
        let polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: self.finishedRun!.locations.count);
        self.mapView.addOverlay(polyline);
    }

    
    // #pragma mark - Navigation
    override func shouldPerformSegueWithIdentifier(identifier: String!, sender: AnyObject!) -> Bool {
        if (self.synchronized == false) {
            var alert: UIAlertView = UIAlertView()
            alert.title = "Easy there cowboy!"
            alert.message = "We havn't uploaded the run to our servers yet, please wait a second."
            alert.addButtonWithTitle("I understand")
            
            alert.show()
            return false;
        }
        return true;
    }
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
