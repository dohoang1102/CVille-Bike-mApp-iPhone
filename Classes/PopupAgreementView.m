//
//  PopupAgreementView.m
//  CycleTracks
//
//  Created by Harsha on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PopupAgreementView.h"


@implementation PopupAgreementView
{
    //UITextView *tview;
    //id<AgreementViewControllerDelegate> vcdelegate;
}

@synthesize tview = _tview;
@synthesize vcdelegate = _vcdelegate;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

/*- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}*/


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    //NSLog(@"In PopupAgreementView:viewDidLoad");
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSError *err = nil;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"agreement" ofType:@"txt"];
    self.tview.text =[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
}

- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"in PopupAgreementView:viewDidAppear self: %@ - delegate: %@", self, vcdelegate);
}

- (void)viewDidUnload
{
    [self setTview:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)proceedButtonPressed:(id)sender {
    //NSLog(@"proceedButtonPressed");
    [self.vcdelegate didDismissModalViewWithProceed];
}

- (IBAction)quitButtonPressed:(id)sender {
    //NSLog(@"quitButtonPressed");
    [self.vcdelegate didDismissModalViewWithQuit];
}
@end
