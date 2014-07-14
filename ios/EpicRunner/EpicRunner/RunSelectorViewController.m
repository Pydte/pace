//
//  RunSelectorViewController.m
//  EpicRunner
//
//  Created by Jeppe on 01/07/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "RunSelectorViewController.h"
#import "RunSelectorItemView.h"

@interface RunSelectorViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnMenu;
@property int itemHeaderOffset;
@property int itemHeight;
@property int itemVSpacing;
@property int itemMargin;
@property RunSelectorItemView *item1;
@end

@implementation RunSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Always show navigationBar
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillAppear:NO];
    
    // Bind menu button
    [self.btnMenu setTarget: self.revealViewController];
    [self.btnMenu setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
    // Settings
    self.itemHeaderOffset = 75;
    self.itemHeight       = 41;
    self.itemVSpacing     = 10;
    self.itemMargin       = 20;
    
    // Spawn item
    CGRect sliderFrame = CGRectMake(20, -50, self.view.frame.size.width-(self.itemMargin*2), self.itemHeight);
    self.item1 = [[RunSelectorItemView alloc] initWithFrame:sliderFrame andText:@"TYPE"];
    [self.view addSubview:self.item1];
    
    // Move item to correct position
    [self.item1 moveRelative:NO coordX:self.item1.frame.origin.x coordY:self.itemHeaderOffset];
    
    
    // BUG: REMEMBER to delete timer! 
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(sendTicks)
                                   userInfo:nil
                                    repeats:YES];
    
}

- (void)sendTicks {
    if (self.item1 != nil && [self.item1 tick]) {
        // Item dead
        self.item1 = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
