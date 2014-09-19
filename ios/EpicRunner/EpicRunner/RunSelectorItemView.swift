//
//  RunSelectorItemView.swift
//  EpicRunner
//
//  Created by Jeppe on 15/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class RunSelectorItemView: UIView {
    var originalLoc: CGPoint = CGPoint();
    var currentLoc: CGPoint = CGPoint();
    var toBeDeleted: Bool = false;
    var lblTimeBar: UILabel = UILabel(frame: CGRectMake(0, 38, 0, 3));
    let secBetweenTicks = 1.0;
    var tickTimer: NSTimer?;
    let startDate: NSDate;
    let endDate: NSDate;
    let totalTime: NSTimeInterval;
    var destroyed = false;
    var runId: Int = 0;
    
    init(frame: CGRect, runId: Int, type: String, startDate: NSDate, endDate: NSDate, difficulty: Int, distance: Int) {
        self.startDate = startDate;
        self.endDate = endDate;
        self.totalTime = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970;
        
        super.init(frame: frame);
        
        // Initialization code
        self.originalLoc = self.frame.origin;
        self.userInteractionEnabled = true;
        self.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0);
        self.runId = runId
        
        // Add timebar
        self.lblTimeBar.contentMode = UIViewContentMode.ScaleToFill;
        self.addSubview(self.lblTimeBar);
        
        // Add type
        let lblType = UILabel(frame: CGRectMake(10, 0, 150, self.frame.size.height));
        lblType.text = type;
        self.addSubview(lblType);
        
        // Add difficulty
        let lblDiff = UILabel(frame: CGRectMake(self.frame.size.width-30, self.frame.size.height/2-7, 14, 14));
        lblType.text = type;
        if (difficulty == 1) {
            lblDiff.backgroundColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0);
        } else if (difficulty == 2) {
            lblDiff.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.2, alpha: 1.0);
        } else if (difficulty == 3) {
            lblDiff.backgroundColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0);
        }
        self.addSubview(lblDiff);
        
        // Add distance
        let lblDist = UILabel(frame: CGRectMake(160, 0, 100, self.frame.size.height));
        lblDist.text = "≈\(distance) km";
        self.addSubview(lblDist);
        
        
        // Register long press
        var longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:");
        longPress.minimumPressDuration = 1.0;
        self.addGestureRecognizer(longPress);
        
        // Tick
        self.tickTimer = NSTimer.scheduledTimerWithTimeInterval(self.secBetweenTicks, target: self, selector: "tick", userInfo: nil, repeats: true);
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        // On touch open detail view
        let h = superview.nextResponder() as RunSelectorViewControllerSwift;
        h.selectedRunId = self.runId;
        h.performSegueWithIdentifier("segueDetailView", sender: self);
    }
    
    func move(relative: Bool, coord: CGPoint) {
        UIView.animateWithDuration(0.5,
            delay: 0.1,
            options: .CurveEaseOut,
            animations: { _ in
                if (relative) {
                    self.frame.origin.x += coord.x;
                    self.frame.origin.y += coord.y;
                } else {
                    self.frame.origin.x = coord.x;
                    self.frame.origin.y = coord.y;
                }
                
                // Save current location as "original"
                self.originalLoc = self.frame.origin;
            },
            completion: { _ in
                println("move of item completed");
            });
    }

    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = recognizer.locationInView(self.superview);
        
        switch recognizer.state {
        case UIGestureRecognizerState.Changed:
            // Move to touched position
            self.center.x += point.x - self.currentLoc.x;
            self.center.y += point.y - self.currentLoc.y;
            
            // Check for dropzone
            if (self.frame.origin.y > 320 && self.frame.origin.y < 345) {
                self.toBeDeleted = true;
                self.backgroundColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0);
            } else {
                self.toBeDeleted = false;
                self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0);
            }
            
        case UIGestureRecognizerState.Began:
            println("LONG PRESS BEGAN");
            self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0);
            self.layer.zPosition = 99;
            
        case UIGestureRecognizerState.Ended:
            println("LONG PRESS ENDED");
            self.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0);
            self.layer.zPosition = 1;
            
            // Check for dropzone
            if (self.toBeDeleted) {
                destroy();
            } else {
                //  Restore position
                UIView.animateWithDuration(0.5,
                    delay: 0.1,
                    options: .CurveEaseOut,
                    animations: { _ in
                        self.frame.origin = self.originalLoc;
                    },
                    completion: { _ in
                        println("item pos restored");
                    }
                );
            }
            
        default:
            ();
        }
        
        self.currentLoc = point;
    }
    
    func tick() -> Bool {
        // In % how close to end date
        let curDate = NSDate.date().timeIntervalSince1970;
        let t = (curDate - self.startDate.timeIntervalSince1970) / self.totalTime * 100;
        
        if (t > 100) {
            // 100 %, we're done
            
            // No more ticks are needed
            self.tickTimer?.invalidate();
        
            destroy();
            
            println("My time is up on this planet! [item commits suicide]");
            
            return true;
            
        } else if (t > 90) {
            // Above 90 %, make red, add progress
            self.lblTimeBar.backgroundColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0);
        } else if (t > 75) {
            // Above 75 %, make yellow, add progress
            self.lblTimeBar.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.2, alpha: 1.0);
        } else {
            // All fine, add progress
            self.lblTimeBar.backgroundColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0);
        }
        
        
        if (curDate > self.startDate.timeIntervalSince1970) {
            // That % in pixels of the timebars size
            let h = CGFloat.bridgeFromObjectiveC(t)
            var p = self.frame.size.width / 100 * h;
            
            if (p > self.frame.size.width) {
                p = self.frame.size.width;
            }
            
            
            UIView.animateWithDuration(self.secBetweenTicks,
                delay: 0.0,
                options: .CurveLinear,
                animations: { _ in
                    self.lblTimeBar.frame.size.width = p;
                },
                completion: { _ in ()}
                );
        }
        
        return false;
    }
    
    func destroy() {
        if (!destroyed) {
        // Clean up timer (we want no memory leak, yirks!)
        self.tickTimer?.invalidate();
        self.tickTimer = nil;
        
        // Let the controller know that i'm out
        let h = superview.nextResponder() as RunSelectorViewControllerSwift;
        h.itemKilled();
            
        // To avoid the rediculous case where the destroy function already is scheduled 
        // and then gets called before the scheduled one
        destroyed = true;
        
        // Commit suicide
        self.removeFromSuperview();
        }
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

}
