//
//  RunSelectorItemView.m
//  EpicRunner
//
//  Created by Jeppe on 01/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "RunSelectorItemView.h"

@interface RunSelectorItemView ()
    @property CGPoint originalLoc;
    @property CGPoint currentLoc;
    @property BOOL toBeDeleted;
    @property UILabel *lblTimeBar;
@end


@implementation RunSelectorItemView
- (id)initWithFrame:(CGRect)frame andText:(NSString*)text
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.originalLoc = self.frame.origin;
        self.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        self.toBeDeleted = NO;
        
        // Register tap gesture
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleFingerTap];
        
        // Register long tap
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self
                                                   action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 1.5;
        [self addGestureRecognizer:longPress];
        
        // Create timebar label
        self.lblTimeBar = [[UILabel alloc] initWithFrame: CGRectMake(0,38,0,3)];
        UIColor *color = [UIColor colorWithRed:0.2 green:1.0 blue:0.2 alpha:1.0];
        self.lblTimeBar.backgroundColor = color;
        [self addSubview:self.lblTimeBar];
    
        // Insert Text
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(10,0,100,self.frame.size.height)];
        label.text = text;
        [self addSubview:label];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
    // Create time-rect
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //UIColor *color = [UIColor colorWithRed:0.2 green:1.0 blue:0.2 alpha:1.0];
    //CGContextSetFillColorWithColor(context, color.CGColor);
    //CGContextFillRect(context, CGRectMake(0,38,30,3));
//}


- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    //CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    NSLog(@"TAPPED");
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer {
    CGPoint point = [recognizer locationInView:self.superview];
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Move to touched position
        CGPoint center = self.center;
        center.x += point.x - self.currentLoc.x;
        center.y += point.y - self.currentLoc.y;
        self.center = center;
        
        // Check for dropzone
        //NSLog(@"%.f", self.frame.origin.y);
        if (self.frame.origin.y > 320 && self.frame.origin.y < 345) {
            self.toBeDeleted = YES;
            self.backgroundColor = [UIColor colorWithRed:0.7 green:0.1 blue:0.1 alpha:1.0];
        } else {
            self.toBeDeleted = NO;
            self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateBegan){
        NSLog(@"LONG PRESS BEGAN");
        
        self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"LONG PRESS ENDED");
        
        self.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        
        // Check for dropzone
        if (self.toBeDeleted == YES) {
            [self destroy];
        } else {
            //  Restore position
            [UIView animateWithDuration:0.5
                                  delay:0.1
                                options: (UIViewAnimationOptions)UIViewAnimationCurveEaseOut
                             animations:^{
                                 CGRect frame = self.frame;
                                 frame.origin = self.originalLoc;
                                 self.frame = frame;
                             }
                             completion:^(BOOL finished) {
                                 NSLog(@"Completed");
                             }];
        }
    }
    
    self.currentLoc = point;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    NSLog(@"touch begin");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"touch ended");
}

- (void)moveRelative:(BOOL)relative coordX:(int)x coordY:(int)y {
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options: (UIViewAnimationOptions)UIViewAnimationCurveEaseOut
                     animations:^{
                         CGRect frame = self.frame;
                         if (relative) {
                             frame.origin.x += x;
                             frame.origin.y += y;
                         } else {
                             frame.origin.x = x;
                             frame.origin.y = y;
                         }
                         self.originalLoc = frame.origin;
                         self.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         NSLog(@"Completed");
                     }];
}

- (BOOL)tick {
    int i = 15;

    if (self.lblTimeBar.frame.size.width + i > self.frame.size.width) {
        // 100 %, we're done
        [self.lblTimeBar setFrame:CGRectMake(self.lblTimeBar.frame.origin.x,
                                             self.lblTimeBar.frame.origin.y,
                                             self.frame.size.width,
                                             self.lblTimeBar.frame.size.height)];
        
        UIColor *color = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
        self.lblTimeBar.backgroundColor = color;

        NSLog(@"My time is up on this planet! [item commits suicide]");

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // Execute code on the main queue after delay
            [self destroy];
        });
        return YES;
    } else if (self.lblTimeBar.frame.size.width/self.frame.size.width > 0.6){
        // Above 60 %, make yellow, add progress
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:0.2 alpha:1.0];
        self.lblTimeBar.backgroundColor = color;
        
        [self.lblTimeBar setFrame:CGRectMake(self.lblTimeBar.frame.origin.x,
                                             self.lblTimeBar.frame.origin.y,
                                             self.lblTimeBar.frame.size.width+i,
                                             self.lblTimeBar.frame.size.height)];
    } else {
        // All fine, add progress
        [self.lblTimeBar setFrame:CGRectMake(self.lblTimeBar.frame.origin.x,
                                             self.lblTimeBar.frame.origin.y,
                                             self.lblTimeBar.frame.size.width+i,
                                             self.lblTimeBar.frame.size.height)];
    }
    //NSLog(@"ticktick %f", self.lblTimeBar.frame.size.width);
    return NO;
}

- (void)destroy {
    [self removeFromSuperview];
}

@end
