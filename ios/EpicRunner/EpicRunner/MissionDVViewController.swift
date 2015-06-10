//
//  MissionDVViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 19/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class MissionDVViewController: UIViewController {
    let screenName = "runselectorDetailView";
    
    @IBOutlet var lblTimeRemaning: UILabel!;
    @IBOutlet var lblBronze: UILabel!;
    @IBOutlet var lblSilver: UILabel!;
    @IBOutlet var lblGold: UILabel!;
    @IBOutlet var lblDescription: UILabel!;
    @IBOutlet var lblDistance: UILabel!;
    
    var distance: Double = 0.0;
    var difficulty: Int = 0;
    var duration: Int = 0;
    var medalBronze: Int = 0;
    var medalSilver: Int = 0;
    var medalGold: Int = 0;
    
    var selectedRunId = 0;
    var selectedRunTypeId = 0;
    let db = SQLiteDB.sharedInstance();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        //Not working?
        //ifnull(medalBronze,0) AS
        let selectedRunQuery = db.query("SELECT runTypeId, startDate, endDate, difficulty, distance, duration, locked, medalBronze, medalSilver, medalGold FROM active_runs WHERE runId=\(self.selectedRunId)");
        
        self.selectedRunTypeId = selectedRunQuery[0]["runTypeId"]!.asInt();
        let endDateUnix: Int = selectedRunQuery[0]["endDate"]!.asInt();
        let locked: Bool = Bool(selectedRunQuery[0]["locked"]!.asInt());
        self.medalBronze = selectedRunQuery[0]["medalBronze"]!.asInt();
        self.medalSilver = selectedRunQuery[0]["medalSilver"]!.asInt();
        self.medalGold = selectedRunQuery[0]["medalGold"]!.asInt();
        self.difficulty = selectedRunQuery[0]["difficulty"]!.asInt();
        self.distance = selectedRunQuery[0]["distance"]!.asDouble();
        self.duration = selectedRunQuery[0]["duration"]!.asInt();
        self.title = HelperFunctions().runHeadline[self.selectedRunTypeId];
        
        // Set time remaining
        if (locked) {
            lblTimeRemaning.text = "This mission is locked.";
        } else {
            let endDate: NSDate = NSDate(timeIntervalSince1970: Double(endDateUnix));
            let endDateFormatter: NSDateFormatter = NSDateFormatter()
            endDateFormatter.dateFormat = "HH:mm"
            lblTimeRemaning.text = "This mission runs out at \(endDateFormatter.stringFromDate(endDate))";
        }
        
        // Set distance
        lblDistance.text = "Distance: " + (NSString(format: "%.2f km", self.distance) as String);
        
        // Set description
        lblDescription.text = HelperFunctions().runDescription[self.selectedRunTypeId];
        lblDescription.numberOfLines = 0;
        lblDescription.sizeToFit();
        
        switch self.selectedRunTypeId {
        case 1:
            populateLocationRun();
        case 2:
            populateIntervalRun();
        case 3:
            populateCollectorRun();
        default:
            println("Unknown run type");
        }
    }
    
    func populateLocationRun() {
        // Set medals
        if (medalBronze == 0) {
            lblBronze.text = "If finish";
        } else {
            lblBronze.text = "in \(HelperFunctions().formatSecToMinSec(medalBronze))";
        }
        lblSilver.text = "in \(HelperFunctions().formatSecToMinSec(medalSilver))";
        lblGold.text = "in \(HelperFunctions().formatSecToMinSec(medalGold))";
    }
    
    func populateIntervalRun() {
        // Override "Distance" label with intervals
        lblDistance.text = "Intervals: \(self.duration) (\(self.duration*2) min)";
        
        // Set medals
        if (self.medalBronze == 1) {
            lblBronze.text = "\(self.medalBronze) interval";
        } else {
            lblBronze.text = "\(self.medalBronze) intervals";
        }
        lblSilver.text = "\(self.medalSilver) intervals";
        lblGold.text = "\(self.medalGold) intervals";
    }
    
    func populateCollectorRun() {
        // Set medals
        if (self.medalBronze == 0) {
            lblBronze.text = "If finish";
        } else {
            lblBronze.text = "in \(HelperFunctions().formatSecToMinSec(medalBronze))";
        }
        lblSilver.text = "in \(HelperFunctions().formatSecToMinSec(medalSilver))";
        lblGold.text = "in \(HelperFunctions().formatSecToMinSec(medalGold))";
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "SegueGenerateRun") {
            var generateRunViewController: GenerateRunViewController = segue.destinationViewController as! GenerateRunViewController;
            generateRunViewController.runId = self.selectedRunId;
            generateRunViewController.runTypeId = self.selectedRunTypeId;
            generateRunViewController.locRunDistance = self.distance*1000;
            generateRunViewController.medalBronze = self.medalBronze;
            generateRunViewController.medalSilver = self.medalSilver;
            generateRunViewController.medalGold = self.medalGold;
        }
    }

}