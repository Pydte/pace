//
//  AppetizerViewController.swift
//  Pace
//
//  Created by Jeppe Richardt on 24/12/15.
//  Copyright © 2015 Pandigames. All rights reserved.
//

import UIKit

class AppetizerViewController: UIViewController, UIPageViewControllerDataSource {

    var pageViewController: UIPageViewController!
    var pageTitles: NSArray!
    var pageImages: NSArray!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("appetizer init")

        self.pageTitles = NSArray(objects: "Side 1", "Side 2")
        self.pageImages = NSArray(objects: "appetizer1", "appetizer2")
        
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        
        let startVC = self.viewControllerAtIndex(0) as ContentViewController
        let viewControllers = NSArray(object: startVC) as! [UIViewController]
        self.pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.size.height-1)
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.view.bringSubviewToFront(self.pageViewController.view)
        self.pageControl.numberOfPages = self.pageTitles.count
    }
    deinit { print("appetizer is being deinitialized") }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewControllerAtIndex(index: Int) -> ContentViewController {
        if ((self.pageTitles.count == 0) || (index >= self.pageTitles.count)) {
            return ContentViewController()
        }
        
        let vc: ContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
        vc.imageFile = self.pageImages[index] as! String
        vc.titleText = self.pageTitles[index] as! String
        vc.pageIndex = index
        
        return vc
    }
    
    // MARK: Page View Controller Data Source

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        self.pageControl.currentPage = index
        if (index == 0) || index == NSNotFound {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        self.pageControl.currentPage = index
        index++

        if (index == 0) || index == NSNotFound {
            return nil
        }
        if (index == self.pageTitles.count) {
            return nil
        }
        
        return viewControllerAtIndex(index)
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
