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
    @IBOutlet weak var img: UIImageView!
    
}

class MenuViewController: UITableViewController {
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
        var CellIdentifier: String = "Cell";
        
        switch (indexPath.row)
        {
        case 0:
            CellIdentifier = "Main";
            break;
            
        case 1:
            CellIdentifier = "Run";
            break;
            
        case 2:
            CellIdentifier = "History";
            break;
            
        case 3:
            CellIdentifier = "Community";
            break;
            
        case 4:
            CellIdentifier = "Shop";
            break;
            
        case 5:
            CellIdentifier = "Settings";
            break;
            
        case 6:
            CellIdentifier = "Logout";
            break;
        
        default:
            break;
        }
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as UITableViewCell;
        let cell2: SWUITableViewCell? = cell as? SWUITableViewCell
        //cell.img.hidden = true; // = UIImage(named: "lock");
        if cell2 == nil {
            println("Whyy jebus?!");
        } else {
            println("derp");
        }
        return cell;
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