//
//  MenuViewController.swift
//  Pace
//
//  Created by Jeppe Richardt on 25/12/15.
//  Copyright © 2015 Pandigames. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var conTop: NSLayoutConstraint!
    @IBOutlet weak var conLeft: NSLayoutConstraint!
    @IBOutlet weak var conMiddle: NSLayoutConstraint!
        
    @IBOutlet weak var conVSpacing01: NSLayoutConstraint!
    @IBOutlet weak var conVSpacing12: NSLayoutConstraint!
    @IBOutlet weak var conVSpacing23: NSLayoutConstraint!
    
    @IBOutlet weak var con00Width: NSLayoutConstraint!
    @IBOutlet weak var con01Width: NSLayoutConstraint!
    @IBOutlet weak var con10Width: NSLayoutConstraint!
    @IBOutlet weak var con11Width: NSLayoutConstraint!
    @IBOutlet weak var con20Width: NSLayoutConstraint!
    @IBOutlet weak var con21Width: NSLayoutConstraint!
    @IBOutlet weak var con30Width: NSLayoutConstraint!
    @IBOutlet weak var con31Width: NSLayoutConstraint!
    
    @IBOutlet weak var lbl00: UILabel!
    @IBOutlet weak var lbl01: UILabel!
    @IBOutlet weak var lbl10: UILabel!
    @IBOutlet weak var lbl11: UILabel!
    @IBOutlet weak var lbl20: UILabel!
    @IBOutlet weak var lbl21: UILabel!
    @IBOutlet weak var lbl30: UILabel!
    @IBOutlet weak var lbl31: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Menu init")
        
        conLeft.constant = self.view.frame.size.width/100*8 //10%
        conMiddle.constant = self.view.frame.size.width/100*5;
        
        let width = (self.view.frame.size.width/100*25) as CGFloat;
        let consWidth = [con00Width, con01Width, con10Width, con11Width, con20Width, con21Width, con30Width, con31Width];
        for c in consWidth {
            c.constant = width;
        }
        print("width: \(self.view.frame.size.width)");
        
        let labels = [lbl00, lbl01, lbl10, lbl11, lbl20, lbl21, lbl30, lbl31];
        let smallestFontSize = 10 as CGFloat;
        for l in labels {
            l.font = UIFont(name: l.font.fontName, size: smallestFontSize);
        }
        
    
    }
    
    deinit { print("menu is being deinitialized") }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
