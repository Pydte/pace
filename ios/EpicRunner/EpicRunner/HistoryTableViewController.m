//
//  HistoryTableViewController.m
//  EpicRunner
//
//  Created by Jeppe on 25/03/14.
//  Copyright (c) 2014 Pandisign ApS. All rights reserved.
//

#import "HistoryTableViewController.h"
#import "Run.h"
#import <tgmath.h>

@interface HistoryTableViewController ()

@end

@implementation HistoryTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mainDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    
    // Initialize runs array and load dummy data
    self.runs = [[NSMutableArray alloc] init];
    [self loadData];
    //[self loadInitialDummyData];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.runs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM HH:mm"];
    
    static NSString *CellIdentifier = @"HistoryPrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    Run *run = [self.runs objectAtIndex:indexPath.row];
    NSTimeInterval runTimeInSeconds = [run.end timeIntervalSinceDate:run.start];
    int runTimeInMinutes = runTimeInSeconds/60;
    int runTimeRemainingSeconds = fmod(runTimeInSeconds, 60);
    NSMutableString *runText = [[NSMutableString alloc] init];
    [runText appendString:[dateFormatter stringFromDate:run.start]];
    [runText appendString:@" - "];
    [runText appendString:[NSString stringWithFormat:@"%.2f",run.distance/1000]];
    [runText appendString:@" km in "];
    [runText appendString:[NSString stringWithFormat:@"%d",runTimeInMinutes]];
    [runText appendString:@":"];
    [runText appendString:[NSString stringWithFormat:@"%d",runTimeRemainingSeconds]];
    [runText appendString:@" min"];
    cell.textLabel.text = runText;
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)loadData {
    // Load runs from database
    sqlite3 *database;
    sqlite3_stmt *statement;
    
    // Open database
    if(sqlite3_open(self.mainDelegate.databasePath, &database) != SQLITE_OK) {
        NSLog(@"[ERROR] SQLITE: Failed to open database! Error: '%s' - RunFinishedSummaryViewController:viewDidLoad", sqlite3_errmsg(database));
		return;
    }
    
    // Read
    if(sqlite3_prepare_v2(database, "SELECT startDate, endDate, distance FROM runs ORDER BY startDate DESC", -1, &statement, nil) != SQLITE_OK){
		NSLog(@"[ERROR] SQLITE: Failed to prepare statement! Error: '%s' - HistoryTableViewController:loadData", sqlite3_errmsg(database));
		return;
	}
    
	while(sqlite3_step(statement) == SQLITE_ROW) {
		int startDate = (int)sqlite3_column_int(statement, 0);
		int endDate = (int)sqlite3_column_int(statement, 1);
		double distance = (double)sqlite3_column_double(statement, 2);
		
        Run *run = [[Run alloc] init];
        run.start = [NSDate dateWithTimeIntervalSince1970:startDate];
        run.end = [NSDate dateWithTimeIntervalSince1970:endDate];
        run.distance = distance;
        [self.runs addObject:run];
	}
    sqlite3_finalize(statement);
    
    //Close db
    sqlite3_close(database);
    database = nil;
    
}


- (void)loadInitialDummyData {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    Run *run1 = [[Run alloc] init];
    run1.start = [dateFormatter dateFromString:@"2014-03-25 15:13:00"];
    run1.end = [dateFormatter dateFromString:@"2014-03-25 15:30:00"];
    run1.distance = 4.27;
    [self.runs addObject:run1];
    
    Run *run2 = [[Run alloc] init];
    run2.start = [dateFormatter dateFromString:@"2014-03-23 14:42:00"];
    run2.end = [dateFormatter dateFromString:@"2014-03-23 15:02:20"];
    run2.distance = 3.96;
    [self.runs addObject:run2];
}

@end
