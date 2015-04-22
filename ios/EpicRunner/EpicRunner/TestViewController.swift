//
//  TestViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 13/02/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    let screenName = "getRunningCertificateIntro"

    @IBOutlet weak var btnMenu: UIBarButtonItem!;
    
    let db = SQLiteDB.sharedInstance();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
    
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDoneTouched(sender: AnyObject) {
        println("simulating done..");
        // Set level local
        self.db.execute("UPDATE settings SET loggedInLevel=1");
        
        // Then post to webservice
        
        // Goto main
        self.performSegueWithIdentifier("segueToMain", sender: self);
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segueStartCalRun") {
            var generateRunViewController: GenerateRunViewController = segue.destinationViewController as GenerateRunViewController;
            //generateRunViewController.runId = 0;
            generateRunViewController.runTypeId = 4;
            generateRunViewController.locRunDistance = 3600;
            generateRunViewController.medalBronze = 2;
            generateRunViewController.medalSilver = 4;
            generateRunViewController.medalGold = 8;
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
}
