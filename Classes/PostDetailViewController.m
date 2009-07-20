//
//  PostDetailViewController.m
//  postmap
//
//  Created by jun on 09/07/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PostDetailViewController.h"
#import "PostAnnotation.h"


@implementation PostDetailViewController

@synthesize post;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Info";
    postNameLabel.text = @"Loading...";
    timesGathered = [[NSMutableArray alloc] init];
    
    [self performSelectorInBackground:@selector(loadDetail) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated;    // Called when the view is about to made visible. Default does nothing
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];  
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.post = nil;
    
    [timesGathered release], timesGathered = nil;
    
    [super dealloc];
}

#pragma mark -

- (void)loadDetail
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSURL *detailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://postmap.org/ajax?type=map%%7Ciw&id=%@",
                                              post.postID]];
    NSLog(@"detailURL: %@", detailURL);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // raw '&' cause resolve error
    NSString *detailHTML = [NSString stringWithContentsOfURL:detailURL encoding:NSUTF8StringEncoding error:nil];
    detailHTML = [detailHTML stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[detailHTML dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    [parser setDelegate:self];
    BOOL parsed = [parser parse];
    NSLog(@"parsed: %d. error = %@", parsed, [parser parserError]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [(UITableView *)self.view performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    [pool release];
}

enum {
    kParsingKindNone = 0,
    kParsingKindPostName,
    kParsingKindTimesGatheredName,
    kParsingKindTimesGatheredTime,
};

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
//    NSLog(@"start [%@], attrs = %@", elementName, attributeDict);
    
    if ([elementName isEqualToString:@"a"]) {
        NSString *href = [attributeDict objectForKey:@"href"];
        if ([href hasPrefix:@"/map"]) {
            postNameLabel.text = @"";
            parsingKind = kParsingKindPostName;
        }
    } 
    
    if ([elementName isEqualToString:@"img"] && !postPictureView.image) {
        NSString *src = [attributeDict objectForKey:@"src"];
        if ([src hasPrefix:@"/img"]) {
            NSURL *postPictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://postmap.org%@&width=100&height=75", src]];
            UIImage *postPicture = [UIImage imageWithData:[NSData dataWithContentsOfURL:postPictureURL]];
            postPictureView.image = postPicture;
        }
    }
    
    if ([elementName isEqualToString:@"th"]) {
        [timesGathered addObject:[NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:@"times"]];
        parsingKind = kParsingKindTimesGatheredName;
    }    
    if ([elementName isEqualToString:@"tr"]) {
        parsingTDIndex = 0;
    }    
    if ([elementName isEqualToString:@"td"]) {
        [[[timesGathered objectAtIndex:parsingTDIndex] objectForKey:@"times"] addObject:@""];
        parsingKind = kParsingKindTimesGatheredTime;
    }
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
{
    if (parsingKind == kParsingKindPostName) parsingKind = kParsingKindNone;
    if ([elementName isEqualToString:@"th"]) parsingKind = kParsingKindNone;
    if ([elementName isEqualToString:@"td"]) {
        NSMutableArray *times = [[timesGathered objectAtIndex:parsingTDIndex] objectForKey:@"times"];
        NSString *time = [times lastObject];
        if ([time length] <= 0) [times removeLastObject];
        
        parsingKind = kParsingKindNone;
        ++parsingTDIndex;
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
//    NSLog(@"foundCharacters: %@, parsingKind = %d", string, parsingKind);
    if (parsingKind == kParsingKindPostName) {
        postNameLabel.text = [postNameLabel.text stringByAppendingString:string];
    }
    
    if (parsingKind == kParsingKindTimesGatheredName) {
        NSMutableDictionary *timesDict = [timesGathered lastObject];
        NSString *name = [timesDict objectForKey:@"name"];
        if (!name) name = string;
        else name = [name stringByAppendingString:string];
        [timesDict setObject:name forKey:@"name"];
    }
    
    if (parsingKind == kParsingKindTimesGatheredTime) {
        NSMutableArray *times = [[timesGathered objectAtIndex:parsingTDIndex] objectForKey:@"times"];
        NSString *time = [times lastObject];
        if (!time) time = string;
        else time = [time stringByAppendingString:string];
        [times removeLastObject];
        [times addObject:time];
    }
}


#pragma mark -
#pragma mark TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [timesGathered count];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[timesGathered objectAtIndex:section] objectForKey:@"name"];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [[[timesGathered objectAtIndex:section] objectForKey:@"times"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeGathered"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TimeGathered"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSMutableArray *times = [[timesGathered objectAtIndex:indexPath.section] objectForKey:@"times"];    
    cell.textLabel.text = [times objectAtIndex:indexPath.row];
    return cell;
}


@end
