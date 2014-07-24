//
//  Run.swift
//  EpicRunner
//
//  Created by Jeppe on 15/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import Foundation

class Run {
    var dbId: Int? = nil;
    var start: NSDate? = nil;
    var end: NSDate? = nil;
    var distance: Double = 0.0; // in meters
    var locations: [CLLocation] = [];
}