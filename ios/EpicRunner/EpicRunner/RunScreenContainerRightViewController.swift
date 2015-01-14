//
//  RunScreenContainerRightViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 24/10/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit

class RunScreenContainerRightViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    
    var container: RunScreenContainerViewController?;
    var mapZoomlevel: Double = 1000;
    var player2timestamp: Double = 0.0;
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.container = self.parentViewController as? RunScreenContainerViewController;
        
        // Bind mapView delegate to this controller
        self.mapView.delegate = self;
        
        // Turn on user tracking
        self.mapView.showsUserLocation = true;
        
        // Skip to rough location, without animation (to avoid animating from USA overview)
        // Used userLocation.location.coordinate before, but that is nil in swift?
        let userLocation: MKUserLocation = self.mapView.userLocation;
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 6000, 6000)
        self.mapView.setRegion(region, animated:false);
        
        
        // Init multiplayer (/second player)
        if(container!.multiplayer) {
            self.player2timestamp = 0;
            container!.player2Annotation = MKPointAnnotation();
            self.mapView.addAnnotation(container!.player2Annotation);
        }
        
        
        // Specific per run type
        if (container!.runTypeId == 1) {
            println("map: location run");
            // Location run
            // Draw point B on map
            container!.locRunNextPointAnno.coordinate = container!.runPoints[0];
            self.mapView.addAnnotation(container!.locRunNextPointAnno);
        
        
        
        } else if (container!.runTypeId == 2) {
            // Interval run
           
            
            
            
            
        } else if (container!.runTypeId == 3) {
            println("map: collector run");
            // Collector run
            // Draw home point
            self.container!.runPointHomeAnno = MKPointAnnotation();
            self.container!.runPointHomeAnno!.coordinate = container!.runPointHome!;
            //self.mapView.addAnnotation(self.container!.runPointHomeAnno);
            
            // Draw all points to collect
            for pointCoord in container!.runPoints {
                var mkPointAnno2: MKPointAnnotation = MKPointAnnotation();
                mkPointAnno2.coordinate = pointCoord;
                container!.runPointsAnno.append(mkPointAnno2);
                self.mapView.addAnnotation(mkPointAnno2);
            }
        }
       
    }
    
    func drawRoute() {
        //Hide user location
        self.mapView.showsUserLocation = false;
        
        //Draw route
        println("herp derp");
        println("herp derp");
        println(container!.intLocNumAtIntEnd.count);
        for (var i=0; i<container!.intLocNumAtIntEnd.count; i++){
//            var pointsCoordinate: [CLLocationCoordinate2D] = [];
//            
//            var startIndex: Int = 0;
//            var endIndex: Int = container!.intLocNumAtIntEnd[i];
//            if (i>0) {
//                startIndex = container!.intLocNumAtIntEnd[i-1];
//            }
//            
//            for (var j=startIndex; j<endIndex; i++) {
//                let location: CLLocation = self.container!.finishedRun!.locations[j];
//                pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
//            }
//            
//            let polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: endIndex-startIndex);
//            polyline.title = "\(self.container!.intPassed[i])";
//            self.mapView.addOverlay(polyline);
            
            var pointsCoordinate: [CLLocationCoordinate2D] = [];
            

            for (var i=0; i<self.container!.finishedRun!.locations.count; i++) {
                let location: CLLocation = self.container!.finishedRun!.locations[i];
                pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
            }
          
            let polyline1: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: self.container!.finishedRun!.locations.count);
            polyline1.title = "true";
            self.mapView.addOverlay(polyline1);
        }
        
        
//        var pointsCoordinate1: [CLLocationCoordinate2D] = [];
//        var pointsCoordinate2: [CLLocationCoordinate2D] = [];
//        
//        for (var i=0; i<(self.container!.finishedRun!.locations.count/2); i++) {
//            let location: CLLocation = self.container!.finishedRun!.locations[i];
//            pointsCoordinate1.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
//        }
//        for (var i=(self.container!.finishedRun!.locations.count/2); i<self.container!.finishedRun!.locations.count; i++) {
//            let location: CLLocation = self.container!.finishedRun!.locations[i];
//            pointsCoordinate2.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
//        }
//        
//        let polyline1: MKPolyline = MKPolyline(coordinates: &pointsCoordinate1, count: self.container!.finishedRun!.locations.count);
//        polyline1.title = "1";
//        self.mapView.addOverlay(polyline1);
//        
//        let polyline2: MKPolyline = MKPolyline(coordinates: &pointsCoordinate2, count: self.container!.finishedRun!.locations.count);
//        polyline2.title = "2";
//        self.mapView.addOverlay(polyline2);
        
        // Set region view of map
        /// Find longest distance horizontal and vertical
        let locTopLeft: CLLocation    = CLLocation(latitude: self.container!.latTop, longitude: self.container!.lonLeft);
        let locBottomLeft: CLLocation = CLLocation(latitude: self.container!.latTop, longitude: self.container!.lonLeft);
        let locTopRight: CLLocation   = CLLocation(latitude: self.container!.latTop, longitude: self.container!.lonRight);
        let distanceLat: Double       = locTopLeft.distanceFromLocation(locBottomLeft);
        let distanceLon: Double       = locTopLeft.distanceFromLocation(locTopRight);
        
        /// Works terrible
        var distanceMargin: Double;
        if (distanceLat > distanceLon) {
            distanceMargin = distanceLat*1;
        }
        else {
            distanceMargin = distanceLon*1;
        }
        
        /// Center map
        let startCoord: CLLocationCoordinate2D = CLLocationCoordinate2DMake((self.container!.latTop+self.container!.latBottom)/2, (self.container!.lonRight+self.container!.lonLeft)/2);
        let adjustedRegion = MKCoordinateRegionMakeWithDistance(startCoord, Double(distanceLat+distanceMargin), Double(distanceLon+distanceMargin));
        self.mapView.setRegion(adjustedRegion, animated: true);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if (overlay.isKindOfClass(MKPolyline)){
            let route: MKPolyline = overlay as MKPolyline;
            var routeRenderer: MKPolylineRenderer = MKPolylineRenderer(polyline: route);
            
            println(route.title);
            if (route.title == "false") {
                routeRenderer.strokeColor = UIColor.redColor();
            } else {
                routeRenderer.strokeColor = UIColor.blueColor();
            }
            return routeRenderer;
        } else {
            return nil;
        }
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
        if (container!.multiplayer) {
            let timeNowInS = NSDate().timeIntervalSince1970;
            if (timeNowInS - self.player2timestamp > 3) {
                self.player2timestamp = timeNowInS;
                
                let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
                let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
                
                let url: NSURL = NSURL(string: "http://marci.dk/epicrunner/locping.php")!;
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
                        
                        let player2lat: Double = dic.objectForKey("lat")!.doubleValue;
                        let player2lon: Double = dic.objectForKey("lon")!.doubleValue;
                        let p2: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: player2lat, longitude: player2lon);
                        self.container!.player2Annotation!.coordinate = p2;
                    }
                    });
                dataTask.resume();
            }
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // If you are showing the users location on the map you don't want to change it
        var view: MKAnnotationView? = nil;
        if (!annotation.isEqual(mapView.userLocation)) {
            // This is not the users location indicator (the blue dot)
            view = mapView.dequeueReusableAnnotationViewWithIdentifier("myAnnotationIdentifier");

            if (view == nil) {
                // Could not reuse a view ...
                // Creating a new annotation view
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotationIdentifier")
            }
            
            // Set image of annotation
            if (annotation.coordinate.latitude == container!.runPointHome?.latitude &&
                annotation.coordinate.longitude == container!.runPointHome?.longitude) {
                    // Home point
                    view!.image = UIImage(named: "home_pin");
            } else {
                if (container!.runTypeId == 1) {
                    // Location run
                    view!.image = UIImage(named: "green_pin");
                } else if (container!.runTypeId == 3) {
                    // Collector run
                    view!.image = UIImage(named: "orange_pin");
                }
            }
        }
        return view;
    }

    
    @IBAction func plusZoom(sender: AnyObject) {
        if (self.mapZoomlevel > 500) {
            self.mapZoomlevel -= 500;
        }
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
            self.mapZoomlevel,
            self.mapZoomlevel);
        self.mapView.setRegion(region, animated: true);
    }
    
    @IBAction func minusZoom(sender: AnyObject) {
        self.mapZoomlevel += 500;
        let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate,
            self.mapZoomlevel,
            self.mapZoomlevel);
        self.mapView.setRegion(region, animated: true);
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
