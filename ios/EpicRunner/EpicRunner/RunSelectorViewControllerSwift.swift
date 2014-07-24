//
//  RunSelectorViewControllerSwift.swift
//  EpicRunner
//
//  Created by Jeppe on 15/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import UIKit

class RunSelectorViewControllerSwift: UIViewController {
    @IBOutlet var btnMenu: UIBarButtonItem
    var running = true;
    var item1: RunSelectorItemView?;
    var item2: RunSelectorItemView?;
    var item3: RunSelectorItemView?;
    var item4: RunSelectorItemView?;
    var item5: RunSelectorItemView?;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind menu button
        self.btnMenu.target = self.revealViewController();
        self.btnMenu.action = "revealToggle:";  // This is dangerous - if wrong it's first going to crash at runtime
        self.navigationController.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        
        // Add item
        item1 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
                                    text: "Swifty item 1",
                                    startDate: NSDate.date(),
                                    endDate: NSDate.date().dateByAddingTimeInterval(50));
        self.view.addSubview(item1);
        
        
        item2 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            text: "Swifty item 2",
            startDate: NSDate.date().dateByAddingTimeInterval(-10),
            endDate: NSDate.date().dateByAddingTimeInterval(40));
        self.view.addSubview(item2);
        
        
        item3 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            text: "Swifty item 3",
            startDate: NSDate.date().dateByAddingTimeInterval(-20),
            endDate: NSDate.date().dateByAddingTimeInterval(30));
        self.view.addSubview(item3);
        
        
        item4 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            text: "Swifty item 4",
            startDate: NSDate.date().dateByAddingTimeInterval(-30),
            endDate: NSDate.date().dateByAddingTimeInterval(20));
        self.view.addSubview(item4);
        
        
        item5 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
            text: "Swifty item 5",
            startDate: NSDate.date().dateByAddingTimeInterval(-40),
            endDate: NSDate.date().dateByAddingTimeInterval(10));
        self.view.addSubview(item5);
        
        
        // Move item
        item1?.move(true, coord: CGPoint(x: 0, y: 120));
        item2?.move(true, coord: CGPoint(x: 0, y: 175));
        item3?.move(true, coord: CGPoint(x: 0, y: 230));
        item4?.move(true, coord: CGPoint(x: 0, y: 285));
        item5?.move(true, coord: CGPoint(x: 0, y: 340));
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func itemKilled() {
        println("The master has recognized that an item was killed..");
        
        if (running) {
            item1?.move(true, coord: CGPoint(x: 0, y: 55));
            item2?.move(true, coord: CGPoint(x: 0, y: 55));
            item3?.move(true, coord: CGPoint(x: 0, y: 55));
            item4?.move(true, coord: CGPoint(x: 0, y: 55));
            
            item5 = item4;
            item4 = item3;
            item3 = item2;
            item2 = item1;
            
            item1 = RunSelectorItemView(frame: CGRectMake(20, -41, self.view.frame.size.width - 40, 41),
                text: "Swifty item ?",
                startDate: NSDate.date(),
                endDate: NSDate.date().dateByAddingTimeInterval(40));
            self.view.addSubview(item1);
            item1?.move(true, coord: CGPoint(x: 0, y: 120));
        }
    }
    
    /*
    // #pragma mark - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillDisappear(animated:Bool) {
        println("View will disappear, cleaning up views!");
        running = false;
        item1?.destroy();
        item2?.destroy();
        item3?.destroy();
        item4?.destroy();
        item5?.destroy();
    }


}
