//
//  RunScreenContainerLeftViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 24/10/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class RunScreenContainerLeftViewController: UIViewController {
    let screenName = "runScreenContainerObjective";
    
    @IBOutlet var lblDescription: UILabel!;
    @IBOutlet var lblMedalBronze: UILabel!;
    @IBOutlet var lblMedalSilver: UILabel!;
    @IBOutlet var lblMedalGold: UILabel!;
    @IBOutlet weak var lblMedalBronzeHeadline: UILabel!;
    @IBOutlet weak var lblMedalSilverHeadline: UILabel!;
    @IBOutlet weak var lblMedalGoldHeadline: UILabel!;
    
    var container: RunScreenContainerViewController?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.container = self.parentViewController as? RunScreenContainerViewController;
        lblDescription.text = HelperFunctions().runDescription[container!.runTypeId];
        
        
        switch self.container!.runTypeId {
        case 1:
            populateLocationRun();
        case 2:
            populateIntervalRun();
        case 3:
            populateCollectorRun();
        case 4:
            populateCertificateRun();
        default:
            println("Unknown run type");
        }
    }
    
    
    func populateLocationRun() {
        // Set medals
        if (self.container!.medalBronze == 0) {
            lblMedalBronze.text = "If finish";
        } else {
            lblMedalBronze.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalBronze))";
        }
        lblMedalSilver.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalSilver))";
        lblMedalGold.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalGold))";
    }
    
    func populateIntervalRun() {
        // Set medals
        if (self.container!.medalBronze == 1) {
            lblMedalBronze.text = "\(self.container!.medalBronze) interval";
        } else {
            lblMedalBronze.text = "\(self.container!.medalBronze) intervals";
        }
        lblMedalSilver.text = "\(self.container!.medalSilver) intervals";
        lblMedalGold.text = "\(self.container!.medalGold) intervals";
    }
    
    func populateCollectorRun() {
        // Set medals
        if (self.container!.medalBronze == 0) {
            lblMedalBronze.text = "If finish";
        } else {
            lblMedalBronze.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalBronze))";
        }
        lblMedalSilver.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalSilver))";
        lblMedalGold.text = "in \(HelperFunctions().formatSecToMinSec(self.container!.medalGold))";
    }
    
    func populateCertificateRun() {
        // Remove medals
        lblMedalBronze.hidden = true;
        lblMedalSilver.hidden = true;
        lblMedalGold.hidden = true;
        lblMedalBronzeHeadline.hidden = true;
        lblMedalSilverHeadline.hidden = true;
        lblMedalGoldHeadline.hidden = true;
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
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
