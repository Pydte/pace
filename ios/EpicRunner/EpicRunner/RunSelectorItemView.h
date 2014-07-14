//
//  RunSelectorItemView.h
//  EpicRunner
//
//  Created by Jeppe on 01/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RunSelectorItemView : UIView
- (id)initWithFrame:(CGRect)frame andText:(NSString*)text;
- (void)moveRelative:(BOOL)relative coordX:(int)x coordY:(int)y;
- (BOOL)tick;
@end
