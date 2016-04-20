//
//  RunView.swift
//  Pace
//
//  Created by Jeppe Richardt on 16/02/16.
//  Copyright © 2016 Pandigames. All rights reserved.
//

import UIKit

class RunView: UIView {
    @IBOutlet weak var lblRunType: UILabel!
    @IBOutlet weak var medalBronze: UIView!
    @IBOutlet weak var medalSilver: UIView!
    @IBOutlet weak var medalGold: UIView!
    @IBOutlet weak var lblRoughDistance: UILabel!
    @IBOutlet weak var lblEstimatedScore: UILabel!
    
    var type: Int = 0;
    var expiresUnix: Int = 1231;
    var roughDistanceKm: Double = 2.0;
    var estimatedTimeMin: Int = 10;
    var estimatedScore: Int = 1230;
    var medalTimeBronze: Double = 14;
    var medalTimeSilver: Double = 10;
    var medalTimeGold: Double = 8;
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("init run")
    }

    convenience init() {
        self.init(frame: CGRect.zero)
        print("tet")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("her")
    }
    
    func setRunType(runType: String) {
        print("is claled")
        lblRunType.text = runType
        lblRoughDistance.text = String(format:"%.0f", roughDistanceKm)
        lblEstimatedScore.text = String(format:"%i", estimatedScore)
        
        medalBronze.layer.cornerRadius = medalBronze.frame.width/2
        medalSilver.layer.cornerRadius = medalSilver.frame.width/2
        medalGold.layer.cornerRadius = medalGold.frame.width/2
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    
    
}
