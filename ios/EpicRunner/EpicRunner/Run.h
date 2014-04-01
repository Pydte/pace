//
//  Run.h
//  EpicRunner
//
//  Created by Jeppe on 25/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Run : NSObject

@property NSDate *start;
@property NSDate *end;
@property double distance;
@property NSMutableArray *locations;

@end
