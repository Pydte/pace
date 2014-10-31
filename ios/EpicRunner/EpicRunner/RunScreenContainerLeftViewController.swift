//
//  RunScreenContainerLeftViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 24/10/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class RunScreenContainerLeftViewController: UIViewController {
    @IBOutlet var lblDescription: UILabel
    @IBOutlet var lblMedalBronze: UILabel
    @IBOutlet var lblMedalSilver: UILabel
    @IBOutlet var lblMedalGold: UILabel
    
    var container: RunScreenContainerViewController?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.container = self.parentViewController as? RunScreenContainerViewController;
        lblDescription.text = HelperFunctions().runDescription[container!.runTypeId];
        
        lblMedalBronze.text = String(self.container!.medalBronze);
        lblMedalSilver.text = String(self.container!.medalSilver);
        lblMedalGold.text = String(self.container!.medalGold);
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
