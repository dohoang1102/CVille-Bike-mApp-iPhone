//
//  AgreementView.m
//  CycleTracks
//
//  Created by Harsha Chenji on 4/10/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import "AgreementView.h"
#import "PopupAgreementView.h"
#import "PersonalInfoViewController.h"
#import "constants.h"

@implementation AgreementView
{
	//UITextView *tview;
    //UIWebView *webview;
    //NSManagedObjectContext *managedObjectContext;
    //User *user;
}


@synthesize tview = _tview;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize user = _user;
@synthesize webview = _webview;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (User *)createUser
{
	// Create and configure a new instance of the User entity
	User *noob = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"createUser error %@, %@", error, [error localizedDescription]);
	}
	[noob setHasaccepted:@"No"];
    [noob setHasenteredvalidinfo:@"No"];
    [noob setLastendlat:[[NSNumber alloc] initWithDouble:0.0]];
    [noob setLastendlong:[[NSNumber alloc] initWithDouble:0.0]];
    
    
    
	return noob;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	NSLog(@"in viewDidLoad...");
    
    self.webview = [[UIWebView alloc] initWithFrame:CGRectMake(5, 70, 310, 300)];
    self.webview.autoresizesSubviews = YES;
    [self.webview setBackgroundColor:[UIColor clearColor]];  
    [self.webview setOpaque:NO];
    [[self view] addSubview:self.webview];
    
    
    NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];

    NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	NSLog(@"saved user count  = %d", count);
	if ( count == 0 )
	{
		// create an empty User entity
		[self setUser:[self createUser]];
	}
	
	NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"no saved user");
		if ( error != nil )
			NSLog(@"PersonalInfo viewDidLoad fetch error %@, %@", error, [error localizedDescription]);
	}
	
	[self setUser:[mutableFetchResults objectAtIndex:0]];
	if ( self.user != nil )
	{
        if ([self.user.hasaccepted isEqualToString:@"No"]) {
            //NSLog(@"about to popup agreement view");
            [self performSegueWithIdentifier:@"agreementPopupTransition" sender:self];
            //PopupAgreementView *aview = [[PopupAgreementView alloc] init];
            //[self presentModalViewController:aview animated:YES];
            //[self presentModalViewController:PopupAgreementView animated:
            //[self presentModalViewController: animated:YES];
            //PopupAgreementView *aview = [[PopupAgreementView alloc] initWithNibName:@"PopupAgreementView" bundle:nil];
            
            //aview.delegate = self;
            
            //[self presentModalViewController:aview animated:YES];
            
        } else {
            //NSError *err = nil;
            //NSString* filePath = [[NSBundle mainBundle] pathForResource:@"agreement" 
            //                                                     ofType:@"rtf"];
//            tview.text = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
            self.tview.text = @"You've accepted the agreement. Information:\n--------------------------------------------";
            
            NSURL *url = [[NSURL alloc] initWithString:kInfoURL];
            NSURLRequest *req = [NSURLRequest requestWithURL:url];
            [self.webview loadRequest:req];
            
        }
        
        if ([self.user.hasenteredvalidinfo isEqualToString:@"No"]) {
            [self.tabBarController.tabBar setUserInteractionEnabled:FALSE];
            self.tabBarController.selectedIndex = 3;
        } else {
            [self.tabBarController.tabBar setUserInteractionEnabled:YES];
//            self.tabBarController.selectedIndex = 3;
        }
	}
	else
		NSLog(@"init FAIL");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //NSLog(@"in viewDidAppear...");
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {


    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"agreementPopupTransition"]){
        //NSLog(@"in prepareForSegue...");
        [[segue destinationViewController] setVcdelegate:self];
        //NSLog(@"self: %@ - state of destVC: %@ - vcdelegate: %@", self, [segue destinationViewController], [[segue destinationViewController] vcdelegate]);
    }
}

- (void)didDismissModalViewWithProceed {
    NSLog(@"didDismissModalViewWithProceed");
    
    // Dismiss the modal view controller
    [self dismissModalViewControllerAnimated:YES];
    
    //NSError *err = nil;
    //NSString* filePath = [[NSBundle mainBundle] pathForResource:@"agreement" 
     //                                               ofType:@"rtf"];
//    tview.text = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    
//    tview.text = @"You've accepted the agreement!";
    self.tview.text = @"You've accepted the agreement. Information:\n--------------------------------------------";
    
    NSURL *url = [[NSURL alloc] initWithString:kInfoURL];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:req];
    
    [self.user setHasaccepted:@"Yes"];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"PersonalInfo save cycling freq error %@, %@", error, [error localizedDescription]);
    }
    
//    PersonalInfoViewController *aview = [[PersonalInfoViewController alloc] initWithNibName:@"PersonalInfo" bundle:nil];
//    
//    aview.modaldelegate = self;
//    
//    [self presentModalViewController:aview animated:YES];
//    [aview release];
    
  	self.tabBarController.selectedIndex = 3;
    
    [self.tabBarController.tabBar setUserInteractionEnabled:FALSE];
    
}

- (void)didDismissModalViewWithQuit {
    NSLog(@"didDismissModalViewWithQuit");
    
    // Dismiss the modal view controller
    [self dismissModalViewControllerAnimated:YES];
    self.tview.text = @"You've not accepted the agreement.";
    [self.user setHasaccepted:@"No"];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"PersonalInfo save cycling freq error %@, %@", error, [error localizedDescription]);
    }
    exit(0);
    
}

@end
