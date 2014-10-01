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
    
    var selectedRunId = 0;
    let db = SQLiteDB.sharedInstance();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Not working?
        //ifnull(medalBronze,0) AS
        let selectedRunQuery = db.query("SELECT runTypeId, startDate, endDate, difficulty, distance, locked, medalBronze, medalSilver, medalGold FROM active_runs WHERE runId=\(self.selectedRunId)");
        
        let runTypeName = ["Location Run","Interval Run","Collector Run"];
        
        let runType: Int = selectedRunQuery[0]["runTypeId"]!.integer;
        let endDateUnix: Int = selectedRunQuery[0]["endDate"]!.integer;
        let locked: Bool = Bool(selectedRunQuery[0]["locked"]!.integer);
        var medalBronze: Int = selectedRunQuery[0]["medalBronze"]!.integer;
        let medalSilver: Int = selectedRunQuery[0]["medalSilver"]!.integer;
        let medalGold: Int = selectedRunQuery[0]["medalGold"]!.integer;
        self.title = runTypeName[runType-1];
        
        // Set time remaining
        if (locked) {
            lblTimeRemaning.text = "This mission is locked.";
        } else {
            let endDate: NSDate = NSDate(timeIntervalSince1970: Double(endDateUnix));
            let endDateFormatter: NSDateFormatter = NSDateFormatter()
            endDateFormatter.dateFormat = "HH:mm"
            lblTimeRemaning.text = "This mission runs out at \(endDateFormatter.stringFromDate(endDate))";
        }
        
        // Set medals
        lblBronze.text = "\(medalBronze)";
        lblSilver.text = "\(medalSilver)";
        lblGold.text = "\(medalGold)";
        
        
        switch runType {
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
        lblDescription.text = "You have to run from point A to point B and back to point A. Point A is your current physical location when you press 'Generate mission', while point B is a location of our choosing."
        lblDescription.numberOfLines = 0;
        lblDescription.sizeToFit();
    }
    
    func populateIntervalRun() {
        lblDescription.text = "You have to run x intervals, which is made up of two parts; one part walking and one part sprinting. This is a radically different way of running, one of constant high intensity rather than medium, long-term load."
        lblDescription.numberOfLines = 0;
        lblDescription.sizeToFit();
    }
    
    func populateCollectorRun() {
        lblDescription.text = "You have to collect a series of objects and return them to your base (starting point). Each time an object is collected it must be returned to the base. An object is effectively collected by running through its position on the map and is registered as 'collected' by running through the 'base' point on the map. There is no specific order to collect the objects in, but you can only carry one object at the time."
        lblDescription.numberOfLines = 0;
        lblDescription.sizeToFit();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
