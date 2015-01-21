//
//  HistoryTableViewControllerSwift.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit
import CoreLocation

class HistoryTableViewControllerSwift: UITableViewController {
    //@IBOutlet strong var myTableView: UITableView!;
    @IBOutlet var myTableView: UITableView!;
    @IBOutlet var btnMenu: UIBarButtonItem!;
    
    let db = SQLiteDB.sharedInstance();
    var runs: [Run] = [];
    var selectedIndex: Int = -1;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Bind pull to update
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged);
        
        // Load data
        loadData();
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // #pragma mark - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return self.runs.count;
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Configure the cell...
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HistoryPrototypeCell", forIndexPath: indexPath) as UITableViewCell;

        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MMMM dd";
        
        let run: Run = self.runs[indexPath.row];
        
        cell.textLabel.text = "\(HelperFunctions().runHeadline[run.runTypeId])";
        cell.detailTextLabel!.text = "\(dateFormatter.stringFromDate(run.start!))";
        switch run.medal {
        case 1:
            cell.imageView.image = UIImage(named: "medal_gold");
        case 2:
            cell.imageView.image = UIImage(named: "medal_silver");
        case 3:
            cell.imageView.image = UIImage(named: "medal_bronze");
        default:
            cell.imageView.image = UIImage(named: "medal_none");
        }
        return cell
    }

    func deleteRun() {
        let run: Run = self.runs[selectedIndex];
        
        // Remove from database
        let db = SQLiteDB.sharedInstance();
        let query = db.execute("DELETE FROM runs WHERE id = \(run.dbId!)");
        
        // Remove from data source (in memory)
        // Order Important! - Update source before table view, otherwise tableView gets confused. Silly table view.
        self.runs.removeAtIndex(self.selectedIndex);
        
        // Remove from tableView
        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: self.selectedIndex, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade);
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if (segue.identifier == "SegueRunDetails") {
            let selectedRowIndexPath = myTableView?.indexPathForSelectedRow();
            let run: Run = self.runs[selectedRowIndexPath!.row];
            
            var detailViewViewController: DetailViewViewControllerSwift = segue.destinationViewController as DetailViewViewControllerSwift;
            detailViewViewController.selectedRun = run;
            
            self.selectedIndex = selectedRowIndexPath!.row;
        }
    }
    
    
    func loadDummyData() {
        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
        
        var run1: Run = Run();
        run1.distance = 4270;
        run1.start = dateFormatter.dateFromString("2014-03-25 15:13:00");
        run1.end = dateFormatter.dateFromString("2014-03-25 15:30:00");
        self.runs.append(run1);
    
        var run2: Run = Run();
        run2.distance = 3960;
        run2.start = dateFormatter.dateFromString("2014-03-23 14:42:00");
        run2.end = dateFormatter.dateFromString("2014-03-23 15:02:20");
        self.runs.append(run2);
    }

    func loadData() {
        
        // Read all runs
        let queryRuns = db.query("SELECT id, startDate, endDate, distance, runTypeId, medal FROM runs WHERE userId=(SELECT loggedInUserId FROM Settings) ORDER BY startDate DESC");
        for runInDb in queryRuns {
            // Retrieve run data
            var run: Run = Run();
            run.dbId = runInDb["id"]!.asInt();
            run.start = NSDate(timeIntervalSince1970: Double(runInDb["startDate"]!.asInt()));
            run.end = NSDate(timeIntervalSince1970: Double(runInDb["endDate"]!.asInt()));
            run.distance = runInDb["distance"]!.asDouble();
            run.runTypeId = runInDb["runTypeId"]!.asInt();
            run.medal = runInDb["medal"]!.asInt();
            
            
            // Read all locations for runs
            // - Probably use parameters........
            // - Maybe first load these data on detail click?
            /*let queryLocs = db.query("SELECT latitude, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed FROM runs_location WHERE runId = \(run.dbId) ORDER BY id");
            for locInDb in queryLocs {
                // Retrieve loc data
                let lat = locInDb["latitude"]!.double;
                let lon = locInDb["longitude"]!.double;
                let horizontalAcc = locInDb["horizontalAccuracy"]!.double;
                let altitude = locInDb["altitude"]!.double;
                let verticalAcc = locInDb["verticalAccuracy"]!.double;
                let speed = locInDb["speed"]!.double;
                let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    altitude: altitude,
                    horizontalAccuracy: horizontalAcc,
                    verticalAccuracy: verticalAcc,
                    course: 0,
                    speed: speed,
                    timestamp: nil)
                
                run.locations.append(loc);
            }*/
            
            self.runs.append(run);
        }
    }
    
    func refresh(sender:AnyObject)
    {
        // Updating your data here...
        println("herp derp");
        //self.tableView.reloadData()
        //self.refreshControl?.endRefreshing()
    }
    
    @IBAction func unwindToHistory(segue: UIStoryboardSegue) {
    }

}
