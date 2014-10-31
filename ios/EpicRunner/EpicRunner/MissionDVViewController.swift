//
//  MissionDVViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 19/09/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class MissionDVViewController: UIViewController {

    @IBOutlet var lblTimeRemaning: UILabel
    @IBOutlet var lblBronze: UILabel
    @IBOutlet var lblSilver: UILabel
    @IBOutlet var lblGold: UILabel
    @IBOutlet var lblDescription: UILabel
    @IBOutlet var lblDistance: UILabel
    
    var distance: Double = 0.0;
    var difficulty: Int = 0;
    var medalBronze: Int = 0;
    var medalSilver: Int = 0;
    var medalGold: Int = 0;
    
    var selectedRunId = 0;
    var selectedRunTypeId = 0;
    let db = SQLiteDB.sharedInstance();
    
    var intervalsBronze: Int = 0;
    var intervalsSilver: Int = 0;
    var intervalsGold: Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Not working?
        //ifnull(medalBronze,0) AS
        let selectedRunQuery = db.query("SELECT runTypeId, startDate, endDate, difficulty, distance, locked, medalBronze, medalSilver, medalGold FROM active_runs WHERE runId=\(self.selectedRunId)");
        
        let runTypeName = ["Location Run","Interval Run","Collector Run"];
        
        self.selectedRunTypeId = selectedRunQuery[0]["runTypeId"]!.integer;
        let endDateUnix: Int = selectedRunQuery[0]["endDate"]!.integer;
        let locked: Bool = Bool(selectedRunQuery[0]["locked"]!.integer);
        self.medalBronze = selectedRunQuery[0]["medalBronze"]!.integer;
        self.medalSilver = selectedRunQuery[0]["medalSilver"]!.integer;
        self.medalGold = selectedRunQuery[0]["medalGold"]!.integer;
        self.difficulty = selectedRunQuery[0]["difficulty"]!.integer;
        self.distance = selectedRunQuery[0]["distance"]!.double;
        self.title = runTypeName[self.selectedRunTypeId-1];
        
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
        lblDistance.text = "Distance: " + NSString(format: "%.2f km", self.distance);
        
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
        switch self.difficulty {
        case 1:
            self.intervalsBronze = 3;
            self.intervalsSilver = 4;
            self.intervalsGold = 5;
        case 2:
            self.intervalsBronze = 3;
            self.intervalsSilver = 5;
            self.intervalsGold = 7;
        case 3:
            self.intervalsBronze = 4;
            self.intervalsSilver = 7;
            self.intervalsGold = 10;
        default:
            println("Unknown difficulty");
        }
        
        // Override "Distance" label with intervals
        lblDistance.text = "Intervals: \(self.intervalsGold) (\(self.intervalsGold*2) min)";
        
        // Set medals
        lblBronze.text = "\(self.intervalsBronze) intervals";
        lblSilver.text = "\(self.intervalsSilver) intervals";
        lblGold.text = "\(self.intervalsGold) intervals";
    }
    
    func populateCollectorRun() {
        // Set medals
        if (medalBronze == 0) {
            lblBronze.text = "If finish";
        } else if (medalBronze == 1) {
            lblBronze.text = "\(medalBronze) object";
        } else {
            lblBronze.text = "\(medalBronze) objects";
        }
        lblSilver.text = "\(medalSilver) objects";
        lblGold.text = "\(medalGold) objects";
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "SegueGenerateRun") {
            var generateRunViewController: GenerateRunViewController = segue.destinationViewController as GenerateRunViewController;
            generateRunViewController.runId = self.selectedRunId;
            generateRunViewController.runTypeId = self.selectedRunTypeId;
            generateRunViewController.locRunDistance = self.distance*1000;
            generateRunViewController.medalBronze = self.medalBronze;
            generateRunViewController.medalSilver = self.medalSilver;
            generateRunViewController.medalGold = self.medalGold;
        }
    }

}