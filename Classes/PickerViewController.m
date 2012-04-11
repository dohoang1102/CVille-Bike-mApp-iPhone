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
//	PickerViewController.m
//	CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/28/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import "CustomView.h"
#import "PickerViewController.h"


@implementation PickerViewController

@synthesize customPickerView = _customPickerView;
@synthesize customPickerDataSource = _customPickerDataSource;
@synthesize vcdelegate = _vcdelegate;
@synthesize description = _description;


// return the picker frame based on its size
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	
	// layout at bottom of page
	/*
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
									screenRect.size.height - 84.0 - size.height,
									size.width,
									size.height);
	 */
	
	// layout at top of page
	//CGRect pickerRect = CGRectMake(	0.0, 0.0, size.width, size.height );	
	
	// layout at top of page, leaving room for translucent nav bar
	//CGRect pickerRect = CGRectMake(	0.0, 43.0, size.width, size.height );	
	CGRect pickerRect = CGRectMake(	0.0, 78.0, size.width, size.height );	
	return pickerRect;
}


- (void)createCustomPicker
{
	self.customPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	self.customPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// setup the data source and delegate for this picker
	self.customPickerDataSource = [[CustomPickerDataSource alloc] init];
	self.customPickerDataSource.parent = self;
	self.customPickerView.dataSource = self.customPickerDataSource;
	self.customPickerView.delegate = self.customPickerDataSource;
	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	CGSize pickerSize = [self.customPickerView sizeThatFits:CGSizeZero];
	self.customPickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	self.customPickerView.showsSelectionIndicator = YES;
	
	// add this picker to our view controller, initially hidden
	//customPickerView.hidden = YES;
	[self.view addSubview:self.customPickerView];
}


- (IBAction)cancel:(id)sender
{
	[self.vcdelegate didCancelPurpose];
}


- (IBAction)save:(id)sender
{
	NSInteger row = [self.customPickerView selectedRowInComponent:0];
    NSInteger row1 = [self.customPickerView selectedRowInComponent:1];
	[self.vcdelegate didPickPurpose:row didPickMode:row1];
}

- (id)init {
    //NSLog(@"in PickerViewController:init");
    self = [super init];
    if (self) {
        [self createCustomPicker];
        
        // picker defaults to top-most item => update the description
        [self pickerView:self.customPickerView didSelectRow:0 inComponent:0];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    //NSLog(@"in PickerViewController:initWithCoder");
    if ((self = [super initWithCoder:aDecoder])) {
        
       // [self createCustomPicker];
        
        // picker defaults to top-most item => update the description
        //[self pickerView:customPickerView didSelectRow:0 inComponent:0];
    }
    
    return self;
}

- (void)awakeFromNib {
    //NSLog(@"in awakeFromNib...");
    [self createCustomPicker];
    [self pickerView:self.customPickerView didSelectRow:0 inComponent:0];
}



/*- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	NSLog(@"initWithNibNamed");
	if (self = [super initWithNibName:nibName bundle:nibBundle])
	{
		//NSLog(@"PickerViewController init");		
		[self createCustomPicker];
		
		// picker defaults to top-most item => update the description
		[self pickerView:customPickerView didSelectRow:0 inComponent:0];
	}
	return self;
}*/


- (id)initWithPurpose:(NSInteger)index
{
	if (self = [self init])
	{
		//NSLog(@"PickerViewController initWithPurpose: %d", index);
		
		// update the picker
		[self.customPickerView selectRow:index inComponent:0 animated:YES];
		
		// update the description
		[self pickerView:self.customPickerView didSelectRow:index inComponent:0];
	}
	return self;
}


- (void)viewDidLoad
{		
	[super viewDidLoad];
	
    //NSLog(@"in PickerViewController:viewDidLoad...");
    
	self.title = NSLocalizedString(@"Purpose/Weather", @"");

	//self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	// self.view.backgroundColor = [[UIColor alloc] initWithRed:40. green:42. blue:57. alpha:1. ];

	// Set up the buttons.
	/*
	UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
															  target:self action:@selector(done)];
	done.enabled = YES;
	self.navigationItem.rightBarButtonItem = done;
	 */
	//[self.navigationController setNavigationBarHidden:NO animated:YES];
	
	//description = [[UITextView alloc] initWithFrame:CGRectMake( 18.0, 280.0, 284.0, 130.0 )];
	self.description = [[UITextView alloc] initWithFrame:CGRectMake( 18.0, 314.0, 284.0, 120.0 )];
	self.description.editable = NO;
	self.description.font = [UIFont fontWithName:@"Arial" size:16];
	[self.view addSubview:self.description];
}


// called after the view controller's view is released and set to nil.
// For example, a memory warning which causes the view to be purged. Not invoked as a result of -dealloc.
// So release any properties that are loaded in viewDidLoad or can be recreated lazily.
//
- (void)viewDidUnload
{
	[super viewDidUnload];
	self.customPickerView = nil;
	self.customPickerDataSource = nil;
}




#pragma mark UIPickerViewDelegate


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	//NSLog(@"parent didSelectRow: %d inComponent:%d", row, component);

    if (component != 0)
        return;
    
	switch (row) {
		case 0:
			self.description.text = kDescSchool;
			break;
		case 1:
			self.description.text = kDescCommute;
			break;
		case 2:
			self.description.text = kDescWork;
			break;
		case 3:
			self.description.text = kDescExercise;
			break;
		case 4:
			self.description.text = kDescSocial;
			break;
		case 5:
			self.description.text = kDescShopping;
			break;
		case 6:
			self.description.text = kDescErrand;
			break;
		case 7:
		default:
			self.description.text = kDescOther;
			break;
	}
}


@end

