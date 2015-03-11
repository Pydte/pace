//
//  RunScreenContainerViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/10/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import MapKit

class RunScreenContainerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var intController: RunScreenContainerIntervalViewController?;
    var cerController: RunScreenContainerCertificateViewController?;
    
    var leftController: UIViewController?;
    var rightController: RunScreenContainerRightViewController?;
    var showing: Int = 0;
    var finishedRun: Run? = nil;
    
    @IBOutlet weak var lblDuration: UILabel!;
    @IBOutlet weak var lblDistance: UILabel!;
    @IBOutlet weak var lblSpeed: UILabel!;
    @IBOutlet weak var lblSpeedDesc: UILabel!;
    @IBOutlet weak var lblMedal: UILabel!;
    
    
    // Shared
    var multiplayer: Bool = false;
    var runTypeId: Int = 0;
    var medalBronze: Int = 0;
    var medalSilver: Int = 0;
    var medalGold: Int = 0;
    var runPointHome: CLLocationCoordinate2D? = nil; //Is set from other controller
    var runPoints: [CLLocationCoordinate2D] = [];    //Is set from other controller
    var runPointHomeAnno: MKPointAnnotation? = nil;
    var runPointsAnno: [MKPointAnnotation] = [];
    
    /// Location Run
    var locRunActive: Bool = false;
    var locRunPointA: CLLocationCoordinate2D? = nil;
    var locRunPointB: CLLocationCoordinate2D? = nil;
    var locRunNextPointAnno: MKPointAnnotation = MKPointAnnotation();
    /// Multiplayer
    var player2Annotation: MKPointAnnotation?;
    //Interval Run
    var intPassed: [Bool] = [];
    var intLocNumAtIntEnd: [Int] = [];            // Used to draw each interval on the map
    
    // Stats
    var latTop: Double    = -999999;  // Extreme coordinates
    var lonRight: Double  = -999999;  // Extreme coordinates
    var latBottom: Double = 999999;   // Extreme coordinates
    var lonLeft: Double   = 999999;   // Extreme coordinates
    var avgSpeed: Double    = 0.0;    // In min/km
    var minAltitude: Double = 999999;
    var maxAltitude: Double = -999999;
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // If Interval run, show custom "default container"
        if (self.runTypeId == 2) {
            intController = self.storyboard?.instantiateViewControllerWithIdentifier("RSCInterval") as? RunScreenContainerIntervalViewController;
            intController!.view.frame.origin.x += 25;
            intController!.view.frame.size.width -= 50;
            self.view.addSubview(intController!.view);
        }
        
        // If Certificate run, show custom "default container"
        if (self.runTypeId == 4) {
            cerController = self.storyboard?.instantiateViewControllerWithIdentifier("RSCCertificate") as? RunScreenContainerCertificateViewController;
            cerController!.view.frame.origin.x += 25;
            cerController!.view.frame.size.width -= 50;
            self.view.addSubview(cerController!.view);
        }
        
        // Init obj & map screen
        leftController = self.storyboard?.instantiateViewControllerWithIdentifier("left") as? UIViewController;
        rightController = self.storyboard?.instantiateViewControllerWithIdentifier("right") as? RunScreenContainerRightViewController;
        self.addChildViewController(leftController!);
        self.addChildViewController(rightController!);
        
        // Set position outside of view
        leftController!.view.frame.origin.x = -leftController!.view.frame.width;
        rightController!.view.frame.origin.x = rightController!.view.frame.width;
        
        // Add view
        self.view.addSubview(leftController!.view);
        self.view.addSubview(rightController!.view);
        
        
        // Gesture left
        var left: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "left:");
        left.edges = UIRectEdge.Left;
        left.delegate = self;
        self.view.addGestureRecognizer(left);
        
        // Gesture right
        var right: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "right:");
        right.edges = UIRectEdge.Right;
        right.delegate = self;
        self.view.addGestureRecognizer(right);
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //LeftToRight
    func left(gesture: UIScreenEdgePanGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.Began) {
            if (self.showing == 0) {
                // Show
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                        self.leftController!.view.frame.origin.x = 0;
                    }, completion: nil);
            } else if (self.showing == 1) {
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.rightController!.view.frame.origin.x = self.rightController!.view.frame.width;
                    }, completion: nil);
            }
            
            if (self.showing > -1) {
                self.showing -= 1;
            }
        }
    }
    
    //RightToLeft
    func right(gesture: UIScreenEdgePanGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.Began) {
            // Show
            if (self.showing == 0) {
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.rightController!.view.frame.origin.x = 0;
                    }, completion: nil);
            } else if (self.showing == -1) {
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.leftController!.view.frame.origin.x = -self.leftController!.view.frame.width;
                    }, completion: nil);
            }
            
            if (self.showing < 1) {
                self.showing += 1;
            }
        }
    }
    
    func showHomeAnno() {
        self.rightController!.mapView.addAnnotation(self.runPointHomeAnno);
    }
    
    func hideHomeAnno() {
        self.rightController!.mapView.removeAnnotation(self.runPointHomeAnno);
    }
    
    func showPointsAnno() {
        for anno in self.runPointsAnno {
            self.rightController!.mapView.addAnnotation(anno);
        }
    }
    
    func hidePointsAnno() {
        for anno in self.runPointsAnno {
            self.rightController!.mapView.removeAnnotation(anno);
        }
    }
    
    func removePoint(pos: CLLocationCoordinate2D) {
        var i: Int = 0;
        for point in self.runPoints {
            if (pos.latitude == point.latitude && pos.longitude == point.longitude) {
                break;
            }
            i++;
        }
        self.rightController!.mapView.removeAnnotation(self.runPointsAnno[i]);
        self.runPoints.removeAtIndex(i);
        self.runPointsAnno.removeAtIndex(i);
    }
    
    func runFinishedInterval(run: Run, intPassed: [Bool], intLocNumAtIntEnd: [Int]) {
        self.intPassed = intPassed;
        self.intLocNumAtIntEnd = intLocNumAtIntEnd;
        runFinished(run);
    }
    
    func runFinished(run: Run) {
        self.finishedRun = run;
        
        // * Change speed to avg speed
        lblSpeedDesc.text = "Avg speed:";
        lblSpeed.text = NSString(format: "%.2f", self.avgSpeed);
        
        // * Draw route on map
        self.rightController!.drawRoute();
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
