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
    
    var selectedRunId = 0;
    let db = SQLiteDB.sharedInstance();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let selectedRunQuery = db.query("SELECT runTypeId, startDate, endDate, difficulty, distance, locked FROM active_runs WHERE runId=\(self.selectedRunId)");
        
        let runTypeName = ["Location Run","Interval Run","Collector Run"];
        
        
        self.title = runTypeName[selectedRunQuery[0]["runTypeId"]!.integer-1];
        lblTimeRemaning.text = "This mission runs out at #CLOCK";
        
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
