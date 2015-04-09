//
//  CustomLoginViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 30/01/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class CustomLoginViewController: UIViewController {
    let screenName = "customLogin";

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func loginTouched(sender: AnyObject) {
        func callbackSuccess(data: AnyObject) {
            println("Sign in successful");
            let dic: NSDictionary = data as NSDictionary;
            let id: Int = dic.objectForKey("id")!.integerValue;
            
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
    
    @IBAction func cancelTouched(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func retrievePasswordTouched(sender: AnyObject) {
        println("retrieve password touched");
    }
    
    func textFieldShouldReturn(textField: UITextField) {
        textField.resignFirstResponder();
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
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
