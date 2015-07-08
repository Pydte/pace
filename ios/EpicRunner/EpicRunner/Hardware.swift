//
//  hardware.swift
//  EpicRunner
//
//  Created by Jeppe on 09/04/15.
//  Copyright (c) 2015 Pandisign ApS. All rights reserved.
//

import UIKit

class Hardware {
    // Phone1,1   ==   iPhone 2G
    // Phone1,2   ==   iPhone 3G
    // Phone2,1   ==   iPhone 3GS
    // Phone3,1   ==   iPhone 4 (GSM)
    // Phone3,2   ==   iPhone 4 (GSM Rev. A)
    // Phone3,3   ==   iPhone 4 (CDMA)
    // Phone4,1   ==   iPhone 4S
    // Phone5,1   ==   iPhone 5 (GSM)
    // Phone5,2   ==   iPhone 5 (Global)
    // Phone5,3   ==   iPhone 5C (GSM)
    // Phone5,4   ==   iPhone 5C (Global)
    // Phone6,1   ==   iPhone 5S (GSM)
    // Phone6,2   ==   iPhone 5S (Global)
    // Phone7,1   ==   iPhone 6 Plus
    // Phone7,2   ==   iPhone 6
    //
    // Pod1,1   ==    iPod Touch (1 Gen)
    // Pod2,1   ==    iPod Touch (2 Gen)
    // Pod3,1   ==    iPod Touch (3 Gen)
    // Pod4,1   ==    iPod Touch (4 Gen)
    // Pod5,1   ==    iPod Touch (5 Gen)
    //
    // Pad1,1   ==    iPad (WiFi)
    // Pad1,2   ==    iPad 3G
    // Pad2,1   ==    iPad 2 (WiFi)
    // Pad2,2   ==    iPad 2 (GSM)
    // Pad2,3   ==    iPad 2 (CDMA)
    // Pad2,4   ==    iPad 2 (WiFi Rev. A)
    // Pad2,5   ==    iPad Mini (WiFi)
    // Pad2,6   ==    iPad Mini (GSM)
    // Pad2,7   ==    iPad Mini (CDMA)
    // Pad3,1   ==    iPad 3 (WiFi)
    // Pad3,2   ==    iPad 3 (CDMA)
    // Pad3,3   ==    iPad 3 (Global)
    // Pad3,4   ==    iPad 4 (WiFi)
    // Pad3,5   ==    iPad 4 (CDMA)
    // Pad3,6   ==    iPad 4 (Global)
    // Pad4,1   ==    iPad Air (WiFi)
    // Pad4,2   ==    iPad Air (WiFi+GSM)
    // Pad4,3   ==    iPad Air (WiFi+CDMA)
    // Pad4,4   ==    iPad Mini Retina (WiFi)
    // Pad4,5   ==    iPad Mini Retina (WiFi+CDMA)
    // Pad4,6   ==    iPad Mini Retina (Wi-Fi + Cellular CN)
    // Pad4,7   ==    iPad Mini 3 (Wi-Fi)
    // Pad4,8   ==    iPad Mini 3 (Wi-Fi + Cellular)
    // Pad5,3   ==    iPad Air 2 (Wi-Fi)
    // Pad5,4   ==    iPad Air 2 (Wi-Fi + Cellular)
    // 
    // 386      ==    Simulator
    // 86_64    ==    Simulator
    func toString() -> String {
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var size: Int = 2
        sysctl(&name, 2, nil, &size, &name, 0)
        var hw_machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctl(&name, 2, &hw_machine, &size, &name, 0)
        
        let hardware: String = String.fromCString(hw_machine)!
        return hardware
    }
}
    