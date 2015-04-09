//
//  modalMedalViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 28/11/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class modalMedalViewController: UIViewController {
    let screenName = "modalMedal";

    var wonMedal: Int = 0;
    var runTimeInSeconds: NSNumber = 0;
    
    @IBOutlet weak var lblTitle: UILabel!;
    @IBOutlet weak var imgMedal: UIImageView!;
    @IBOutlet weak var lblDesc: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        lblTitle.text = "YOU WON \(HelperFunctions().runMedal[wonMedal].uppercaseString)";
        imgMedal.image = UIImage(named: "medal_\(HelperFunctions().runMedal[wonMedal])");
        
        let runTimeInMinutes: Double = Double(runTimeInSeconds) / Double(60);
        let runRemainingTimeInSeconds: Double = fmod(Double(runTimeInSeconds), 60);
        let runTimeInMinutesFormat = NSString(format: "%02d", Int(runTimeInMinutes));
        let runRemainingTimeInSecondsFormat = NSString(format: "%02d", Int(runRemainingTimeInSeconds));
        lblDesc.text = "You finished in: \(runTimeInMinutesFormat):\(runRemainingTimeInSecondsFormat)";
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated);
        HelperFunctions().statScreenEntered(screenName);
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        HelperFunctions().statScreenExited(screenName);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDismissedClicked(sender: AnyObject) {
        var rs: RunScreenViewController = self.parentViewController! as RunScreenViewController;
        rs.nextModal();
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
