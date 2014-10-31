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
    
    var leftController: UIViewController?;
    var rightController: UIViewController?;
    var showing: Int = 0;
    
    @IBOutlet var lblDuration: UILabel
    @IBOutlet var lblDistance: UILabel
    @IBOutlet var lblSpeed: UILabel
    @IBOutlet var lblMedal: UILabel
    
    
    // Shared
    var multiplayer: Bool = false;
    var runTypeId: Int = 0;
    var medalBronze: Int = 0;
    var medalSilver: Int = 0;
    var medalGold: Int = 0;
    
    /// Location Run
    var locRunActive: Bool = false;
    var locRunPointA: CLLocationCoordinate2D? = nil;
    var locRunPointB: CLLocationCoordinate2D? = nil;
    var locRunNextPointAnno: MKPointAnnotation = MKPointAnnotation();
    /// Multiplayer
    var player2Annotation: MKPointAnnotation?;
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        leftController = self.storyboard.instantiateViewControllerWithIdentifier("left") as? UIViewController;
        rightController = self.storyboard.instantiateViewControllerWithIdentifier("right") as? RunScreenContainerRightViewController;
        self.addChildViewController(leftController);
        self.addChildViewController(rightController);
        
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
    
    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
