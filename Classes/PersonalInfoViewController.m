/**  CycleTracks, Copyright 2009,2010 San Francisco County Transportation Authority
 *                                    San Francisco, CA, USA
 *
 *   @author Matt Paul <mattpaul@mopimp.com>
 *
 *   This file is part of CycleTracks.
 *
 *   CycleTracks is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   CycleTracks is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with CycleTracks.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  PersonalInfoViewController.m
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/23/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import "PersonalInfoViewController.h"
#import "User.h"

#define kMaxCyclingFreq 3

@implementation PersonalInfoViewController
{
    UIPickerView *uvaClassificationPicker;
    NSMutableArray* arrayUVAClassifications;
    
    UIPickerView *cyclingLevelPicker;
    NSMutableArray *arrayCyclingLevel;
}

@synthesize delegate = _delegate; 
@synthesize managedObjectContext = _managedObjectContext; 
@synthesize user = _user;
@synthesize age = _age;
@synthesize email = _email; 
@synthesize gender = _gender; 
@synthesize homeZIP = _homeZIP;
@synthesize workZIP = _workZIP;
@synthesize schoolZIP = _schoolZIP;
@synthesize cyclingFreq = _cyclingFreq;
@synthesize entersurveyswitch = _entersurveyswitch;
@synthesize owncarswitch = _owncarswitch;
@synthesize liveoncampusswitch = _liveoncampusswitch;
@synthesize uvaClassification = _uvaClassification;
@synthesize name = _name;
@synthesize uvaAffiliated = _uvaAffiliated;
@synthesize cyclingLevel = _cyclingLevel;


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}


- (id)init
{
	NSLog(@"INIT");
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}


- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		NSLog(@"PersonalInfoViewController::initWithManagedObjectContext");
		self.managedObjectContext = context;
    }
    return self;
}

/*
- (void)initTripManager:(TripManager*)manager
{
	self.managedObjectContext = manager.managedObjectContext;
}
*/

- (UITextField*)setupTextFieldAlpha
{
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textAlignment = UITextAlignmentRight;
	textField.placeholder = @"";
	textField.keyboardType = UIKeyboardTypeDefault;
	textField.returnKeyType = UIReturnKeyDone;
	textField.delegate = self;
	return textField;
}

- (UITextField*)setupTextFieldAlphaPickerUVAClassification
{
    
    uvaClassificationPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    uvaClassificationPicker.delegate = self;
    uvaClassificationPicker.dataSource = self;
    [uvaClassificationPicker setShowsSelectionIndicator:YES];

    
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textAlignment = UITextAlignmentRight;
	textField.placeholder = @"";
    textField.inputView = uvaClassificationPicker;
//    textField.delegate = self;
    
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleBordered target:self
                                                                   action:@selector(uvaClassificationPickerDoneClicked:)];
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    
    // Plug the keyboardDoneButtonView into the text field...
    textField.inputAccessoryView = keyboardDoneButtonView;  
    

    
    
	return textField;
}

- (IBAction) uvaClassificationPickerDoneClicked:(id) sender
{
    [self.uvaClassification resignFirstResponder];
    
}

- (UITextField*)setupTextFieldAlphaPickerCyclingLevel
{
    
    cyclingLevelPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    cyclingLevelPicker.delegate = self;
    cyclingLevelPicker.dataSource = self;
    [cyclingLevelPicker setShowsSelectionIndicator:YES];
    
    
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textAlignment = UITextAlignmentRight;
	textField.placeholder = @"";
    textField.inputView = cyclingLevelPicker;
    //    textField.delegate = self;
    
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleBordered target:self
                                                                  action:@selector(cyclingLevelPickerDoneClicked:)];
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    
    // Plug the keyboardDoneButtonView into the text field...
    textField.inputAccessoryView = keyboardDoneButtonView;  
    
	return textField;
}

- (IBAction) cyclingLevelPickerDoneClicked:(id) sender
{
    [self.cyclingLevel resignFirstResponder];
    
}

- (UITextField*)setupTextFieldEmail
{
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone,
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textAlignment = UITextAlignmentRight;
	textField.placeholder = @"";
	textField.keyboardType = UIKeyboardTypeEmailAddress;
	textField.returnKeyType = UIReturnKeyDone;
	textField.delegate = self;
	return textField;
}


- (UITextField*)setupTextFieldNumeric
{
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textAlignment = UITextAlignmentRight;
	textField.placeholder = @"12345";
	textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	textField.returnKeyType = UIReturnKeyDone;
	textField.delegate = self;
	return textField;
}


- (UISegmentedControl*)createYesNoSwitch
{
	CGRect frame = CGRectMake( 190, 7, 100, 29 );
    UISegmentedControl *yesnoswitch = [[UISegmentedControl alloc] initWithFrame:frame];
    [yesnoswitch insertSegmentWithTitle:@"Yes" atIndex:0 animated:FALSE];
    [yesnoswitch insertSegmentWithTitle:@"No" atIndex:1 animated:FALSE];
    yesnoswitch.selectedSegmentIndex = UISegmentedControlNoSegment;
    
	return yesnoswitch;
}


- (User *)createUser
{
	// Create and configure a new instance of the User entity
	User *noob = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"createUser error %@, %@", error, [error localizedDescription]);
	}
	
	return noob;
}




- (void)viewDidLoad
{
    [super viewDidLoad];
    
    arrayUVAClassifications = [[NSMutableArray alloc] init];
    /*[arrayUVAClassifications addObject:@" Staff "];
    [arrayUVAClassifications addObject:@" Faculty "];
    [arrayUVAClassifications addObject:@" Freshman "];
    [arrayUVAClassifications addObject:@" Junior "];
    [arrayUVAClassifications addObject:@" Senior "];
    [arrayUVAClassifications addObject:@" Graduate Student "];
    [arrayUVAClassifications addObject:@" Postdoc "];
    */
    [arrayUVAClassifications addObject:@" Staff "];
    [arrayUVAClassifications addObject:@" Faculty "];
    [arrayUVAClassifications addObject:@" Undergraduate Student "];
    [arrayUVAClassifications addObject:@" Graduate Student "];
    [arrayUVAClassifications addObject:@" Postdoc "];
    
     
    arrayCyclingLevel = [[NSMutableArray alloc] init];
    [arrayCyclingLevel addObject:@" Beginner "];
    [arrayCyclingLevel addObject:@" Intermediate "];
    [arrayCyclingLevel addObject:@" Advanced "];
    
    
	// Set the title.
	// self.title = @"Personal Info";
	
	// initialize text fields
//	self.age		= [self initTextFieldNumeric];
	self.email		= [self setupTextFieldEmail];
//	self.gender		= [self initTextFieldAlpha];
//	self.homeZIP	= [self initTextFieldNumeric];
//	self.workZIP	= [self initTextFieldNumeric];
//	self.schoolZIP	= [self initTextFieldNumeric];
    self.entersurveyswitch	= [self createYesNoSwitch];
//    self.owncarswitch	= [self createYesNoSwitch];
//    self.liveoncampusswitch	= [self createYesNoSwitch];
    self.uvaClassification = [self setupTextFieldAlphaPickerUVAClassification];
    self.name = [self setupTextFieldAlpha];
    
    //New
    self.uvaAffiliated = [self createYesNoSwitch];
    self.cyclingLevel = [self setupTextFieldAlphaPickerCyclingLevel];
    
    

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

	// Set up the buttons.
	UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																		  target:self action:@selector(done)];
	done.enabled = YES;
	self.navigationItem.rightBarButtonItem = done;
	
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
		// initialize text fields to saved personal info
//		age.text		= user.age;
		self.email.text		= self.user.email;
//        NSLog(@"is this the problem");
//		gender.text		= user.gender;
//		homeZIP.text	= user.homeZIP;
//		workZIP.text	= user.workZIP;
//		schoolZIP.text	= user.schoolZIP;
		
        //Set UVA classification
        self.uvaClassification.text = self.user.uvaClassification;
    
        //Set cycling level
        self.cyclingLevel.text = self.user.cyclingLevel;
    
        //Set UVA affilliation
        if([self.user.uvaAffiliated isEqualToString:@"No"]) {
            [self.uvaAffiliated setSelectedSegmentIndex:1];
        } else if ([self.user.uvaAffiliated isEqualToString:@"Yes"]) {
            [self.uvaAffiliated setSelectedSegmentIndex:0];
        } else {
            self.uvaAffiliated.selectedSegmentIndex = UISegmentedControlNoSegment;
        }

        
        self.name.text = self.user.name;
        
  /*      if ([self.user.ownacar isEqualToString:@"No"]) {
            [self.owncarswitch setSelectedSegmentIndex:1];
        }
        else if ([self.user.ownacar isEqualToString:@"Yes"]) {
            [self.owncarswitch setSelectedSegmentIndex:0];
        } else {
            self.owncarswitch.selectedSegmentIndex = UISegmentedControlNoSegment;
        }*/
        
        /*if ([self.user.liveoncampus isEqualToString:@"No"])
            [self.liveoncampusswitch setSelectedSegmentIndex:1];
        else if ([self.user.liveoncampus isEqualToString:@"Yes"])
            [self.liveoncampusswitch setSelectedSegmentIndex:0];
        else
            self.liveoncampusswitch.selectedSegmentIndex = UISegmentedControlNoSegment;
        */
         
        if ([self.user.enterdrawing isEqualToString:@"No"])
            [self.entersurveyswitch setSelectedSegmentIndex:1];
        else        if ([self.user.enterdrawing isEqualToString:@"Yes"])
            [self.entersurveyswitch setSelectedSegmentIndex:0];
        else
            self.entersurveyswitch.selectedSegmentIndex = UISegmentedControlNoSegment;
        
        
        
//		// init cycling frequency
//		NSLog(@"init cycling freq: %d", [user.cyclingFreq intValue]);
//		cyclingFreq		= [NSNumber numberWithInt:[user.cyclingFreq intValue]];
//		
//		if ( !([user.cyclingFreq intValue] > kMaxCyclingFreq) )
//			[self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:[user.cyclingFreq integerValue] 
//																					  inSection:2]];
	}
	else
		NSLog(@"init FAIL");
	
}


#pragma mark UITextFieldDelegate methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //NSLog(@"numberOfComponentsInPickerView: %@",pickerView);
    //NSLog(@"uvaClassification: %@", uvaClassificationPicker);
    //NSLog(@"cyclingLevel: %@", cyclingLevelPicker);
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView == uvaClassificationPicker) {
        return [arrayUVAClassifications count];
    } else {
        return [arrayCyclingLevel count];
    }
    //return [arrayUVAClassifications count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(pickerView == uvaClassificationPicker) {
        self.uvaClassification.text = (NSString *)[arrayUVAClassifications objectAtIndex:row];
        return [arrayUVAClassifications objectAtIndex:row];
    } else {
        self.cyclingLevel.text = (NSString *)[arrayCyclingLevel objectAtIndex:row];
        return [arrayCyclingLevel objectAtIndex:row];
    }
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(pickerView == uvaClassificationPicker) {
        self.uvaClassification.text = (NSString *)[arrayUVAClassifications objectAtIndex:row];
    } else {
        self.cyclingLevel.text = (NSString *)[arrayCyclingLevel objectAtIndex:row];
    }
}




// the user pressed the "Done" button, so dismiss the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSLog(@"textFieldShouldReturn");
	[textField resignFirstResponder];
	return YES;
}


// save the new value for this textField
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSLog(@"textFieldDidEndEditing");
	
	// save value
	if ( self.user != nil )
	{
		if ( textField == self.age )
		{
			NSLog(@"saving age: %@", self.age.text);
//			[user setAge:age.text];
		}
		if ( textField == self.email )
		{
			NSLog(@"saving email: %@", self.email.text);
			[self.user setEmail:self.email.text];
		}
		if ( textField == self.gender )
		{
			NSLog(@"saving gender: %@", self.gender.text);
//			[user setGender:gender.text];
		}
		if ( textField == self.homeZIP )
		{
			NSLog(@"saving homeZIP: %@", self.homeZIP.text);
//			[user setHomeZIP:homeZIP.text];
		}
		if ( textField == self.schoolZIP )
		{
			NSLog(@"saving schoolZIP: %@", self.schoolZIP.text);
//			[user setSchoolZIP:schoolZIP.text];
		}
		if ( textField == self.workZIP )
		{
			NSLog(@"saving workZIP: %@", self.workZIP.text);
//			[user setWorkZIP:workZIP.text];
		}

        if ( textField == self.uvaClassification )
		{
			NSLog(@"saving uva classification: %@", self.uvaClassification.text);
			[self.user setUvaClassification:self.uvaClassification.text];
		}
        
        if ( textField == self.name )
		{
			NSLog(@"saving name: %@", self.name.text);
			[self.user setName:self.name.text];
		}
        
        if (textField == self.cyclingLevel)
        {
            NSLog(@"saving cycling level: %@", self.cyclingLevel.text);
            [self.user setCyclingLevel:self.cyclingLevel.text];
        }
        
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"PersonalInfo save textField error %@, %@", error, [error localizedDescription]);
		}
	}
}


- (void)done
{
    if (self.entersurveyswitch.selectedSegmentIndex == UISegmentedControlNoSegment ||
        /*self.owncarswitch.selectedSegmentIndex == UISegmentedControlNoSegment ||*/
        /*self.liveoncampusswitch.selectedSegmentIndex == UISegmentedControlNoSegment ||*/
        /*[self.uvaClassification.text isEqualToString:@""] ||*/
        self.cyclingLevel.text == nil ||
        self.uvaAffiliated.selectedSegmentIndex == UISegmentedControlNoSegment) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@":(" message:@"Please note mandatory requirements!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    // if UVA affilliated, enter classification
    if(self.uvaAffiliated.selectedSegmentIndex == 0 && (self.uvaClassification.text == nil)) {
        UIAlertView *alert = [[UIAlertView alloc]      initWithTitle:@":(" 
                                                             message:@"Please enter UVA classification!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    
    // if enter drawing, enter name and email
    if (self.entersurveyswitch.selectedSegmentIndex == 0 && ((self.email.text == nil) || (self.name.text == nil)) /*([self.email.text isEqualToString:@""] || [self.name.text isEqualToString:@""])*/)
    {
        UIAlertView *alert = [[UIAlertView alloc]      initWithTitle:@":(" 
                                                       message:@"Please note mandatory requirements!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
        
    }
    
    UIAlertView *saveDoneAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Personal information saved!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [saveDoneAlert show];    
    
    [self.tabBarController.tabBar setUserInteractionEnabled:TRUE];
    [self.user setHasenteredvalidinfo:@"Yes"];
    
    
	if ( self.user != nil )
	{
		NSLog(@"saving age: %@", self.age.text);
		[self.user setAge:self.age.text];

		NSLog(@"saving email: %@", self.email.text);
		[self.user setEmail:self.email.text];

		NSLog(@"saving gender: %@", self.gender.text);
		[self.user setGender:self.gender.text];

		NSLog(@"saving homeZIP: %@", self.homeZIP.text);
		[self.user setHomeZIP:self.homeZIP.text];

		NSLog(@"saving schoolZIP: %@", self.schoolZIP.text);
		[self.user setSchoolZIP:self.schoolZIP.text];

		NSLog(@"saving workZIP: %@", self.workZIP.text);
		[self.user setWorkZIP:self.workZIP.text];
		
		NSLog(@"saving cycling freq: %d", [self.cyclingFreq intValue]);
		[self.user setCyclingFreq:self.cyclingFreq];

        NSLog(@"saving enterdrawing");
        [self.user setEnterdrawing:[self.entersurveyswitch titleForSegmentAtIndex:[self.entersurveyswitch selectedSegmentIndex]]];

        NSLog(@"saving ownacar");
        [self.user setOwnacar:[self.owncarswitch titleForSegmentAtIndex:[self.owncarswitch selectedSegmentIndex]]];
        
        NSLog(@"saving liveoncampus");
        [self.user setLiveoncampus:[self.liveoncampusswitch titleForSegmentAtIndex:[self.liveoncampusswitch selectedSegmentIndex]]];
        
        NSLog(@"saving UVA classification");
        [self.user setUvaClassification:self.uvaClassification.text];

        NSLog(@"saving name");
        [self.user setName:self.name.text];
        
        NSLog(@"saving cycling level");
        [self.user setCyclingLevel:self.cyclingLevel.text];
        
        NSLog(@"saving UVA affiliation");
        [self.user setUvaAffiliated:[self.uvaAffiliated titleForSegmentAtIndex:[self.uvaAffiliated selectedSegmentIndex]]];

        
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"PersonalInfo save cycling freq error %@, %@", error, [error localizedDescription]);
		}
        [saveDoneAlert dismissWithClickedButtonIndex:0 animated:YES];
	}
	else
		NSLog(@"ERROR can't save personal info for nil user");
	
	// update UI
	// TODO: test for at least one set value
	[self.delegate setSaved:YES];
	
	[self.navigationController popViewControllerAnimated:YES];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
		default:
			return @"Thank you for using CVille Bike mApp! Please enter your user details here. Fields marked * are mandatory. You cannot select other tabs until valid info is entered.";
			break;
		case 1:
			return @"Information for the drawing:\nPrizes will be awarded to randomly chosen participants. If you wish to enter the raffle, name and phone/email is MANDATORY";
			break;
		//case 2:
		//	return @"Your cycling frequency";
		//	break;
	}
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch ( section )
	{
		case 0:
			return 3;
			break;
		case 1:
			return 3;
			break;
		//case 2:
		//	return 4;
		//	break;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // Set up the cell...
	UITableViewCell *cell = nil;
	
	// outer switch statement identifies section
	switch ([indexPath indexAtPosition:0])
	{
		case 0:
		{
			static NSString *CellIdentifier = @"CellTextField";
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			}

			// inner switch statement identifies row
			switch ([indexPath indexAtPosition:1])
			{
                case 0:
                    cell.textLabel.text = @"Cycling self-rating*";
                    [cell.contentView addSubview:self.cyclingLevel];
                    break;
                case 1:
                    cell.textLabel.text = @"Affiliated with UVA?*";
                    [cell.contentView addSubview:self.uvaAffiliated];
                    break;
                case 2:
					cell.textLabel.text = @"UVA Classification";
					[cell.contentView addSubview:self.uvaClassification];
					break;
				/*case 0:
					cell.textLabel.text = @"UVA Classification*";
					[cell.contentView addSubview:self.uvaClassification];
					break;
				case 1:
					cell.textLabel.text = @"Live on campus?*";
					[cell.contentView addSubview:self.liveoncampusswitch];
					break;
				case 2:
					cell.textLabel.text = @"Own a car?*";
					[cell.contentView addSubview:self.owncarswitch];
					break;
                case 3:
                    cell.textLabel.text = @"Affiliated with UVA?*";
                    [cell.contentView addSubview:self.uvaAffiliated];
                    break;
                case 4:
                    cell.textLabel.text = @"Cycling self-rating*";
                    [cell.contentView addSubview:self.cyclingLevel];
                    break;*/
			}
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
			break;
	
		case 1:
		{
			static NSString *CellIdentifier = @"CellTextField";
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			}

			switch ([indexPath indexAtPosition:1])
			{
                case 0:
					cell.textLabel.text = @"Enter Drawing?*";
					[cell.contentView addSubview:self.entersurveyswitch];
					break;
                case 1:
					cell.textLabel.text = @"Name";
					[cell.contentView addSubview:self.name];
					break;
                case 2:
                    cell.textLabel.text = @"Email/Phone";
					[cell.contentView addSubview:self.email];
					break;
			}
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
			break;
			
		/*case 2:
		{
			static NSString *CellIdentifier = @"CellCheckmark";
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			}
			
			switch ([indexPath indexAtPosition:1])
			{
				case 0:
					cell.textLabel.text = @"Less than once a month";
					break;
				case 1:
					cell.textLabel.text = @"Several times per month";
					break;
				case 2:
					cell.textLabel.text = @"Several times per week";
					break;
				case 3:
					cell.textLabel.text = @"Daily";
					break;
			}
			//
			//if ( user != nil )
			//	if ( [user.cyclingFreq intValue] == [indexPath indexAtPosition:1] )
			//		cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
			if ( [self.cyclingFreq intValue] == [indexPath indexAtPosition:1] )
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
				cell.accessoryType = UITableViewCellAccessoryNone;
		}*/
	}
	
	// debug
	//NSLog(@"%@", [cell subviews]);
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];

    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];

	// outer switch statement identifies section
	switch ([indexPath indexAtPosition:0])
	{
		case 0:
		{
			// inner switch statement identifies row
			switch ([indexPath indexAtPosition:1])
			{
				case 0:
					break;
				case 1:
					break;
			}
			break;
		}
			
		case 1:
		{
			switch ([indexPath indexAtPosition:1])
			{
				case 0:
					break;
				case 1:
					break;
			}
			break;
		}
		
		case 2:
		{
			// cycling frequency
			// remove all checkmarks
			UITableViewCell *cell;
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
			cell.accessoryType = UITableViewCellAccessoryNone;
			
			// apply checkmark to selected cell
			cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.accessoryType = UITableViewCellAccessoryCheckmark;

			// store cycling freq
			self.cyclingFreq = [NSNumber numberWithInt:[indexPath indexAtPosition:1]];
			NSLog(@"setting instance variable cycling freq: %d", [self.cyclingFreq intValue]);
		}
	}
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/




@end

