//
//  ReadingViewController.m
//  Bible
//
//  Created by Matthew Lorentz on 8/27/13.
//  Copyright (c) 2013 Matthew Lorentz. All rights reserved.
//

#import "ReadingViewController.h"
#import "ReadingView.h"
#import "BookLocation.h"
#import "AppDelegate.h"

@interface ReadingViewController ()

@end

@implementation ReadingViewController

@synthesize book = _book;
@synthesize popoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)awakeFromNib {
    self.splitViewController.delegate = self;
    
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = appDel.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Book" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Find only Books for the current translation
    NSString *translationCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedTranslation"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"translation == '%@'", translationCode]]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"shortName" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:fetchRequest error:&error];
    if (array == nil)
    {
        // Deal with error...
    } else {
        [self setBook:[array firstObject]];
    }
}

- (id)initWithBook:(Book *)book {
    self = [super init];
    if (self) {
        _book = book;
    }
    return self;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    barButtonItem.title = @"Menu";
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.popoverController = pc;
}

- (void)setBook:(Book *)newBook {
    if (_book != newBook) {
        _book = newBook;
        [_book setReading:[NSNumber numberWithBool:YES]];
        NSManagedObjectContext *context = [(NSManagedObject *)_book managedObjectContext];
        NSError *error;
        [context save:&error];
        if (error != nil) {
            NSLog(@"An error occured during save");
            NSLog(@"%@", [error localizedDescription]);
        }
        
        // Update the view.
        [self configureView];
    }
    
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (_book) {
        self.navigationItem.title = [_book shortName];
        [self.readingView setBook:_book];
        [self.readingView setText:[_book text]];
        [self.readingView setCurrentLocation:[_book getLocation]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.readingView saveLocation];
}



@end
