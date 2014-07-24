//
//  MenuViewController.swift
//  EpicRunner
//
//  Created by Jeppe on 19/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//
import UIKit

class SWUITableViewCell: UITableViewCell {
    
}

class MenuViewControllerSwift: UITableViewController {
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // configure the destination view controller:
        //    if ( [segue.destinationViewController isKindOfClass: [ColorViewController class]] &&
        //        [sender isKindOfClass:[UITableViewCell class]] )
        //    {
        //        UILabel* c = [(SWUITableViewCell *)sender label];
        //        ColorViewController* cvc = segue.destinationViewController;
        //
        //        cvc.color = c.textColor;
        //        cvc.text = c.text;
        //    }
        
        // configure the segue.
        if (segue.isKindOfClass(SWRevealViewControllerSegue)) {
            let rvcs: SWRevealViewControllerSegue = segue as SWRevealViewControllerSegue;
            
            let rvc: SWRevealViewController? = self.revealViewController();
            assert(rvc != nil, "oops! must have a revealViewController");
            
            assert(rvc?.frontViewController.isKindOfClass(UINavigationController), "oops!  for this segue we want a permanent navigation controller in the front!");
            
            rvcs.performBlock = {(rvc_segue: SWRevealViewControllerSegue!, svc: UIViewController!, dvc: UIViewController!) -> () in
                //rvc?.pushFrontViewController(dvc, animated: true);
            }
        }
    }
    
        
//        rvcs.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
//        {
//            UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:dvc];
//            [rvc pushFrontViewController:nc animated:YES];
//        };
//        }
//    }

}