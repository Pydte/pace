//
//  SignUpViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 08/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet var txtEmail: UITextField!;
    @IBOutlet var txtFullname: UITextField!;
    @IBOutlet var txtPassword: UITextField!;
    @IBOutlet var txtPasswordRepeat: UITextField!;
    @IBOutlet var segGender: UISegmentedControl!;
    @IBOutlet var txtDateDay: UITextField!;
    @IBOutlet var txtDateMonth: UITextField!;
    @IBOutlet var txtDateYear: UITextField!;
    
    override func viewDidLoad() {
        super.viewDidLoad();

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnSignUp(sender: UIButton) {
        func callbackSuccess(data: AnyObject) {
            println("Sign up successful");
            
            let dic: NSDictionary = data as! NSDictionary;
            let id: Int = dic.objectForKey("id")!.integerValue;
            println("id: \(id)");
            
            //Log in this user aka. save userID in db
            let db = SQLiteDB.sharedInstance();
            let query = db.execute("UPDATE settings SET loggedInUserId=\(id), loggedInUsername='\(self.txtEmail.text)'");
            
            //Forward user
            self.performSegueWithIdentifier("segueFromSignUpToApp", sender: self);
        }
        
        println("Signing up");
        

        //Check fields not empty
        if (txtEmail.text == "" || txtPassword.text == "" || txtPasswordRepeat.text == "" || txtFullname.text == "" || txtDateDay.text == "" || txtDateMonth.text == "" || txtDateYear.text == "") {
            println("Something is empty");
            return;
        }
        
        //Check that the passwords are equal
        
        
        //Format birth date
        let dateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "YYYY-MM-DD";
        let birthDate = dateFormatter.dateFromString(NSString(format: "%@-%@-%@", txtDateYear.text, txtDateMonth.text, txtDateDay.text) as String);
        
        //Format gender
        var gender: String;
        if (segGender.selectedSegmentIndex == 0) {
            gender = "male";
        } else {
            gender = "female";
        }
        
        //Send data to server
        let params: String = "email=\(txtEmail.text)&password=\(txtPassword.text)&name=\(txtFullname.text)&gender=\(gender)&birth_date=\(birthDate!.timeIntervalSince1970)";
        HelperFunctions().callWebService("user-create", params: params, callbackSuccess: callbackSuccess, callbackFail: HelperFunctions().webServiceDefaultFail);
    }

    @IBAction func cancelTouched(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldShouldReturn(textField: UITextField) {
        textField.resignFirstResponder();
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
