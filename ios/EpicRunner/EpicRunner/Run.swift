//
//  Run.swift
//  EpicRunner
//
//  Created by Jeppe on 15/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

import Foundation
import CoreLocation

class Run {
    var dbId: Int? = nil;
    var realRunId: Int? = nil; // the id given by the mighty server
    var start: NSDate? = nil;
    var end: NSDate? = nil;
    var distance: Double = 0.0; // in meters
    var locations: [CLLocation] = [];
    var aborted: Bool = true; // in case of random stuff, true is default
    var runTypeId: Int = 0; //
    var medal: Int = 0; 
    
}