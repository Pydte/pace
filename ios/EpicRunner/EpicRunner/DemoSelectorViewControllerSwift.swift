//
//  DemoSelectorViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 20/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class DemoSelectorViewControllerSwift: UIViewController {
    @IBOutlet var btnMenu: UIBarButtonItem
    
    var OnePointLocationRunDistance: Double = 0.0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        //Always show navigationBar
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [super viewWillAppear:NO];
        */
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        //Always show navigationBar
        if(segue.identifier? == "SegueMultiplayer") {
            var mapViewController: MapViewControllerSwift = segue.destinationViewController as MapViewControllerSwift;
            mapViewController.multiplayer = true;
        } else if (segue.identifier? == "Segue1AutoRoute") {
            var mapViewController: MapViewControllerSwift = segue.destinationViewController as MapViewControllerSwift;
            mapViewController.autoroute1 = true;
            mapViewController.onePointLocationRunDistance = self.OnePointLocationRunDistance;
        }
        
  
    }
    
    
    @IBAction func unwindToDemoSelector(segue: UIStoryboardSegue) {
        self.navigationController.setNavigationBarHidden(false, animated:true);
        super.viewWillAppear(true);
        
        if(segue.identifier? == "SegueStartRun") {
            //[self performSegueWithIdentifier:@"SegueTest" sender:self];
            //MapViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactDetailViewController"];
            //Contact *contact = [self.contacts objectAtIndex:indexPath.row];
            //controller.contact = contact;
            //[self.navigationController pushViewController:controller animated:YES];
            println("test");
        }
    }
}
