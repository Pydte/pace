//
//  OnePLocationRunViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit

class OnePLocationRunViewControllerSwift: UIViewController, MKMapViewDelegate {

    
    @IBOutlet var approxDistField: UITextField!;
    @IBOutlet var mapView: MKMapView!;
    @IBOutlet var LoadingIcon_endPos: UIActivityIndicatorView!;
    var location: CLLocation? = nil;
    var endPosAuto: Bool = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide NavigationBar
        self.navigationController!.setNavigationBarHidden(true, animated:true);
        super.viewWillAppear(true);
        
        // Create a gesture recognizer for long presses (for example in viewDidLoad)
        var lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:");
        lpgr.minimumPressDuration = 0.5; //user needs to press for half a second.
        self.mapView.addGestureRecognizer(lpgr);
        
        // Done button above keypad
        var numberToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50));
        numberToolbar.barStyle = UIBarStyle.BlackTranslucent;
        numberToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "doneWithNumberPad")];
        numberToolbar.sizeToFit();
        self.approxDistField.inputAccessoryView = numberToolbar;
        
        // Init properties
        self.endPosAuto = true;
        
        // Bind mapView delegate to this controller
        self.mapView.delegate = self;
        
        // Turn on user tracking
        self.mapView.showsUserLocation = true;
        
        // Skip to rough location, without animation (to avoid animating from USA overview)
        let userLocation: MKUserLocation = self.mapView.userLocation;
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000);
        self.mapView.setRegion(region, animated:false);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // #pragma mark - Navigation
    override func shouldPerformSegueWithIdentifier(identifier: String!, sender: AnyObject!) -> Bool {
        if(identifier? == "SegueStartRun") {
            if (!self.endPosAuto) {
                // There should be a point chosen, otherwise abort
                if (self.location == nil) {
                    var alert: UIAlertView = UIAlertView();
                alert.title = "Invalid goal";
                alert.message = "You should pick a goal (press and hold on map).";
                alert.addButtonWithTitle("Got it");
                alert.show();
                return false;
            }
        }
        
        if ((self.approxDistField.text as NSString).doubleValue < 0.4) {
            var alert: UIAlertView = UIAlertView();
            alert.title = "Invalid distance";
            alert.message = "You should enter a distance longer than 400 meters.";
            alert.addButtonWithTitle("Got it");
            alert.show();
            return false;
        }
        if ((self.approxDistField.text as NSString).doubleValue > 60.0) {
            var alert: UIAlertView = UIAlertView();
            alert.title = "Invalid distance";
            alert.message = "You should enter a distance shorter than 60 km.";
            alert.addButtonWithTitle("Got it");
            alert.show();
            return false;
        }
        
        }
        return true;
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if(segue.identifier? == "SegueStartRun") {
            var runScreenViewController: RunScreenViewController = segue.destinationViewController as RunScreenViewController;
            runScreenViewController.autoroute1 = true;
            runScreenViewController.onePointLocationRunDistance = (self.approxDistField.text as NSString).doubleValue * 1000.0;
            
            if (!self.endPosAuto) {
                runScreenViewController.onePointLocationLocation = self.location;
            }
            
            println("start run");
        }
    }

    func handleLongPress(gestureRecognizer: UIGestureRecognizer!) {
        if (gestureRecognizer.state != UIGestureRecognizerState.Began) {
            return;
        }
        
        //Start loading icon
        self.LoadingIcon_endPos.startAnimating();
        
        let touchPoint: CGPoint = gestureRecognizer.locationInView(self.mapView);
        let touchMapCoordinate: CLLocationCoordinate2D = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView);
        var point: MKPointAnnotation = MKPointAnnotation();
        point.coordinate = touchMapCoordinate;
        for annotation in self.mapView.annotations {
            self.mapView.removeAnnotation(annotation as MKAnnotation);
        }
        
        
        // Get point on nearest road
        let placemarkSource: MKPlacemark = MKPlacemark(coordinate:self.mapView.userLocation.coordinate, addressDictionary:nil);
        let mapItemSource: MKMapItem = MKMapItem(placemark:placemarkSource);
        
        let placemarkDest: MKPlacemark = MKPlacemark(coordinate: point.coordinate, addressDictionary: nil);
        let mapItemDest: MKMapItem = MKMapItem(placemark: placemarkDest);
        
        var walkingRouteRequest: MKDirectionsRequest = MKDirectionsRequest();
        walkingRouteRequest.transportType = MKDirectionsTransportType.Walking;
        walkingRouteRequest.setSource(mapItemSource);
        walkingRouteRequest.setDestination(mapItemDest);
        
        let walkingRouteDirections: MKDirections = MKDirections(request: walkingRouteRequest)
        walkingRouteDirections.calculateDirectionsWithCompletionHandler({(response:MKDirectionsResponse!, error: NSError!) in
            if (error != nil) {
                //Some error happened
                println("Error \(error.description)");
            } else {
                // Take the last MKRoute object
                let route: MKRoute = response.routes[response.routes.count-1] as MKRoute;
                let pointCount: Int = route.polyline.pointCount;
                
                // Allocate a array to hold 1 points/coordinates
                // - Important to add 1 dummy item, which will be overwritten
                var routeCoordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D(latitude: 0, longitude: 0)];
                
                // Get the last coordinate of the polyline
                route.polyline.getCoordinates(&routeCoordinates, range:NSMakeRange(pointCount-1, 1));
                
                // Set point on nearest road
                self.location = CLLocation(latitude: routeCoordinates[0].latitude, longitude:routeCoordinates[0].longitude)
                point.coordinate = routeCoordinates[0];
                self.mapView.addAnnotation(point);
                
                // Set distance
                self.approxDistField.text = NSString(format: "%.2f", route.distance/1000.0);
            }
            self.LoadingIcon_endPos.stopAnimating();
        });
    }
    
    func doneWithNumberPad() {
        self.approxDistField.resignFirstResponder();
    }
    
    @IBAction func startPosAutoSwitch(sender: AnyObject) {
        sender.setOn(true, animated:true);
  
        var alert: UIAlertView = UIAlertView();
        alert.title = "Not an option!";
        alert.message = "You really don't wanna do that..";
        alert.addButtonWithTitle("I accept my faith");
        alert.show();
    }
    
    @IBAction func endPosAutoSwitch(sender: AnyObject) {
        let state: Bool = sender.isOn;
        self.endPosAuto = state;
        
        if (state) {
            self.LoadingIcon_endPos.startAnimating();
            self.mapView.hidden = true;
            self.approxDistField.enabled = true;
            self.LoadingIcon_endPos.stopAnimating();
        } else {
            self.LoadingIcon_endPos.startAnimating();
            
            // Skip to location, without animation
            let userLocation: MKUserLocation = self.mapView.userLocation;
            let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 2000, 2000);
            self.mapView.setRegion(region, animated: false);
            
            self.mapView.hidden = false;
            self.approxDistField.enabled = false;
            self.LoadingIcon_endPos.stopAnimating();
        }
    }
}
