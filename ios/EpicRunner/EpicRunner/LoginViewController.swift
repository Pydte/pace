//
//  LoginViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 08/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FBLoginViewDelegate {
    let screenName = "login";

    @IBOutlet weak var fbLoginView: FBLoginView!;
    var doOnce: Bool = false;
    var email: String = "";
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        //FB settings
        self.fbLoginView.delegate = self;
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends"];
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
        
        //Check if the user already is logged in.
        let db = SQLiteDB.sharedInstance();
        let query = db.query("SELECT loggedInUserId FROM settings");
        let userID = query[0]["loggedInUserId"]!.asInt();
        
        //if userID == null in db => userID = 0
        if (userID != 0) {
            //Redirect user to app
            println("User already logged in");
            self.performSegueWithIdentifier("segueFromLoginToApp", sender: self);
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginViewFetchedUserInfo(loginView: FBLoginView!, user: FBGraphUser) {
        //Set email
        self.email = user.objectForKey("email") as String;
        //self.email = "jr@pandisign.dk";
        println("**setting email : \(self.email)**");
        
        
        //println("Hello \(user.first_name) \(user.last_name)");
        //println(user.objectForKey("id")); (unique user id)
        //println(user);
    }
    
    func loginViewShowingLoggedInUser(loginView: FBLoginView!) {
        func callbackSuccess(data: AnyObject) {
            println("Sign in successful");
            let json = JSON(data)
            let sessionToken2: String = json["session_token"].string!;
            println(sessionToken2);
            
            let dic: NSDictionary = data as NSDictionary;
            let id = 6;
            //let id: Int = json["id"].intValue;
            let level: Int = json["level"].intValue;
            let tuRunSelector: Int = json["tutorial_completed"].intValue;
            let sessionToken: String = json["session_token"].stringValue;
            
            //Save userID & session_token in database
            let db = SQLiteDB.sharedInstance();
            let query = db.execute("UPDATE settings SET loggedInUserId=\(id), loggedInUsername='\(self.email)', loggedInSessionToken='\(sessionToken)', loggedInLevel=\(level), loggedInTuRunSelector=\(tuRunSelector)");
            
            println("id: \(id)");
            
            //Forward user
            self.performSegueWithIdentifier("segueFromLoginToApp", sender: self);
        }
        func callbackFailure(err: String) {
            // Something went wrong with authenticating with the epicrunner servers.
            println("Rolling back buddy..");
            
            // "Roll back"
            FBSession.activeSession().closeAndClearTokenInformation();
            loginView.hidden = false;
            self.doOnce = false;
            
            // Be informative
            HelperFunctions().webServiceDefaultFail(err);
        }
        
        // To avoid the code being run multiple times!
        if (!self.doOnce) {
            self.doOnce = true;
            loginView.hidden = true;
            
            println("Facebook succeeded locally.");
            println("Authenticating with EpicRunner servers..")
            var FBAuthToken = FBSession.activeSession().accessTokenData.accessToken;
            println(FBAuthToken);
            
            // Do webservice call with fbAuthToken
            HelperFunctions().callWebService("fb-login", params: "email=" + self.email + "&auth_token=" + FBAuthToken, callbackSuccess: callbackSuccess, callbackFail: callbackFailure);
            
            println("\"Done\"");
        }
    }
    
    func loginViewHandleError(loginView: FBLoginView!, error: NSError) {
        println("Facebook authentication fucked up :)");
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
