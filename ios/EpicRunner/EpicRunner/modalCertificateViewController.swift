//
//  modalCertificateViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 06/03/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class modalCertificateViewController: UIViewController {
    let screenName = "modalCertification";
    
    let db = SQLiteDB.sharedInstance();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        func callbackSuccess(data: AnyObject) {
            println("Level updated on server");
            //let dic: NSDictionary = data as NSDictionary;
            // Locally
            db.execute("UPDATE settings set loggedInLevel=1");
        }

        // Update level! (certify)
        let query = db.query("SELECT loggedInLevel, loggedInUserId, loggedInSessionToken FROM settings");
        if (query[0]["loggedInLevel"]!.asInt() < 1) {
            /// Post to server
            let userId: Int = query[0]["loggedInUserId"]!.asInt();
            let sessionToken: String = query[0]["loggedInSessionToken"]!.asString();
            HelperFunctions().callWebService("update-level", params: "userid=\(userId)&new_level=1&session_token='\(sessionToken)'", callbackSuccess: callbackSuccess, callbackFail: HelperFunctions().webServiceDefaultFail);
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDismissClicked(sender: AnyObject) {
        var rs: RunScreenViewController = self.parentViewController! as RunScreenViewController;
        rs.nextModal();
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
