//
//  RunSelectorViewControllerSwift.swift
//  EpicRunner
//
//  Created by Jeppe on 15/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

//Make local table in database to active runs
//
// Check if any runs are timed out
//   If not, show runs
//   If, request active runs, update local database, show runs



import UIKit

class RunSelectorViewControllerSwift: UIViewController {
    @IBOutlet var btnMenu: UIBarButtonItem!;
    @IBOutlet var btnLockedRunPlaceholder: UIButton!;
    @IBOutlet var lblLoadingText: UILabel!;
    @IBOutlet var idcLoading: UIActivityIndicatorView!;
    
    let db = SQLiteDB.sharedInstance();
    var userId: Int = 0;
    let runTypeName = ["Location Run","Interval Run","Collector Run"];
    var selectedRunId: Int = 0;
    var item1: RunSelectorItemView?;
    var item2: RunSelectorItemView?;
    var item3: RunSelectorItemView?;
    var item4: RunSelectorItemView?;
    var item5: RunSelectorItemView?;
    var itemLocked: RunSelectorItemView?;
    
    var runId: Int = 0;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";
        self.navigationController!.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        let queryId = db.query("SELECT loggedInUserId FROM settings");
        self.userId = queryId[0]["loggedInUserId"]!.asInt();
    }
    
    func loadRunSelector() {
        // Check if any runs are timed out
        let queryActiveRuns = db.query("SELECT runId, runTypeId, startDate, endDate, difficulty, distance, locked, disabled FROM active_runs WHERE userId=(SELECT loggedInUserId FROM settings)");
        let nowUnix: Int = Int(NSDate().timeIntervalSince1970);
        var runTimedOut: Bool = false;
        var numberOfRuns: Int = 0;
        var numberOfLockedRuns: Int = 0;
        for run in queryActiveRuns {
            numberOfRuns++;
            
            let runId: Int = run["runId"]!.asInt();
            let endDate: Int = run["endDate"]!.asInt();
            let locked: Bool = Bool(run["locked"]!.asInt());
            
            if (nowUnix > endDate && locked == false) {
                // A run has timed out, delete it and notify
                runTimedOut = true;
                db.execute("DELETE FROM active_runs WHERE runId=\(runId)");
            } else if (locked) {
                numberOfLockedRuns++;
                // Show locked run
                itemLocked = RunSelectorItemView(frame: CGRectMake(btnLockedRunPlaceholder.frame.origin.x, btnLockedRunPlaceholder.frame.origin.y, self.view.frame.size.width - 40, 41),
                    runId: run["runId"]!.asInt(),
                    type: runTypeName[run["runTypeId"]!.asInt()-1] + String(run["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(run["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(run["endDate"]!.asInt())),
                    difficulty: run["difficulty"]!.asInt(),
                    distance: Int(run["distance"]!.asDouble()),
                    disabled: Bool(run["disabled"]!.asInt()));
                self.view.addSubview(itemLocked!);
            }
        }
        
        if (numberOfLockedRuns > 1) {
            println("delete locked");
            db.execute("DELETE FROM active_runs WHERE locked=1 AND userId=(SELECT loggedInUserId FROM settings)");
        }
        
        // If necessary, request active runs from webservice
        if (runTimedOut || (numberOfRuns-numberOfLockedRuns) != 5 || numberOfLockedRuns > 1) {
        //if (true) {
            // Show loading info, this request can take a little while
            lblLoadingText.text = "Fetching available runs..";
            lblLoadingText.hidden = false;
            idcLoading.startAnimating();
            
            HelperFunctions().callWebService("selectable-runs", params: "id=\(self.userId)", callbackSuccess: showRuns, callbackFail: HelperFunctions().webServiceDefaultFail);
        } else {
            // Just show local runs
            showRuns(nil);
        }
    }
    
    func showRuns(data: AnyObject?) {
        // Hide loading info
        lblLoadingText.hidden = true;
        idcLoading.stopAnimating();
        
        if let dic: NSDictionary = data as? NSDictionary {
            // Extract runs from webservice into database
            let runs: NSArray = dic.objectForKey("runs") as NSArray;
            self.extractRunsIntoDb(runs);
        }
        
        
        let activeRuns = db.query("SELECT runId, runTypeId, startDate, endDate, difficulty, distance, disabled FROM active_runs WHERE userId=(SELECT loggedInUserId FROM settings) AND locked=0 ORDER BY endDate DESC");
        
        var curId = 0;
        item1 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.asInt(),
            type: runTypeName[activeRuns[curId]["runTypeId"]!.asInt()-1] + String(activeRuns[curId]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.asInt())),
            difficulty: activeRuns[curId]["difficulty"]!.asInt(),
            distance: Int(activeRuns[curId]["distance"]!.asDouble()),
            disabled: Bool(activeRuns[curId]["disabled"]!.asInt()));
        self.view.addSubview(item1!);
        
        
        curId = 1;
        item2 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.asInt(),
            type: runTypeName[activeRuns[curId]["runTypeId"]!.asInt()-1] + String(activeRuns[curId]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.asInt())),
            difficulty: activeRuns[curId]["difficulty"]!.asInt(),
            distance: Int(activeRuns[curId]["distance"]!.asDouble()),
            disabled: Bool(activeRuns[curId]["disabled"]!.asInt()));
        self.view.addSubview(item2!);
        
        
        curId = 2;
        item3 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.asInt(),
            type: runTypeName[activeRuns[curId]["runTypeId"]!.asInt()-1] + String(activeRuns[curId]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.asInt())),
            difficulty: activeRuns[curId]["difficulty"]!.asInt(),
            distance: Int(activeRuns[curId]["distance"]!.asDouble()),
            disabled: Bool(activeRuns[curId]["disabled"]!.asInt()));
        self.view.addSubview(item3!);
        
        
        curId = 3;
        item4 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.asInt(),
            type: runTypeName[activeRuns[curId]["runTypeId"]!.asInt()-1] + String(activeRuns[curId]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.asInt())),
            difficulty: activeRuns[curId]["difficulty"]!.asInt(),
            distance: Int(activeRuns[curId]["distance"]!.asDouble()),
            disabled: Bool(activeRuns[curId]["disabled"]!.asInt()));
        self.view.addSubview(item4!);
        
        
        curId = 4;
        item5 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.asInt(),
            type: runTypeName[activeRuns[curId]["runTypeId"]!.asInt()-1] + String(activeRuns[curId]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.asInt())),
            difficulty: activeRuns[curId]["difficulty"]!.asInt(),
            distance: Int(activeRuns[curId]["distance"]!.asDouble()),
            disabled: Bool(activeRuns[curId]["disabled"]!.asInt()));
        self.view.addSubview(item5!);
        
        
        // Move item
        item1?.move(true, coord: CGPoint(x: 0, y: 120));
        item2?.move(true, coord: CGPoint(x: 0, y: 175));
        item3?.move(true, coord: CGPoint(x: 0, y: 230));
        item4?.move(true, coord: CGPoint(x: 0, y: 285));
        item5?.move(true, coord: CGPoint(x: 0, y: 340));
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func lockRun(runId: Int) {
        func callback(data: AnyObject) {
            let dic: NSDictionary = data as NSDictionary;
                
            // If succeeds: Delete current locked run & Set run to locked
            self.db.execute("DELETE FROM active_runs WHERE userId=\(self.userId) AND locked=1;");
            self.db.execute("UPDATE active_runs SET locked=1, endDate=0 WHERE runid=\(runId);");
            
            // Extract new run from webservice into database
            let runs: NSArray = NSArray(object: dic.objectForKey("new_run")!);
            self.extractRunsIntoDb(runs);
            
            // Show replacement run & UI
            let newRunIdTemp: AnyObject! = runs[0];
            let newRunId: Int = newRunIdTemp.objectForKey("id")!.integerValue;
            let newRun = self.db.query("SELECT runId, runTypeId, startDate, endDate, difficulty, distance, disabled FROM active_runs WHERE runId=\(newRunId)");
            
            switch runId {
            case self.item1!.runId:
                self.itemLocked = self.item1;
                self.item1 = RunSelectorItemView(frame: CGRectMake(20, 79, self.view.frame.size.width - 40, 41),
                    runId: newRun[0]["runId"]!.asInt(),
                    type: self.runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
                    difficulty: newRun[0]["difficulty"]!.asInt(),
                    distance: Int(newRun[0]["distance"]!.asDouble()),
                    disabled: Bool(newRun[0]["disabled"]!.asInt()));
                self.view.addSubview(self.item1!);
            case self.item2!.runId:
                self.itemLocked = self.item2;
                self.item2 = RunSelectorItemView(frame: CGRectMake(20, 134, self.view.frame.size.width - 40, 41),
                    runId: newRun[0]["runId"]!.asInt(),
                    type: self.runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
                    difficulty: newRun[0]["difficulty"]!.asInt(),
                    distance: Int(newRun[0]["distance"]!.asDouble()),
                    disabled: Bool(newRun[0]["disabled"]!.asInt()));
                self.view.addSubview(self.item2!);
            case self.item3!.runId:
                self.itemLocked = self.item3;
                self.item3 = RunSelectorItemView(frame: CGRectMake(20, 189, self.view.frame.size.width - 40, 41),
                    runId: newRun[0]["runId"]!.asInt(),
                    type: self.runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
                    difficulty: newRun[0]["difficulty"]!.asInt(),
                    distance: Int(newRun[0]["distance"]!.asDouble()),
                    disabled: Bool(newRun[0]["disabled"]!.asInt()));
                self.view.addSubview(self.item3!);
            case self.item4!.runId:
                self.itemLocked = self.item4;
                self.item4 = RunSelectorItemView(frame: CGRectMake(20, 244, self.view.frame.size.width - 40, 41),
                    runId: newRun[0]["runId"]!.asInt(),
                    type: self.runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
                    difficulty: newRun[0]["difficulty"]!.asInt(),
                    distance: Int(newRun[0]["distance"]!.asDouble()),
                    disabled: Bool(newRun[0]["disabled"]!.asInt()));
                self.view.addSubview(self.item4!);
            case self.item5!.runId:
                self.itemLocked = self.item5;
                self.item5 = RunSelectorItemView(frame: CGRectMake(20, 299, self.view.frame.size.width - 40, 41),
                    runId: newRun[0]["runId"]!.asInt(),
                    type: self.runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
                    startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
                    endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
                    difficulty: newRun[0]["difficulty"]!.asInt(),
                    distance: Int(newRun[0]["distance"]!.asDouble()),
                    disabled: Bool(newRun[0]["disabled"]!.asInt()));
                self.view.addSubview(self.item5!);
            default:
                println("Hmm, something went wrong? o.O");
            }
        }
        
        println("Locking run: \(runId)");
        
        // Destroy current locked run
        if (itemLocked != nil) {
            itemLocked?.destroy(false);
        }
        
        // Post new locked run to server
        HelperFunctions().callWebService("lock-run", params: "user_id=\(self.userId)&active_run_id=\(runId)", callbackSuccess: callback, callbackFail: HelperFunctions().webServiceDefaultFail);
    }
    
    func itemKilled(timedOut: Bool) {
        if (timedOut) {
            // Get new item
            HelperFunctions().callWebService("selectable-runs", params: "id=\(self.userId)", callbackSuccess: rearrangeItems, callbackFail: HelperFunctions().webServiceDefaultFail);
        }
    }
    
    func rearrangeItems(data: AnyObject) {
        // Extract runs from webservice into database
        let dic: NSDictionary = data as NSDictionary;
        let runs: NSArray = dic.objectForKey("runs") as NSArray;
        self.extractRunsIntoDb(runs);
        
        // On success:
        // Reposition all items
        item1?.move(true, coord: CGPoint(x: 0, y: 55));
        item2?.move(true, coord: CGPoint(x: 0, y: 55));
        item3?.move(true, coord: CGPoint(x: 0, y: 55));
        item4?.move(true, coord: CGPoint(x: 0, y: 55));
        
        // Reassign items
        item5 = item4;
        item4 = item3;
        item3 = item2;
        item2 = item1;
        
        // Show new item
        let newRun = db.query("SELECT runId, runTypeId, startDate, endDate, difficulty, distance, disabled FROM active_runs WHERE userId=(SELECT loggedInUserId FROM settings) AND locked=0 ORDER BY startDate DESC LIMIT 1");
        
        item1 = RunSelectorItemView(frame: CGRectMake(20, 79, self.view.frame.size.width - 40, 41),
            runId: newRun[0]["runId"]!.asInt(),
            type: runTypeName[newRun[0]["runTypeId"]!.asInt()-1] + String(newRun[0]["runId"]!.asInt()),
            startDate: NSDate(timeIntervalSince1970: Double(newRun[0]["startDate"]!.asInt())),
            endDate: NSDate(timeIntervalSince1970: Double(newRun[0]["endDate"]!.asInt())),
            difficulty: newRun[0]["difficulty"]!.asInt(),
            distance: Int(newRun[0]["distance"]!.asDouble()),
            disabled: Bool(newRun[0]["disabled"]!.asInt()));
        self.view.addSubview(item1!);
    }
    
    func syncAllRuns() {
        func syncAllRunsSuccess(data: AnyObject) {
            // Update realRunId, synced
            let dic: NSDictionary = data as NSDictionary;
            let realRunId: Int = dic.objectForKey("posted_id")!.integerValue;
            self.db.execute("UPDATE Runs SET realRunId=\(realRunId), synced=1 WHERE id=\(self.runId)");
            
            // Remove from active_runs (run selector) IF NOT free run AND Locked
            //if (self.finishedRun!.realRunId?) {
            //    self.db.execute("DELETE FROM active_runs WHERE locked=1 AND runId=\(self.finishedRun!.realRunId!)");
            //}
            
            // Continue until all runs are synced
            syncAllRuns();
        }
        
        let runDataQuery = self.db.query("SELECT id, realRunId, distance, duration, avgSpeed, maxSpeed, minAltitude, maxAltitude, runTypeId FROM Runs WHERE synced=0 AND userId=(SELECT loggedInUserId FROM settings) LIMIT 1");
        
        if (runDataQuery.count > 0) {
            let runId_l: Int = runDataQuery[0]["id"]!.asInt();
            println("synchronizing: \(runId_l)");
            self.runId = runId_l;
            let realRunId: Int = runDataQuery[0]["realRunId"]!.asInt();
            let distance: Double = runDataQuery[0]["distance"]!.asDouble();
            let duration: Double = runDataQuery[0]["duration"]!.asDouble();
            let avgSpeed: Double = runDataQuery[0]["avgSpeed"]!.asDouble();
            let maxSpeed: Double = runDataQuery[0]["maxSpeed"]!.asDouble();
            let minAltitude: Double = runDataQuery[0]["minAltitude"]!.asDouble();
            let maxAltitude: Double = runDataQuery[0]["maxAltitude"]!.asDouble();
            let runTypeId: Int = runDataQuery[0]["runTypeId"]!.asInt();
            
            // Run locations
            var run_locations: String = "";
            let runLocationDataQuery = self.db.query("SELECT latitude, runId, longitude, horizontalAccuracy, altitude, verticalAccuracy, speed, timestamp FROM runs_location WHERE runId=\(runId)");
            for var i=0; i<runLocationDataQuery.count; i++ {
                let latitude: Double = runLocationDataQuery[0]["latitude"]!.asDouble();
                let longitude: Double = runLocationDataQuery[0]["longitude"]!.asDouble();
                let horizontalAccuracy: Double = runLocationDataQuery[0]["horizontalAccuracy"]!.asDouble();
                let altitude: Double = runLocationDataQuery[0]["altitude"]!.asDouble();
                let verticalAccuracy: Double = runLocationDataQuery[0]["verticalAccuracy"]!.asDouble();
                let speed: Double = runLocationDataQuery[0]["speed"]!.asDouble();
                let timestamp: Int = runLocationDataQuery[0]["timestamp"]!.asInt();
                
                run_locations += "&la[]=\(latitude)&lo[]=\(longitude)&ho[]=\(horizontalAccuracy)&ve[]=\(verticalAccuracy)&al[]=\(altitude)&sp[]=\(speed)&ti[]=\(timestamp))";
            }
            
            var params: String = "user_id=\(self.userId)&max_speed=\(maxSpeed)&min_altitude=\(minAltitude)&max_altitude=\(maxAltitude)&avg_speed=\(avgSpeed)&distance=\(distance)&duration=\(duration)\(run_locations)";
            var webService: String = "post-free-run";
            if (runTypeId != 0) {
                webService = "post-run";
                params = "run_id=\(realRunId)&" + params;
            }
            HelperFunctions().callWebService(webService, params: params, callbackSuccess: syncAllRunsSuccess, callbackFail: HelperFunctions().webServiceDefaultFail);
        } else {
            println("Done all sync");
            loadRunSelector();
        }
    }

    
    // Puts runs from webservice into database. (INSERTS ONLY IF NOT EXISTS)
    func extractRunsIntoDb(runs: NSArray) {
        for run in runs {
            let runId: Int = run.objectForKey("id")!.integerValue;
            var endDate: Int = 0;
            var locked = 0;
            if let derp = run.objectForKey("end_date") as? String {
                endDate = run.objectForKey("end_date")!.integerValue;
            } else {
                locked = 1;
            }
            
            let runTypeId: Int = run.objectForKey("run_type_id")!.integerValue;
            let startDate: Int = run.objectForKey("start_date")!.integerValue;
            
            
            // INSERT IF NOT EXISTS
            self.db.execute("INSERT INTO active_runs (runid, runTypeId, startDate, endDate, userId, locked) " +
                "SELECT * FROM (SELECT \(runId), \(runTypeId), \(startDate), \(endDate), (SELECT loggedInUserId FROM settings), \(locked)) AS tmp " +
                "WHERE NOT EXISTS (SELECT runid FROM active_runs WHERE runid=\(runId)) LIMIT 1");
            
            
            
            // Individual data depending on run type
            if (runTypeId == 1) {
                // Location run
                // UPDATE SAID RUN
                let distance: Int = run.objectForKey("distance")!.integerValue;
                let medalSilver: Int = run.objectForKey("medal_silver")!.integerValue;
                let medalGold: Int = run.objectForKey("medal_gold")!.integerValue;
                let difficulty: Int = run.objectForKey("difficulty")!.integerValue;
                
                self.db.execute("UPDATE active_runs SET distance=\(distance), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty) WHERE runId=\(runId)");
                
            } else if (runTypeId == 2) {
                // Interval run
                let medalBronze: Int = run.objectForKey("medal_bronze")!.integerValue;
                let medalSilver: Int = run.objectForKey("medal_silver")!.integerValue;
                let medalGold: Int = run.objectForKey("medal_gold")!.integerValue;
                let difficulty: Int = run.objectForKey("difficulty")!.integerValue;
                let duration: Int = run.objectForKey("duration")!.integerValue;
                
                self.db.execute("UPDATE active_runs SET medalBronze=\(medalBronze), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty), duration=\(duration) WHERE runId=\(runId)");
                
            } else if (runTypeId == 3) {
                // Collector run
                let distance: Int = run.objectForKey("distance")!.integerValue;
                //let medalBronze: Int = run.objectForKey("medal_bronze")!.integerValue;
                let medalSilver: Int = run.objectForKey("medal_silver")!.integerValue;
                let medalGold: Int = run.objectForKey("medal_gold")!.integerValue;
                let difficulty: Int = run.objectForKey("difficulty")!.integerValue;
                let duration: Int = run.objectForKey("duration")!.integerValue;
                
                self.db.execute("UPDATE active_runs SET distance=\(distance), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty), duration=\(duration) WHERE runId=\(runId)");
            }
        }
    }
    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segueDetailView") {
            var destCtrl: MissionDVViewController = segue.destinationViewController as MissionDVViewController;
            destCtrl.selectedRunId = self.selectedRunId;
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        // Do we have access?
        let queryAccess = db.query("SELECT loggedInLevel, loggedInTuRunSelector FROM settings");
        let level: Int = queryAccess[0]["loggedInLevel"]!.asInt();
        if (level == 0) {
            println("No access, you should at least be level 1!");
            var noAccessController: UIViewController = self.storyboard?.instantiateViewControllerWithIdentifier("noAccess") as UIViewController;
            self.addChildViewController(noAccessController);
            self.view.addSubview(noAccessController.view);
        } else {
            let needsSyncQuery = db.query("SELECT id FROM runs WHERE synced=0 AND userId=(SELECT loggedInUserId FROM settings) LIMIT 1");
            if (needsSyncQuery.count > 0) {
                println("Not synced");

                // Sync
                lblLoadingText.text = "Synchronizing local runs..";
                lblLoadingText.hidden = false;
                idcLoading.startAnimating();
                
                syncAllRuns();
            } else {
                println("Already synced");
                // Already synced, load runs
                loadRunSelector();
            }
            
            // Should we show the tutorial?
            let tutorialDone: Bool = Bool(queryAccess[0]["loggedInTuRunSelector"]!.asInt());
            if (!tutorialDone) {
                println("Showing tutorial");
            }
        }
    }
    
    override func viewWillDisappear(animated:Bool) {
        // Clean up
        println("View will disappear, cleaning up views!");
        item1?.destroy(false);
        item2?.destroy(false);
        item3?.destroy(false);
        item4?.destroy(false);
        item5?.destroy(false);
        itemLocked?.destroy(false);
    }
}
