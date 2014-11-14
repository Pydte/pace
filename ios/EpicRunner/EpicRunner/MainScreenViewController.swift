//
//  MainScreenViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class MainScreenViewControllerSwift: UIViewController {
    @IBOutlet var btnMenu: UIBarButtonItem!;
    @IBOutlet var lblEmail: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Set active users email
        let db = SQLiteDB.sharedInstance();
        let emailQuery = db.query("SELECT loggedInUserName FROM settings");
        let email = emailQuery[0]["loggedInUserName"]!.asString();
        lblEmail.text = email;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
    }
}
