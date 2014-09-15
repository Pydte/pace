//
//  SignUpViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 08/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet var txtEmail: UITextField
    @IBOutlet var txtFullname: UITextField
    @IBOutlet var txtPassword: UITextField
    @IBOutlet var txtPasswordRepeat: UITextField
    @IBOutlet var segGender: UISegmentedControl
    @IBOutlet var txtDateDay: UITextField
    @IBOutlet var txtDateMonth: UITextField
    @IBOutlet var txtDateYear: UITextField
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnSignUp(sender: UIButton) {
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
        let birthDate = dateFormatter.dateFromString(NSString(format: "%@-%@-%@", txtDateYear.text, txtDateMonth.text, txtDateDay.text));
        
        //Format gender
        var gender: String;
        if (segGender.selectedSegmentIndex == 0) {
            gender = "male";
        } else {
            gender = "female";
        }
        
        //Send data to server
        let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
        
        let url: NSURL = NSURL.URLWithString("http://epicrunner.com.pandiweb.dk/webservice/user-create");
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
        
        //let params: String = "email=test@test.dk&password=pass&name=Test&gender=male&birth_date=0";
        let params: String = "email=\(txtEmail.text)&password=\(txtPassword.text)&name=\(txtFullname.text)&gender=\(gender)&birth_date=\(birthDate.timeIntervalSince1970)";
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
                    println("Sign up successful");
                    
                    let id: Int = dic.objectForKey("id").integerValue;
                    println("id: \(id)");
                    
                    //Forward user
                    self.performSegueWithIdentifier("segueFromSignUpToApp", sender: self);
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
