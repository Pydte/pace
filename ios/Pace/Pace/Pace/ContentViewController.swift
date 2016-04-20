//
//  ContentViewController.swift
//  Pace
//
//  Created by Jeppe Richardt on 24/12/15.
//  Copyright © 2015 Pandigames. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var pageIndex: Int!
    var titleText: String!
    var imageFile: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = UIImage(named: self.imageFile)
        self.titleLabel.text = self.titleText
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
}
