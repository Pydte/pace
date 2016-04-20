//
//  RunSelectorViewController.swift
//  Pace
//
//  Created by Jeppe Richardt on 14/02/16.
//  Copyright © 2016 Pandigames. All rights reserved.
//

import UIKit

class RunSelectorViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var btnChooseRun: UIButton!
    @IBOutlet weak var te: iCarousel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("runselector init")
        
        // Bind menu button
        if self.revealViewController() != nil {
            self.menuBtn.target = self.revealViewController();
            self.menuBtn.action = "revealToggle:";
            self.navigationController?.navigationBar.addGestureRecognizer(self.revealViewController().panGestureRecognizer());
        }
        
        // Transparent navigation bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        // Choose Run button
        btnChooseRun.layer.cornerRadius = 15;
        
        // Carousel
        te.type = iCarouselType.CoverFlow
        te.bounces = true
        te.bounceDistance = 0.25
        te.pagingEnabled = false
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit { print("runselector is being deinitialized") }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return 5
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        // View
        let imageView = UINib(nibName: "RunView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! RunView
        
        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width*0.8, height: self.view.frame.size.height*0.63)
        imageView.layer.cornerRadius = 5;
        //imageView.layoutIfNeeded()
        
        // Border
        let borderWidth:CGFloat = 1.0;
        imageView.frame = CGRectInset(imageView.frame, -borderWidth, -borderWidth);
        imageView.layer.borderColor = UIColor(red: 0.866, green: 0.866, blue: 0.866, alpha: 1).CGColor;
        imageView.layer.borderWidth = borderWidth;
        
        // Demo Data
        switch index {
        case 0:
            imageView.roughDistanceKm = 2
            imageView.estimatedScore = 1230
            imageView.setRunType("Collector Run")
        case 1:
            imageView.roughDistanceKm = 1
            imageView.estimatedScore = 700
            imageView.setRunType("Interval Run")
        case 2:
            imageView.roughDistanceKm = 4
            imageView.estimatedScore = 1500
            imageView.setRunType("Collector Run")
        case 3:
            imageView.roughDistanceKm = 5
            imageView.estimatedScore = 1670
            imageView.setRunType("Collector Run")
        case 4:
            imageView.roughDistanceKm = 6
            imageView.estimatedScore = 1710
            imageView.setRunType("Interval Run")
        default:
            imageView.roughDistanceKm = 9
            imageView.estimatedScore = 2313
            imageView.setRunType("Unknown Run")
        }
        
        //let imageView: UIImageView
        
        /*if view != nil {
            imageView = view as! UIImageView
        } else {
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width*0.9, height: self.view.frame.size.height*1.2))
        }*/

        //imageView.image = UIImage(named: "page.png")
        imageView.translatesAutoresizingMaskIntoConstraints = true
        return imageView
    }
    @IBAction func btnChooseRun(sender: AnyObject) {
        print("Choose run")
        let t: RunView = te.currentItemView as! RunView
        print(t.roughDistanceKm)
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
