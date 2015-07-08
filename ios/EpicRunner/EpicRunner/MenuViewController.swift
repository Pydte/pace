//
//  MenuViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 19/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//
import UIKit

class SWUITableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event);
        HelperFunctions().statAction("TouchedMenuItem", msg: self.accessibilityLabel)
    }
}

class MenuViewController: UITableViewController {
    let screenName = "menu"
    let db = SQLiteDB.sharedInstance();
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // configure the destination view controller:
        //    if ( [segue.destinationViewController isKindOfClass: [ColorViewController class]] &&
        //        [sender isKindOfClass:[UITableViewCell class]] )
        //    {
        //        UILabel* c = [(SWUITableViewCell *)sender label];
        //        ColorViewController* cvc = segue.destinationViewController;
        //
        //        cvc.color = c.textColor;
        //        cvc.text = c.text;
        //    }
        
        // configure the segue.
        //    if (segue.isKindOfClass(SWRevealViewControllerSegue)) {
        //}
        
        if (segue.identifier == "Logout") {
            println("Logging out...");
            
            // Log out locally
            let db = SQLiteDB.sharedInstance();
            let query = db.execute("UPDATE settings SET loggedInUserId=NULL");
            
            // Log out facebook
            FBSession.activeSession().closeAndClearTokenInformation();
        }
    }
    
    // #pragma mark - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 7;
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: SWUITableViewCell? = nil;
        let query = self.db.query("SELECT loggedInLevel FROM settings");
        let loggedInLevel: Int = query[0]["loggedInLevel"]!.asInt();
        
        switch (indexPath.row)
        {
        case 0:
            cell = (tableView.dequeueReusableCellWithIdentifier("Main") as! SWUITableViewCell)
            break;
            
        case 1:
            cell = (tableView.dequeueReusableCellWithIdentifier("Run") as! SWUITableViewCell)
            println("mother fucking DOING IT?!");
            // If menu item is locked, show it
            if (loggedInLevel < 1) {
                cell?.label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0);
                var lock: UIImageView = UIImageView(image: UIImage(named: "lock")!);
                lock.frame.size = CGSize(width: 25, height: 25);
                lock.frame.origin = CGPoint(x: self.view.frame.size.width-100, y: (cell!.frame.size.height-lock.frame.height)/2);
                lock.alpha = 0.6;
                cell?.addSubview(lock);
            }
            break;
            
        case 2:
            cell = (tableView.dequeueReusableCellWithIdentifier("History") as! SWUITableViewCell)
            break;
            
        case 3:
            cell = (tableView.dequeueReusableCellWithIdentifier("Community") as! SWUITableViewCell)
            break;
            
        case 4:
            cell = (tableView.dequeueReusableCellWithIdentifier("Shop") as! SWUITableViewCell)
            break;
            
        case 5:
            cell = (tableView.dequeueReusableCellWithIdentifier("Settings") as! SWUITableViewCell)
            break;
            
        case 6:
            cell = (tableView.dequeueReusableCellWithIdentifier("Logout") as! SWUITableViewCell)
            break;
        
        default:
            break;
        }

        return cell!;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        // Reload data, some menus might have been unlocked :)
        println("reloadData on viewDidAppear");
        self.tableView.reloadData();
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }

    // #pragma mark state preservation / restoration
    
    override func encodeRestorableStateWithCoder(coder : NSCoder) {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        
        // TODO save what you need here
        
        super.encodeRestorableStateWithCoder(coder);
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
    
        // TODO restore what you need here
    
        super.decodeRestorableStateWithCoder(coder);
    }
    
    override func applicationFinishedRestoringState() {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        
        // TODO call whatever function you need to visually restore
    }
}