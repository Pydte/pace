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

    var selectedRun: Run?;
    let db = SQLiteDB.sharedInstance();
    
    @IBOutlet var mapView: MKMapView
    @IBOutlet var lblDate: UILabel
    @IBOutlet var lblDistance: UILabel
    @IBOutlet var lblDuration: UILabel
    @IBOutlet var lblAvgSpeed: UILabel
    @IBOutlet var lblMaxSpeed: UILabel
    @IBOutlet var lblMinAltitude: UILabel
    @IBOutlet var lblMaxAltitude: UILabel
    @IBOutlet var btnDelete: UIBarButtonItem
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load all data points into memory
        loadRouteData();
        
        // Present info
        presentInfo();
        
        // Draw route
        drawRoute();
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
        // Check if the data points already is in memory, otherwise load them from db.
        if (self.selectedRun!.locations.count == 0) {
            let queryLocs = db.query("SELECT latitude, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed FROM runs_location WHERE runId = \(self.selectedRun!.dbId) ORDER BY id");
            for locInDb in queryLocs {
                // Retrieve loc data
                let lat = locInDb["latitude"]!.double;
                let lon = locInDb["longitude"]!.double;
                let horizontalAcc = locInDb["horizontalAccuracy"]!.double;
                let altitude = locInDb["altitude"]!.double;
                let verticalAcc = locInDb["verticalAccuracy"]!.double;
                let speed = locInDb["speed"]!.double;
                let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    altitude: altitude,
                    horizontalAccuracy: horizontalAcc,
                    verticalAccuracy: verticalAcc,
                    course: 0,
                    speed: speed,
                    timestamp: nil)
                
                self.selectedRun!.locations.append(loc);
            }
        }
    }
    
    func presentInfo() {
        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MMM. dd, yyyy, HH:mm";
        self.lblDate.text = dateFormatter.stringFromDate(self.selectedRun!.start);
        
        self.lblDistance.text = NSString(format: "%.2f", self.selectedRun!.distance/1000);
        
        let runTimeInSeconds: NSNumber = self.selectedRun!.end!.timeIntervalSinceDate(self.selectedRun!.start);
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
        avgSpeed = avgSpeed/Double(self.selectedRun!.locations.count);
        
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
    }
    
    func drawRoute() {
        var pointsCoordinate: [CLLocationCoordinate2D] = [];
        
        for (var i=0; i<self.selectedRun!.locations.count; i++) {
            let location: CLLocation = self.selectedRun!.locations[i];
            pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
        }
        
        let polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: self.selectedRun!.locations.count);
        self.mapView.addOverlay(polyline);
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
    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
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
