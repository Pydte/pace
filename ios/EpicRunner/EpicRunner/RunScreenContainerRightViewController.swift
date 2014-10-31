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

    @IBOutlet var mapView: MKMapView
    
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
        
        // Location run
        if (container!.locRunActive) {
            // Draw point B on map
            container!.locRunNextPointAnno.coordinate = container!.locRunPointB!;
            self.mapView.addAnnotation(container!.locRunNextPointAnno);
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
        if (container!.multiplayer) {
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
            if (!view) {
                // Could not reuse a view ...
                
                // Creating a new annotation view
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotationIdentifier")
                
                // This will rescale the annotation view to fit the image
                view!.image = UIImage(named: "green_pin");
            }
        }
        return view;
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
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
