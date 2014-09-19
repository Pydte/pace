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
    @IBOutlet var btnMenu: UIBarButtonItem
    let db = SQLiteDB.sharedInstance();
    var selectedRunId: Int = 0;
    var running = true;
    var item1: RunSelectorItemView?;
    var item2: RunSelectorItemView?;
    var item3: RunSelectorItemView?;
    var item4: RunSelectorItemView?;
    var item5: RunSelectorItemView?;
    var itemLocked: RunSelectorItemView?;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
    }
    
    func loadRunSelector() {
        // Check if any runs are timed out
        let queryActiveRuns = db.query("SELECT runId, endDate, locked FROM active_runs");
        let nowUnix: Int = Int(NSDate().timeIntervalSince1970);
        var runTimedOut: Bool = false;
        var numberOfRuns: Int = 0;
        for run in queryActiveRuns {
            numberOfRuns++;
            
            let runId: Int = run["runId"]!.integer;
            let endDate: Int = run["endDate"]!.integer;
            let locked: Bool = Bool(run["locked"]!.integer);
            
            if (nowUnix > endDate && locked == false) {
                runTimedOut = true;
                db.execute("DELETE FROM active_runs WHERE runId=\(runId)");
            }
        }
        
        
        // If necessary, request active runs from webservice
        if (runTimedOut || numberOfRuns != 5) {
            println("Requesting active runs from webservice..");
            
            let defaultConfigObject: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration();
            let defaultSession: NSURLSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: NSOperationQueue.mainQueue());
            
            let url: NSURL = NSURL.URLWithString("http://epicrunner.com.pandiweb.dk/webservice/selectable-runs");
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: url);
            
            
            let queryId = db.query("SELECT loggedInUserId FROM settings");
            let id = queryId[0]["loggedInUserId"]!.integer;
            
            let params: String = "id=\(id)";
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
                        println("Retrival of active runs successful");
                        
                        let runs: NSArray = dic.objectForKey("runs") as NSArray;
                        for run in runs {
                            let runId: Int = run.objectForKey("id").integerValue;
                            let runTypeId: Int = run.objectForKey("run_type_id").integerValue;
                            let startDate: Int = run.objectForKey("start_date").integerValue;
                            let endDate: Int = run.objectForKey("end_date").integerValue;
                            
                            // INSERT IF NOT EXISTS
                            self.db.execute("INSERT INTO active_runs (runid, runTypeId, startDate, endDate) " +
                                "SELECT * FROM (SELECT \(runId), \(runTypeId), \(startDate), \(endDate)) AS tmp " +
                                "WHERE NOT EXISTS (SELECT runid FROM active_runs WHERE runid=\(runId)) LIMIT 1");
                            
                            
                            
                            // Individual data depending on run type
                            if (runTypeId == 1) {
                                // Location run
                                // UPDATE SAID RUN
                                let distance: Int = run.objectForKey("distance").integerValue;
                                let medalSilver: Int = run.objectForKey("medal_silver").integerValue;
                                let medalGold: Int = run.objectForKey("medal_gold").integerValue;
                                let difficulty: Int = run.objectForKey("difficulty").integerValue;
                                
                                self.db.execute("UPDATE active_runs SET distance=\(distance), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty) WHERE runId=\(runId)");
                                
                            } else if (runTypeId == 2) {
                                // Interval run
                                let medalBronze: Int = run.objectForKey("medal_bronze").integerValue;
                                let medalSilver: Int = run.objectForKey("medal_silver").integerValue;
                                let medalGold: Int = run.objectForKey("medal_gold").integerValue;
                                let difficulty: Int = run.objectForKey("difficulty").integerValue;
                                let duration: Int = run.objectForKey("duration").integerValue;
                                
                                self.db.execute("UPDATE active_runs SET medalBronze=\(medalBronze), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty), duration=\(duration) WHERE runId=\(runId)");
                                
                            } else if (runTypeId == 3) {
                                // Collector
                                let distance: Int = run.objectForKey("distance").integerValue;
                                let medalBronze: Int = run.objectForKey("medal_bronze").integerValue;
                                let medalSilver: Int = run.objectForKey("medal_silver").integerValue;
                                let medalGold: Int = run.objectForKey("medal_gold").integerValue;
                                let difficulty: Int = run.objectForKey("difficulty").integerValue;
                                let duration: Int = run.objectForKey("duration").integerValue;
                                
                                self.db.execute("UPDATE active_runs SET distance=\(distance), medalBronze=\(medalBronze), medalSilver=\(medalSilver), medalGold=\(medalGold), difficulty=\(difficulty), duration=\(duration) WHERE runId=\(runId)");
                            }
                        }
                        
                        // Show runs
                        self.showRuns();
                    } else {
                        println("Mr. Server is not happy.");
                    }
                    
                    
                } else {
                    println("Failed to contact server.");
                }
                });
            dataTask.resume();
        } else {
            // Just show local runs
            showRuns();
        }
    }
    
    func showRuns() {
        // Show runs --SHOULD WAIT FOR REQUESTING OF RUNS
        let activeRuns = db.query("SELECT runId, runTypeId, startDate, endDate, difficulty, distance, locked FROM active_runs ORDER BY endDate DESC");
        
        let runTypeName = ["Location Run","Interval Run","Collector Run"];
        
        var curId = 0;
        item1 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.integer,
            type: runTypeName[activeRuns[curId]["runTypeId"]!.integer-1],
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.integer)),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.integer)),
            difficulty: activeRuns[curId]["difficulty"]!.integer,
            distance: Int(activeRuns[curId]["distance"]!.double));
        self.view.addSubview(item1);
        
        
        curId = 1;
        item2 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.integer,
            type: runTypeName[activeRuns[curId]["runTypeId"]!.integer-1],
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.integer)),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.integer)),
            difficulty: activeRuns[curId]["difficulty"]!.integer,
            distance: Int(activeRuns[curId]["distance"]!.double));
        self.view.addSubview(item2);
        
        
        curId = 2;
        item3 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.integer,
            type: runTypeName[activeRuns[curId]["runTypeId"]!.integer-1],
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.integer)),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.integer)),
            difficulty: activeRuns[curId]["difficulty"]!.integer,
            distance: Int(activeRuns[curId]["distance"]!.double));
        self.view.addSubview(item3);
        
        
        curId = 3;
        item4 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.integer,
            type: runTypeName[activeRuns[curId]["runTypeId"]!.integer-1],
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.integer)),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.integer)),
            difficulty: activeRuns[curId]["difficulty"]!.integer,
            distance: Int(activeRuns[curId]["distance"]!.double));
        self.view.addSubview(item4);
        
        
        curId = 4;
        item5 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            runId: activeRuns[curId]["runId"]!.integer,
            type: runTypeName[activeRuns[curId]["runTypeId"]!.integer-1],
            startDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["startDate"]!.integer)),
            endDate: NSDate(timeIntervalSince1970: Double(activeRuns[curId]["endDate"]!.integer)),
            difficulty: activeRuns[curId]["difficulty"]!.integer,
            distance: Int(activeRuns[curId]["distance"]!.double));
        self.view.addSubview(item5);
        
        
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
    
    func itemKilled() {
        println("The master has recognized that an item was killed..");
        
        if (running) {
            item1?.move(true, coord: CGPoint(x: 0, y: 55));
            item2?.move(true, coord: CGPoint(x: 0, y: 55));
            item3?.move(true, coord: CGPoint(x: 0, y: 55));
            item4?.move(true, coord: CGPoint(x: 0, y: 55));
            
            item5 = item4;
            item4 = item3;
            item3 = item2;
            item2 = item1;
            
//            item1 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
//                text: "Swifty item ?",
//                startDate: NSDate.date(),
//                endDate: NSDate.date().dateByAddingTimeInterval(40));
//            self.view.addSubview(item1);
//            item1?.move(true, coord: CGPoint(x: 0, y: 120));
        }
    }
    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segueDetailView") {
            var destCtrl: MissionDVViewController = segue.destinationViewController as MissionDVViewController;
            destCtrl.selectedRunId = self.selectedRunId;
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        loadRunSelector();
    }
    
    override func viewWillDisappear(animated:Bool) {
        // Clean up
        println("View will disappear, cleaning up views!");
        running = false;
        item1?.destroy();
        item2?.destroy();
        item3?.destroy();
        item4?.destroy();
        item5?.destroy();
    }
}
