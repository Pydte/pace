//
//  LoginViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 08/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var txtEmail: UITextField
    @IBOutlet var txtPassword: UITextField
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewWillAppear(animated);
        
        //Check if the user already is logged in.
        let db = SQLiteDB.sharedInstance();
        let query = db.query("SELECT loggedInUserId FROM settings");
        let userID = query[0]["loggedInUserId"]!.integer;
        
        //if userID == null in db => userID = 0
        if (userID != 0) {
            //Redirect user to app
            println("User already logged in");
            self.performSegueWithIdentifier("segueFromLoginToApp", sender: self);
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnLogIn(sender: UIButton) {
        func callbackSuccess(data: AnyObject) {
            println("Sign in successful");
            let dic: NSDictionary = data as NSDictionary;
            let id: Int = dic.objectForKey("id").integerValue;
            
            //Save userID in database
            let db = SQLiteDB.sharedInstance();
            let query = db.execute("UPDATE settings SET loggedInUserId=\(id), loggedInUsername='\(self.txtEmail.text)'");
            
            println("id: \(id)");
            
            //Forward user
            self.performSegueWithIdentifier("segueFromLoginToApp", sender: self);
        }
        
        println("Logging in..");
        
        //Check not empty fields
        
        //Send data to server
        HelperFunctions().callWebService("user-login", params: "email=\(txtEmail.text)&password=\(txtPassword.text)", callbackSuccess: callbackSuccess, callbackFail: HelperFunctions().webServiceDefaultFail);
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
