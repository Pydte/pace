//
//  RunSelectorViewController.m
//  EpicRunner
//
//  Created by Jeppe on 30/04/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "RunSelectorViewController.h"
#import "MapViewController.h"

@interface RunSelectorViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnMenu;

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
    
    // Bind menu button
    [self.btnMenu setTarget: self.revealViewController];
    [self.btnMenu setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"SegueMultiplayer"])
    {
        MapViewController *mapViewController = segue.destinationViewController;
        mapViewController.multiplayer = true;
    } else if ([segue.identifier isEqualToString:@"Segue1AutoRoute"]) {
        MapViewController *mapViewController = segue.destinationViewController;
        mapViewController.autoroute1 = true;
    }
}


@end