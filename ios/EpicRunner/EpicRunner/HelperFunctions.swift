//
//  HelperFunctions.swift
//  EpicRunner
//
//  Created by Jeppe on 29/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import CoreLocation



class HelperFunctions {
    let db = SQLiteDB.sharedInstance();
    
    // 0: Free Run
    // 1: Location Run
    // 2: Interval Run
    // 3: Collector Run
    let runHeadline: [String] = ["Free Run", "Location Run", "Interval Run", "Collector Run", "Certificate Run"];
    let runDescription: [String] = ["Run anywhere in any pace you want. When you are done, you simply touch the stop button.",
        "You have to run from point A to point B and back to point A. Point A is your current physical location when you press 'Generate mission', while point B is a location of our choosing.",
        "You have to run x intervals, which is made up of two parts; one part walking and one part sprinting. This is a radically different way of running, one of constant high intensity rather than medium, long-term load.",
        "You have to collect a series of objects and return them to your base (starting point). Each time an object is collected it must be returned to the base. An object is effectively collected by running through its position on the map and is registered as 'collected' by running through the 'base' point on the map. There is no specific order to collect the objects in, but you can only carry one object at the time.",
        "You have to collect a series of objects and return them to your base (starting point). Each time an object is collected it must be returned to the base. Collect as many as you can within the time limit."];
    let runMedal: [String] = ["None", "Gold", "Silver", "Bronze"];
    
    // ONLY USED TO TEST
    func callWebService2(serviceName: String, params: String, callbackSuccess: (AnyObject) -> Void, callbackFail: (String) -> Void, controller: UIViewController) {
        let toViewController: UIViewController = MainScreenViewController();
        
        //controller.presentViewController(toViewController, animated: true, completion: nil);
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
        storyboard.instantiateViewControllerWithIdentifier("MainScreenController");
        controller.navigationController!.pushViewController(toViewController, animated: true);
        
    }
    
    // A function which contacts the server and sends the response to the callback function
    func callWebService(serviceName: String, params: String, callbackSuccess: (AnyObject) -> Void, callbackFail: (String) -> Void) {
        let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
        
        let url: NSURL = NSURL(string: "http://epicrunner.dk.panditest.dk/webservice/\(serviceName)")!;
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
        urlRequest.HTTPMethod = "POST";
        urlRequest.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false);
        
        let dataTask: NSURLSessionDataTask = defaultSession.dataTaskWithRequest(urlRequest, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
            
            if (error == nil) {
                let text: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)!;
                //println(text);
                
                var error: NSError?
                let dic: NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? NSDictionary;
                if (dic != nil) {
                    let status: Bool = dic!.objectForKey("success")!.boolValue;
                    
                    if (status) {
                        println("Server contact successful");
                        callbackSuccess(dic!);
                    } else {
                        println("Mr. Server is not happy.");
                        
                        let err: AnyObject? = dic!.objectForKey("errors");
                        var errStr: String = "No error description provided.";
                        if (err != nil) {
                            errStr = (err as! NSArray)[0] as! String;
                        }
                        
                        self.handleSharedMistakes(errStr, callbackFail: callbackFail); // Will call the callback function, if appropriet
                    }
                } else {
                    println("The server did not respond with a valid response.");
                    self.statError("The server did not respond with a valid response.");
                    println(text);
                    callbackFail("The server did not respond with a valid response.");
                }
                
            } else {
                println("Failed to contact server: \(error.description)");
                self.statError("Failed to contact server: \(error.description)");
                callbackFail("Failed to contact server1.");
            }
            });
        dataTask.resume();
    
    }
    
    // A default error function to give the "callWebService" function, if one doesn't really care ¯\_(ツ)_/¯
    func webServiceDefaultFail(err: String) {
        var alert: UIAlertView = UIAlertView();
        alert.title = "Error";
        alert.message = err;
        alert.addButtonWithTitle("Ok");
        
        alert.show();
    }
    
    // Handles shared/common mistakes, like if the sessession has expired etc.
    // If no matches, it calls the supplied callbackFail
    func handleSharedMistakes(err: String, callbackFail: (String) -> Void) {
        self.statError("Webservice: " + err);
        
        switch err {
            case "Session expired.":
                println("ERROR: Session Expired");
                // Update local db to not logged in
            
                // Goto login screen
                //let toViewController: UIViewController = LoginViewController();
                //let segue: UIStoryboard = UIStoryboardSegue(identifier: "Logout", source: nil, destination: toViewController);
                //prepareForSegue(segue, sender: nil);
                //segue.perform();
                
                // Show message "You have been logged out, please log in again."
                webServiceDefaultFail("You have to manually log out and then log in again, for security reasons.")
            default:
                callbackFail(err);
        }
    }
    
    // Converts degrees to radians
    func radiansFromDegrees(degrees: Double) -> Double {
        return degrees * (M_PI/180.0);
    }
    
    // Converts redians to degrees
    func degreesFromRadians(radians: Double) -> Double {
        return radians * (180.0/M_PI);
    }
    
    // Returns a CLLocationCoordinate2D X km away in bearing Y.
    func coordinateFromCoord(fromCoord: CLLocationCoordinate2D, distanceKm: Double, bearingDegrees: Double) -> CLLocationCoordinate2D {
        let distanceRadians: Double = distanceKm / 6371.0;
        //6,371 = Earth's radius in km
        let bearingRadians: Double = radiansFromDegrees(bearingDegrees);
        let fromLatRadians: Double = radiansFromDegrees(fromCoord.latitude);
        let fromLonRadians: Double = radiansFromDegrees(fromCoord.longitude);
        
        let toLatRadians: Double = asin( sin(fromLatRadians) * cos(distanceRadians)
            + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
        
        var toLonRadians: Double = fromLonRadians + atan2(sin(bearingRadians)
            * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
                - sin(fromLatRadians) * sin(toLatRadians));
        
        // adjust toLonRadians to be in the range -180 to +180...
        toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
        
        let result: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:  degreesFromRadians(toLatRadians), longitude: degreesFromRadians(toLonRadians));
        return result;
    }
    
    // Takes secs and returns "MM:SS"
    func formatSecToMinSec(secs: Int) -> String {
        let runTimeInMinutes: Double = Double(secs) / Double(60);
        let runRemainingTimeInSeconds: Double = fmod(Double(secs), 60);
        let runTimeInMinutesFormat = NSString(format: "%02d", Int(runTimeInMinutes));
        let runRemainingTimeInSecondsFormat = NSString(format: "%02d", Int(runRemainingTimeInSeconds));
        return "\(runTimeInMinutesFormat):\(runRemainingTimeInSecondsFormat)";
    }
    
    
    /// Statistics
    // STAT: Create new session
    func statNewSession() {
        let deviceId = UIDevice.currentDevice().identifierForVendor.UUIDString;
        let deviceType = Hardware().toString();
        let os = UIDevice.currentDevice().systemVersion;
        let timestamp = NSDate().timeIntervalSince1970;
        
        self.db.execute("INSERT INTO stat_session (deviceId, deviceType, os, userId, timestamp) VALUES ('\(deviceId)','\(deviceType)','\(os)',(SELECT loggedInUserId FROM settings),\(timestamp))");
        
        println("STAT New Session: \(deviceId), \(deviceType), \(os), \(timestamp)");
    }

    // STAT: Update userId for Session
    func updateUserIdForSession() {
        println("STAT Update UserID for Session");
        
    }
    
    // STAT: Screen Entered
    func statScreenEntered(screen: String) {
        println("STAT Screen Entered: \(screen)");
        let timestamp = NSDate().timeIntervalSince1970;
        
        self.db.execute("INSERT INTO stat_screen (statSessionId, screen, enteredTimestamp) VALUES ((SELECT id FROM stat_session ORDER BY timestamp DESC), '\(screen)', \(timestamp))");
    }
    
    // STAT: Screen Exited
    func statScreenExited(screen: String) {
        //println("STAT Screen Exited: \(screen)");
        let timestamp = NSDate().timeIntervalSince1970;
        
        self.db.execute("UPDATE stat_screen SET exitedTimestamp = \(timestamp) WHERE id = (SELECT id FROM stat_screen WHERE screen = '\(screen)' ORDER BY enteredTimestamp DESC LIMIT 1)");
    }
    
    // STAT: Action
    func statAction(type: String, msg: String) {
        //println("STAT Action: \(msg)");
        let type = 0;
        let msg = 0;
        let timestamp = 0;
        
        self.db.execute("INSERT INTO stat_action (statScreenId, type, msg, timestamp) VALUES ((SELECT id FROM stat_screen ORDER BY id DESC LIMIT 1), \(type), \(msg), \(timestamp))");
    }
    
    // STAT: Report error
    func statError(err: String) {
        statAction("Error", msg: err);
    }
    
    // STAT: Report button touched
    func statTouch(btn: String) {
        statAction("Touched", msg: btn);
    }
}
