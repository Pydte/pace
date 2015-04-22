//
//  RunScreenContainerIntervalViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 09/01/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class RunScreenContainerIntervalViewController: UIViewController {
    let screenName = "runScreenContainerInterval";
    
    @IBOutlet weak var lblPassed: UILabel!
    @IBOutlet weak var lblFailed: UILabel!
    @IBOutlet weak var lblSwitchIn: UILabel!
    @IBOutlet weak var lblMedal: UILabel!
    @IBOutlet weak var lblCurrentPace: UILabel!
    @IBOutlet weak var lblTargetPace: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
