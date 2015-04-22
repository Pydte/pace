//
//  MainScreenViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class MainScreenViewController: UIViewController {
    let screenName = "main";
    
    @IBOutlet var btnMenu: UIBarButtonItem!;
    @IBOutlet var lblEmail: UILabel!;
    @IBOutlet weak var btnRunSelector: UIButton!;
    
    var level: Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Set active users email
        let db = SQLiteDB.sharedInstance();
        let emailQuery = db.query("SELECT loggedInUserName, loggedInLevel FROM settings");
        let email = emailQuery[0]["loggedInUserName"]!.asString();
        lblEmail.text = email;
        
        self.level = emailQuery[0]["loggedInLevel"]!.asInt();
        if (self.level == 0) {
            btnRunSelector.setTitle("Get Certificate", forState: UIControlState.Normal);
        } else {
            btnRunSelector.setTitle("Run Selector", forState: UIControlState.Normal);
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnRunSelectorTouched(sender: AnyObject) {
        if (self.level == 0) {
            //Get Certificate
            self.performSegueWithIdentifier("segueToTest", sender: self);
        } else {
            //Run Selector
            self.performSegueWithIdentifier("segueToRunSelector", sender: self);
        }
    }
    
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
    }
}
