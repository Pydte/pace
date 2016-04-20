//
//  DashboardViewController.swift
//  Pace
//
//  Created by Jeppe Richardt on 25/12/15.
//  Copyright © 2015 Pandigames. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController {
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    
    @IBOutlet weak var bgImg: UIImageView!
    
    // Btn Run Selector
    @IBOutlet weak var btnRS: UIButton!
    var rsCurrentLocX: CGFloat = 0.0;
    var rsDefaultLocX: CGFloat = 0.0;
    var rsActivated: Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("dashboard init")
        
        // Bind menu button
        if self.revealViewController() != nil {
            self.menuBtn.target = self.revealViewController();
            self.menuBtn.action = "revealToggle:";
            self.navigationController?.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        }
        
        // Transparent navigation bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        
        // Run Selector Button
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLPRunSelector:");
        longPress.minimumPressDuration = 0.001;
        self.btnRS.addGestureRecognizer(longPress);
    }
    deinit { print("dashboard is being deinitialized") }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.rsDefaultLocX = btnRS.frame.origin.x;
    }
    
    func handleLPRunSelector(recognizer: UILongPressGestureRecognizer) {
        // Note: Contraints are fucking with it.. 
        let point: CGPoint = recognizer.locationInView(self.view);
        var toUnlock: Bool = false;
        
        // Check for dropzone
        if (self.btnRS.frame.origin.x <= 30) {
            //Unlock
            print("DROP ZONE");
            toUnlock = true
            self.btnRS.center.x = point.x - self.rsCurrentLocX;
        } else {
            toUnlock = false;
            self.btnRS.center.x = point.x - self.rsCurrentLocX;
        }
        
        switch recognizer.state {
        case UIGestureRecognizerState.Changed:
            //if (!toUnlock) {
                // Move to touched position
                self.btnRS.center.x = point.x - self.rsCurrentLocX;
            //}
        case UIGestureRecognizerState.Ended:
            if (!toUnlock) {
                //Restore pos
                UIView.animateWithDuration(0.5,
                    delay: 0.1,
                    options: .CurveEaseOut,
                    animations: { _ in
                        self.btnRS.frame.origin.x = self.rsDefaultLocX;
                    },
                    completion: { _ in
                });
            } else {
                self.performSegueWithIdentifier("segueRunSelector", sender: self)
            }
        default:
            ();
        }
        
        //self.rsCurrentLocX = point.x;
    }
    
    
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
