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
    let screenName = "runScreenContainerMap";

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
            container!.player2Annotation!.subtitle = "p2";
            self.mapView.addAnnotation(container!.player2Annotation);
        }
        
        
        // Specific per run type
        if (container!.runTypeId == 1) {
            println("map: location run");
            // Location run
            // Draw point B on map
            container!.locRunNextPointAnno.coordinate = container!.runPoints[0];
            container!.locRunNextPointAnno.subtitle = "point";
            self.mapView.addAnnotation(container!.locRunNextPointAnno);
        
        
        
        } else if (container!.runTypeId == 2) {
            // Interval run
           
            
            
            
            
        } else if (container!.runTypeId == 3) {
            println("map: collector run");
            // Collector run
            // Draw home point
            self.container!.runPointHomeAnno = MKPointAnnotation();
            self.container!.runPointHomeAnno!.coordinate = container!.runPointHome!;
            self.container!.runPointHomeAnno!.subtitle = "collectorPoint";
            //self.mapView.addAnnotation(self.container!.runPointHomeAnno);
            
            // Draw all points to collect
            for pointCoord in container!.runPoints {
                var mkPointAnno2: MKPointAnnotation = MKPointAnnotation();
                mkPointAnno2.coordinate = pointCoord;
                mkPointAnno2.subtitle = "point";
                container!.runPointsAnno.append(mkPointAnno2);
                self.mapView.addAnnotation(mkPointAnno2);
            }
            
            
            
        } else if (container!.runTypeId == 4) {
            println("map: collector run");
            // Collector run
            // Draw home point
            self.container!.runPointHomeAnno = MKPointAnnotation();
            self.container!.runPointHomeAnno!.coordinate = container!.runPointHome!;
            self.container!.runPointHomeAnno!.subtitle = "collectorPoint";
            //self.mapView.addAnnotation(self.container!.runPointHomeAnno);
            
            // Draw all points to collect
            for pointCoord in container!.runPoints {
                var mkPointAnno2: MKPointAnnotation = MKPointAnnotation();
                mkPointAnno2.coordinate = pointCoord;
                mkPointAnno2.subtitle = "point";
                container!.runPointsAnno.append(mkPointAnno2);
                self.mapView.addAnnotation(mkPointAnno2);
            }
        }
       
    }
    
    func drawRoute() {
        //Hide user location & enable user interaction
        self.mapView.showsUserLocation = false;
        self.mapView.userInteractionEnabled = true;
        self.mapView.scrollEnabled = true;
        self.mapView.zoomEnabled = true;
        
        //Spawn invisible "border" at the left, to allow swipe left to right (ortherwise one would scroll the map)
        println("view");
        var borderView: UIView = UIView();
        borderView.alpha = 0.1;
        borderView.backgroundColor = UIColor.grayColor();
        borderView.frame.size.width = 20;
        borderView.frame.size.height = self.view.frame.height;
        borderView.frame.origin.x = 0;
        borderView.frame.origin.y = 0;
        self.view.addSubview(borderView);
        self.view.bringSubviewToFront(borderView);
        println("spawned");
        
        //Draw route, if interval run
        for (var i=0; i<container!.intLocNumAtIntEnd.count; i++){
            var pointsCoordinate: [CLLocationCoordinate2D] = [];
            
            var startIndex: Int = 0;
            var endIndex: Int = self.container!.intLocNumAtIntEnd[i];
            if (i>0) {
                startIndex = self.container!.intLocNumAtIntEnd[i-1]-1;
                
                // Place annotations (separators) between each interval
                var mkPointAnno: MKPointAnnotation = MKPointAnnotation();
                let location: CLLocation = self.container!.finishedRun!.locations[self.container!.intLocNumAtIntEnd[i-1]-1];
                mkPointAnno.coordinate = location.coordinate;
                mkPointAnno.subtitle = "intSeparator";
                //container!.runPointsAnno.append(mkPointAnno);
                self.mapView.addAnnotation(mkPointAnno);
            }

            for (var j=startIndex; j<endIndex; j++) {
                let location: CLLocation = self.container!.finishedRun!.locations[j];
                pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
            }

            //FAILS ON ARCHIVE - IF "C" IS NOT STATIC INT??
            let c: Int = 5; //endIndex-startIndex;
            var polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: c);
            polyline.title = "\(self.container!.intPassed[i])";
            self.mapView.addOverlay(polyline);
            
        }
        // Draw route, if not interval run
        if (container!.intLocNumAtIntEnd.count == 0) {
            var pointsCoordinate: [CLLocationCoordinate2D] = [];
            for (var j=0; j<self.container!.finishedRun!.locations.count; j++) {
                let location: CLLocation = self.container!.finishedRun!.locations[j];
                pointsCoordinate.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude));
            }
            
            let polyline: MKPolyline = MKPolyline(coordinates: &pointsCoordinate, count: self.container!.finishedRun!.locations.count);
            polyline.title = "true";
            self.mapView.addOverlay(polyline);
        }
        
        
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
            
            routeRenderer.lineCap = kCGLineCapRound;
            routeRenderer.lineWidth = 5.0;
            
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
            if annotation.subtitle != nil {
                if (annotation.subtitle == "intSeparator") {
                    view!.image = UIImage(named: "separatorLine");
                } else {
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
                        } else if (container!.runTypeId == 4) {
                            // Certificate run
                            view!.image = UIImage(named: "orange_pin");
                        }
                    }
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
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
