//
//  Book.m
//  Icthus
//
//  Created by Matthew Lorentz on 8/27/13.
//  Copyright (c) 2013 Matthew Lorentz. All rights reserved.
//

#import "Book.h"
#import "AppDelegate.h"


@implementation Book

@dynamic abbr;
@dynamic code;
@dynamic index;
@dynamic longName;
@dynamic reading;
@dynamic shortName;
@dynamic text;
@dynamic translation;
@dynamic numberOfChapters;

-(BookLocation *)getLocation {
    NSManagedObjectContext *context = [(NSManagedObject *)self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BookLocation" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"book = %@", self];
    [request setPredicate:predicate];

    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil)
    {
        NSLog(@"Error fetching BookLocation");
        NSLog(@"%@", [error localizedDescription]);
    }
    
    BookLocation *location;
    if ([array count] >= 1) {
        location = [array firstObject];
    } else {
        AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *managedObjectContext = [appDel managedObjectContext];
        location = [NSEntityDescription insertNewObjectForEntityForName:@"BookLocation" inManagedObjectContext:managedObjectContext];
        [location setBook:self chapter:0 verse:0];
    }
    
    return location;
}

-(void)setLocation:(BookLocation *)location {
    NSManagedObjectContext *context = [(NSManagedObject *)self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BookLocation" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"book = %@", self];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];    
    if (array == nil) {
        NSLog(@"Error fetching old BookLocations");
        NSLog(@"%@", [error localizedDescription]);
    } else {
        // delete the old BookLocations
        for (BookLocation *oldLocation in array) {
            if (![[[oldLocation objectID] URIRepresentation] isEqual:[[location objectID] URIRepresentation]]) {
                [context deleteObject:oldLocation];
            }
        }
    }
    
    [context save:&error];
    if (error != nil) {
        NSLog(@"An error occured during save");
        NSLog(@"%@", [error localizedDescription]);
    }

}

-(void)setLocationForChapter:(int)chapter Verse:(int)verse {
    AppDelegate *appDel = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = [appDel managedObjectContext];
    BookLocation *newLocation = [NSEntityDescription insertNewObjectForEntityForName:@"BookLocation" inManagedObjectContext:managedObjectContext];
    [newLocation setBook:self chapter:chapter verse:verse];
    [self setLocation:newLocation];
}

@end
