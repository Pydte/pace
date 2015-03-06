//
//  modalCertificateViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 06/03/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class modalCertificateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDismissClicked(sender: AnyObject) {
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
