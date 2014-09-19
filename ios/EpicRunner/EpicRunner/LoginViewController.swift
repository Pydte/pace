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
        println("Logging in..");
        
        //Check not empty fields
        
        //Send data to server
        let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
        
        let url: NSURL = NSURL.URLWithString("http://epicrunner.com.pandiweb.dk/webservice/user-login");
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
        
        let params: String = "email=\(txtEmail.text)&password=\(txtPassword.text)";
        urlRequest.HTTPMethod = "POST";
        urlRequest.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false);
        
        let dataTask: NSURLSessionDataTask = defaultSession.dataTaskWithRequest(urlRequest, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
            //println("Response:\(response)\n");
            if (error == nil) {
                let text: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                println(text);
                
                var error: NSError?
                let dic: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as NSDictionary;
                
                let status: Bool = dic.objectForKey("success").boolValue;
                
                if (status) {
                    println("Sign in successful");
                    
                    let id: Int = dic.objectForKey("id").integerValue;
                    
                    //Save userID in database
                    let db = SQLiteDB.sharedInstance();
                    let query = db.execute("UPDATE settings SET loggedInUserId=\(id)");
                    
                    println("id: \(id)");
                    
                    //Forward user
                    self.performSegueWithIdentifier("segueFromLoginToApp", sender: self);
                } else {
                    println("Mr. Server is not happy.");
                    
                    
                    
                }
                
                
            } else {
                println("Failed to contact server.");
            }
            });
        dataTask.resume();
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
