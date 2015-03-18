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
    var userId: Int = 0;
    var sessionToken: String?;
    var runs: [Run] = [];
    var selectedIndex: Int = -1;
    var loadMoreBtn: UIButton? = nil;
    var loadMoreLocal: Bool = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Load User Id
        let queryId = db.query("SELECT loggedInUserId, loggedInSessionToken FROM settings");
        self.userId = queryId[0]["loggedInUserId"]!.asInt();
        self.sessionToken = queryId[0]["loggedInSessionToken"]!.asString();
        
        // Bind pull to update
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged);
        
        // Load data
        loadData(25, offset: -1);
        
        // "Load more data"-button
        var footerView: UIView = UIView(frame: CGRectMake(0, 0, 320, 30));
        
        self.loadMoreBtn = UIButton(frame: CGRectMake(0, 0, 320, 30));
        loadMoreBtn!.setTitle("Load more", forState: UIControlState.Normal);
        loadMoreBtn!.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal);
        loadMoreBtn!.titleLabel?.font = UIFont.systemFontOfSize(14.0);
        loadMoreBtn!.addTarget(self, action: "loadMore", forControlEvents: UIControlEvents.TouchUpInside)

        footerView.addSubview(loadMoreBtn!);
        footerView.userInteractionEnabled = true;
        self.tableView.tableFooterView = footerView;
        self.tableView.tableFooterView?.userInteractionEnabled = true;

        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    func loadMore() {
        println("Loading more..");
        loadMoreBtn!.setTitle("Loading more..", forState: UIControlState.Normal);
        
        let numOfRuns = self.runs.count;
        let numOfRunsToRetrieve: Int = 25;
        
        if (!self.loadMoreLocal) {
            //Retrieve numOfRunsToRetrieve from web service with offset numOfRuns
            HelperFunctions().callWebService("old-runs", params: "userid=\(self.userId)&session_token='\(self.sessionToken!)'&count=\(numOfRunsToRetrieve)&offset=\(numOfRuns)", callbackSuccess: loadMoreSuccess, callbackFail: HelperFunctions().webServiceDefaultFail);
        } else {
            //Retrieve runs locally
            loadData(numOfRunsToRetrieve, offset: numOfRuns);
            
            if (numOfRunsToRetrieve+numOfRuns != self.runs.count) {
                // No more runs stored locally
                self.loadMoreLocal = false;
            }
            
            self.tableView.reloadData();
            if (self.loadMoreLocal) {
                loadMoreBtn!.setTitle("Load more", forState: UIControlState.Normal);
            } else {
                loadMoreBtn!.setTitle("Load more online", forState: UIControlState.Normal);
            }
        }
    }
    
    func loadMoreSuccess(data: AnyObject?) {
        //Extract data into db
        let dic: NSDictionary = data as NSDictionary;
        let runs: NSArray = dic.objectForKey("runs") as NSArray;
        extractRunsIntoDb(runs);
        
        let numOfRuns = self.runs.count;
        let numOfRunsToRetrieve: Int = 25;
        
        //Retrieve runs locally
        loadData(numOfRunsToRetrieve, offset: numOfRuns);
        
        self.tableView.reloadData();
        loadMoreBtn!.setTitle("Load more online", forState: UIControlState.Normal);
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
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HistoryPrototypeCell", forIndexPath: indexPath) as UITableViewCell;
        
        
        //// Load more automatically - Not used
        //if (indexPath.row == runs.count - 1) {
        //    loadMore();
        //}
        
        
        // Configure the cell...
        var dateFormatter: NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MMMM dd";
        
        let run: Run = self.runs[indexPath.row];
        
        cell.textLabel!.text = "\(HelperFunctions().runHeadline[run.runTypeId])";
        cell.detailTextLabel!.text = "\(dateFormatter.stringFromDate(run.start!))";
        switch run.medal {
        case 1:
            cell.imageView!.image = UIImage(named: "medal_gold");
        case 2:
            cell.imageView!.image = UIImage(named: "medal_silver");
        case 3:
            cell.imageView!.image = UIImage(named: "medal_bronze");
        default:
            cell.imageView!.image = UIImage(named: "medal_none");
        }
        return cell
    }
    
    //TODO: Delete(or hide?) from cloud too?
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

    // -1 for limit or offset, means no limit/offset
    func loadData(limit: Int, offset: Int) {
        println("Load data locally");
        
        var limitStr: String = "";
        var offsetStr: String = "";
        if (limit > 0) {
            limitStr = " LIMIT \(limit)";
        }
        if (offset > 0) {
            offsetStr = " OFFSET \(offset)";
        }
        
        // Read all runs
        let queryRuns = db.query("SELECT id, realRunId, startDate, endDate, distance, duration, avgSpeed, runTypeId, medal FROM runs WHERE userId=(SELECT loggedInUserId FROM Settings) ORDER BY startDate DESC\(limitStr)\(offsetStr)");
        for runInDb in queryRuns {
            // Retrieve run data
            var run: Run = Run();
            run.dbId = runInDb["id"]!.asInt();
            run.realRunId = runInDb["realRunId"]!.asInt();
            run.start = NSDate(timeIntervalSince1970: Double(runInDb["startDate"]!.asInt()));
            run.end = NSDate(timeIntervalSince1970: Double(runInDb["endDate"]!.asInt()));
            run.distance = runInDb["distance"]!.asDouble();
            run.duration = runInDb["duration"]!.asDouble();
            run.avgSpeed = runInDb["avgSpeed"]!.asDouble();
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
        println("Updating history..");
        
        //Change title
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Updating history..");
        
        //Make webservice request
        HelperFunctions().callWebService("old-runs", params: "userid=\(self.userId)&session_token='\(self.sessionToken!)'&count=40&offset=0", callbackSuccess: refreshSuccess, callbackFail: refreshFail);
    }

    func refreshSuccess(data: AnyObject?) {
        println(data);
        //Extract data into db
        let dic: NSDictionary = data as NSDictionary;
        let runs: NSArray = dic.objectForKey("runs") as NSArray;
        extractRunsIntoDb(runs);
        
        //Retrieve runs from db
        self.runs.removeAll(keepCapacity: true);
        loadData(25, offset: -1);
        self.tableView.reloadData();
        
        //Reset
        self.refreshControl?.endRefreshing();
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Keep pulling to update..");
    }
    
    func refreshFail(err: String) {
        //On failure
        println("Failed to update history");
        self.refreshControl?.endRefreshing();
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Keep pulling to update..");
        HelperFunctions().webServiceDefaultFail(err);
    }
    
    
    // Puts runs from webservice into database. (INSERTS ONLY IF NOT EXISTS)
    func extractRunsIntoDb(runs: NSArray) {
        for run in runs {
            let runId: Int = run.objectForKey("id")!.integerValue;
            var runTypeId: Int = 0;
            if let tmp1 = run.objectForKey("run_type_id") as? String {
                runTypeId = run.objectForKey("run_type_id")!.integerValue;
            }
            var startDate: Int = 0;
            if let tmp2 = run.objectForKey("start_date") as? String {
                startDate = run.objectForKey("start_date")!.integerValue;
            }
            var endDate: Int = 0;
            if let tmp3 = run.objectForKey("end_date") as? String {
                endDate = run.objectForKey("end_date")!.integerValue;
            }
            let distance: Double = run.objectForKey("distance")!.doubleValue;
            let duration: Double = run.objectForKey("duration")!.doubleValue;
            let avgSpeed: Double = run.objectForKey("avg_speed")!.doubleValue;
            let maxSpeed: Double = run.objectForKey("max_speed")!.doubleValue;
            let minAltitude: Double = run.objectForKey("min_altitude")!.doubleValue;
            let maxAltitude: Double = run.objectForKey("max_altitude")!.doubleValue;
            var medalScore: Int = 0;
            if let derp = run.objectForKey("medal_score") as? String {
                medalScore = run.objectForKey("medal_score")!.integerValue;
            }
            
            
            
            // INSERT IF NOT EXISTS
            self.db.execute("INSERT INTO runs (startDate, endDate, distance, duration, avgSpeed, maxSpeed, minAltitude, maxAltitude, realRunId, userId, runTypeId, aborted, medal, synced) " +
                "SELECT * FROM (SELECT \(startDate), \(endDate), \(distance), \(duration), \(avgSpeed), \(maxSpeed), \(minAltitude), \(maxAltitude), \(runId), \(self.userId), \(runTypeId), (SELECT loggedInUserId FROM settings), \(medalScore), 1) AS tmp " +
                "WHERE NOT EXISTS (SELECT realRunId FROM runs WHERE realRunId=\(runId)) LIMIT 1");
        }
    }
    
    @IBAction func unwindToHistory(segue: UIStoryboardSegue) {
    }

}
