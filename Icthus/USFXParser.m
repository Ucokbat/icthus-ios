//
//  USFXParser.m
//  Icthus
//
//  Created by Matthew Lorentz on 3/10/14.
//  Copyright (c) 2014 Matthew Lorentz. All rights reserved.
//

#import "USFXParser.h"
#import "Translation.h"
#import "Book.h"

@implementation USFXParser

@synthesize nameParser = _nameParser;
@synthesize bookParser = _bookParser;
@synthesize context = _context;
@synthesize booksByCode = _booksByCode;
@synthesize currentBook = _currentBook;

NSArray *includedBooks;
NSMutableString *mutableBookText;
int chapterIndex;
bool shouldParseCharacters;
bool shouldParseBook;
static NSString *translationCode;
static NSString *translationDisplayName;

- (void) instantiateBooks:(NSManagedObjectContext *)context translationCode:(NSString *)code displayName:(NSString *)displayName bookNamePath:(NSString *)bookNamePath bookTextPath:(NSString *)bookTextPath {
    translationCode = code;
    translationDisplayName = displayName;
    _context = context;
    _booksByCode = [[NSMutableDictionary alloc] init];
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Define the books we will include
    includedBooks = @[@"GEN",@"EXO",@"LEV",@"NUM",@"DEU",@"JOS",@"JDG",@"RUT",@"1SA",@"2SA",@"1KI",@"2KI",@"1CH",@"2CH",@"EZR",@"NEH",@"EST",@"JOB",@"PSA",@"PRO",@"ECC",@"SNG",@"ISA",@"JER",@"LAM",@"EZK",@"DAN",@"HOS",@"JOL",@"AMO",@"OBA",@"JON",@"MIC",@"NAM",@"HAB",@"ZEP",@"HAG",@"ZEC",@"MAL",@"MAT",@"MRK",@"LUK",@"JHN",@"ACT",@"ROM",@"1CO",@"2CO",@"GAL",@"EPH",@"PHP",@"COL",@"1TH",@"2TH",@"1TI",@"2TI",@"TIT",@"PHM",@"HEB",@"JAS",@"1PE",@"2PE",@"1JN",@"2JN",@"3JN",@"JUD",@"REV",];
    
    Translation *trans = [NSEntityDescription insertNewObjectForEntityForName:@"Translation" inManagedObjectContext:_context];
    [trans setCode:translationCode];
    [trans setDisplayName:translationDisplayName];
    
    _nameParser = [[NSXMLParser alloc] initWithData:[[NSData alloc] initWithContentsOfFile:bookNamePath]];
    [_nameParser setDelegate:self];
    
    if ([_nameParser parse]) {
        NSLog(@"Successfully parsed %@ book names", displayName);
    } else {
        NSLog(@"An error occured parsing %@ book names", displayName);
    }
    
    _bookParser = [[NSXMLParser alloc] initWithData:[[NSData alloc] initWithContentsOfFile:bookTextPath]];
    [_bookParser setDelegate:self];
    
    if ([_bookParser parse]) {
        NSLog(@"Successfully parsed %@ books", displayName);
    } else {
        NSLog(@"An error occured parsing %@ books", displayName);
    }
    
    NSError *error;
    [appDel.persistentStoreCoordinator lock];
    if (![_context save:&error]) {
        NSLog(@"Error saving books: %@", [error localizedDescription]);
    }
    [appDel.persistentStoreCoordinator unlock];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    if (parser == _nameParser && [elementName isEqual: @"book"]) {
        NSUInteger bookIndex = [includedBooks indexOfObject:[attributeDict valueForKey:@"code"]];
        if (bookIndex != NSNotFound) {
            Book *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:_context];
            [book setCode:[attributeDict valueForKey:@"code"]];
            [book setIndex:[NSNumber numberWithInteger:bookIndex]];
            [book setLongName:[attributeDict valueForKey:@"long"]];
            [book setShortName:[attributeDict valueForKey:@"short"]];
            [book setAbbr:[attributeDict valueForKey:@"abbr"]];
            [book setTranslation:translationCode];
            [book setText:@""];
            [_booksByCode setValue:book forKey:[book code]];
        }
    } else if ([elementName isEqualToString:@"book"]) {
        NSUInteger bookIndex = [includedBooks indexOfObject:[attributeDict valueForKey:@"id"]];
        if (bookIndex == NSNotFound) {
            shouldParseBook = NO;
        } else {
            shouldParseBook = YES;
            _currentBook = [_booksByCode valueForKey:[attributeDict valueForKey:@"id"]];
            mutableBookText = [[NSMutableString alloc] initWithString:@"<book>"];
            chapterIndex = 0;
        }
    } else if (shouldParseBook) {
        if ([elementName isEqualToString:@"p"]) {
            shouldParseCharacters = YES;
            // add a newline and a tab
            [mutableBookText appendString:@"\n\t"];
        } else if ([elementName isEqualToString:@"q"]) {
            // These are lyrical verses. Insert a newline.
            [mutableBookText appendString:@"\n"];
        } else if ([elementName isEqualToString:@"f"]) {
            shouldParseCharacters = NO;
        } else if ([elementName isEqualToString:@"v"]) {
            shouldParseCharacters = YES;
            [mutableBookText appendString:[NSString stringWithFormat:@"<v i=\"%d\">", [[attributeDict objectForKey:@"id"] intValue]]];
        } else if ([elementName isEqualToString:@"qt"] ||
                   [elementName isEqualToString:@"wj"] ||
                   [elementName isEqualToString:@"tl"] ||
                   [elementName isEqualToString:@"qac"] ||
                   [elementName isEqualToString:@"sls"] ||
                   [elementName isEqualToString:@"bk"] ||
                   [elementName isEqualToString:@"pn"] ||
                   [elementName isEqualToString:@"k"] ||
                   [elementName isEqualToString:@"ord"] ||
                   [elementName isEqualToString:@"sig"] ||
                   [elementName isEqualToString:@"bd"] ||
                   [elementName isEqualToString:@"it"] ||
                   [elementName isEqualToString:@"bdit"] ||
                   [elementName isEqualToString:@"sc"] ||
                   [elementName isEqualToString:@"no"] ||
                   [elementName isEqualToString:@"quoteStart"] ||
                   [elementName isEqualToString:@"quoteEnd"] ||
                   [elementName isEqualToString:@"quoteRemind"] ||
                   [elementName isEqualToString:@"nd"]) {
            shouldParseCharacters = YES;
        } else if ([elementName isEqualToString:@"qs"]) {
            // For the "Selah" in the Psalms
            shouldParseCharacters = YES;
        } else if ([elementName isEqualToString:@"d"]) {
            // Indicating the title of a Psalm
            shouldParseCharacters = YES;
            [mutableBookText appendString:@"\n"];
        } else if ([elementName isEqualToString:@"c"]) {
            if (chapterIndex != 0) {
                [mutableBookText appendString:@"</c>"];
            }
            chapterIndex = [(NSString *)[attributeDict objectForKey:@"id"] intValue];
            [mutableBookText appendString:[NSString stringWithFormat:@"<c i=\"%@\">", [attributeDict objectForKey:@"id"]]];
        } else {
            shouldParseCharacters = NO;
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
    if (parser == _bookParser && [elementName isEqualToString:@"book"] && shouldParseBook) {
        [mutableBookText appendString:@"</c></book>"];
        // Remove any blocks of spaces
        NSString *replacedText = [self cleanBookText:mutableBookText];
        [_currentBook setText:replacedText];
        [_currentBook setNumberOfChapters:[NSNumber numberWithInt:chapterIndex]];
    } else if (shouldParseBook) {
        if ([elementName isEqualToString:@"p"]) {
            shouldParseCharacters = NO;
        } else if ([elementName isEqualToString:@"f"]) {
            shouldParseCharacters = YES;
        } else if ([elementName isEqualToString:@"ve"]) {
            shouldParseCharacters = NO;
            [mutableBookText appendString:@"</v>"];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (shouldParseBook && shouldParseCharacters) {
        // remove the newlines in the xml. Replace with spaces.
        string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        [mutableBookText appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"A parsing error occured");
    NSLog(@"%@", [parseError localizedDescription]);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {

}

- (NSString *)cleanBookText:(NSString *)bookText {
    NSError *error;
    
    // Parse double spaces by themselves
    NSRegularExpression *filterSpaces = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        bookText = [filterSpaces stringByReplacingMatchesInString:bookText options:0 range:NSMakeRange(0, [bookText length]) withTemplate:@" "];
    }
    
    // Parse double spaces separeted by verse tags
    NSRegularExpression *filterSpacesWithVerseTags = [NSRegularExpression regularExpressionWithPattern:@" +(</v><v i=\"[0-9]+\">) +" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        bookText = [filterSpacesWithVerseTags stringByReplacingMatchesInString:bookText options:0 range:NSMakeRange(0, [bookText length]) withTemplate:@" $1"];
    }
    
    // parse double spaces separated by chapter tags
    NSRegularExpression *filterSpacesWithChapterTags = [NSRegularExpression regularExpressionWithPattern:@" +(</v></c><c i=\"[0-9]\"><v i=\"[0-9]+\">) +" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        bookText = [filterSpacesWithChapterTags stringByReplacingMatchesInString:bookText options:0 range:NSMakeRange(0, [bookText length]) withTemplate:@" $1"];
    }
    
    return bookText;
}


@end