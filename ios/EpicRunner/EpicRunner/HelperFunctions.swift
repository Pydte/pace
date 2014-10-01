//
//  HelperFunctions.swift
//  EpicRunner
//
//  Created by Jeppe on 29/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

// import UIKit


class HelperFunctions {
    
    // A function which contacts the server and sends the response to the callback function
    func callWebService(serviceName: String, params: String, callbackSuccess: (AnyObject) -> Void, callbackFail: (String) -> Void) {
        let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
        
        let url: NSURL = NSURL.URLWithString("http://epicrunner.com.pandiweb.dk/webservice/\(serviceName)");
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
        urlRequest.HTTPMethod = "POST";
        urlRequest.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false);
        
        let dataTask: NSURLSessionDataTask = defaultSession.dataTaskWithRequest(urlRequest, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
            
            if (error == nil) {
                let text: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                //println(text);
                
                var error: NSError?
                let dic: NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? NSDictionary;
                if (dic != nil) {
                    let status: Bool = dic!.objectForKey("success").boolValue;
                    
                    if (status) {
                        println("Server contact successful");
                        callbackSuccess(dic!);
                    } else {
                        println("Mr. Server is not happy.");
                        
                        let errArr: NSArray = dic!.objectForKey("errors") as NSArray;
                        callbackFail(errArr[0] as String);
                    }
                } else {
                    println("Mr. Server went full retard.");
                    callbackFail("Mr. Server went full retard1.");
                }
                
            } else {
                println("Failed to contact server.");
                callbackFail("Failed to contact server1.");
            }
            });
        dataTask.resume();
    
    }
    
    // A default error function to give the "callWebService" function, if ones doesn't really care ¯\_(ツ)_/¯
    func webServiceDefaultFail(err: String) {
        var alert: UIAlertView = UIAlertView()
        alert.title = "Error"
        alert.message = err
        alert.addButtonWithTitle("Ok")
        
        alert.show()
    }
   
}
