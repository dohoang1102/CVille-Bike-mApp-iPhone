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
//  RecordTripViewController.m
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/10/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import "constants.h"
#import "MapViewController.h"
#import "PersonalInfoViewController.h"
#import "PickerViewController.h"
#import "RecordTripViewController.h"
#import "ReminderManager.h"
#import "TripManager.h"
#import "Trip.h"
#import "User.h"
#import "Coord.h"



@implementation RecordTripViewController

//@synthesize parentView;
@synthesize locationManager = _locationManager;
@synthesize tripManager = _tripManager;
@synthesize reminderManager = _reminderManager;
@synthesize startButton = _startButton;
@synthesize saveButton = _saveButton;
@synthesize lockButton = _lockButton;
@synthesize slider = _slider;
@synthesize sliderView = _sliderView;
@synthesize opacityMask = _opacityMask;
@synthesize timer, timeCounter, distCounter, speedCounter;
@synthesize locked = _locked;
@synthesize recording = _recording;
@synthesize shouldUpdateCounter = _shouldUpdateCounter;
@synthesize userInfoSaved = _userInfoSaved;
@synthesize lasttriplastpoint = _lasttriplastpoint;
@synthesize mapView = _mapView;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize didUpdateUserLocation = _didUpdateUserLocation;
@synthesize displayTrip = _displayTrip;


#pragma mark CLLocationManagerDelegate methods

- (CLLocationManager *)getLocationManager {
	
    if (self.locationManager != nil) {
        return self.locationManager;
    }
	
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.delegate = self;
	
    return self.locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	// NSLog(@"location update: %@", [newLocation description]);
	//CLLocationDistance deltaDistance = [newLocation getDistanceFrom:oldLocation];
	CLLocationDistance deltaDistance = [newLocation distanceFromLocation:oldLocation]; 
    //NSLog(@"deltaDistance = %f", deltaDistance);
	
	if ( !self.didUpdateUserLocation )
	{
		NSLog(@"zooming to current user location");
		//MKCoordinateRegion region = { mapView.userLocation.location.coordinate, { 0.0078, 0.0068 } };
		MKCoordinateRegion region = { newLocation.coordinate, { 0.0078, 0.0068 } };
		[self.mapView setRegion:region animated:YES];

		self.didUpdateUserLocation = YES;
	}
	
	// only update map if deltaDistance is at least some epsilon 
	else if ( deltaDistance > 1.0 )
	{
		//NSLog(@"center map to current user location");
		[self.mapView setCenterCoordinate:newLocation.coordinate animated:YES];
	}

	if ( self.recording )
	{
		// add to CoreData store
		CLLocationDistance distance = [self.tripManager addCoord:newLocation];
		self.distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance / 1609.344];
	}
	
	// 	double mph = ( [trip.distance doubleValue] / 1609.344 ) / ( [trip.duration doubleValue] / 3600. );
	if ( newLocation.speed >= 0. )
		speedCounter.text = [NSString stringWithFormat:@"%.1f mph", newLocation.speed * 3600 / 1609.344];
	else
		speedCounter.text = @"0.0 mph";
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
	NSLog(@"locationManager didFailWithError: %@", error );
}


#pragma mark MKMapViewDelegate methods

- (void)initTripManager:(TripManager*)manager
{
	//manager.activityDelegate = self;
	manager.alertDelegate	= self;
	manager.dirty			= YES;
	self.tripManager		= manager;
}

- (BOOL)hasUserInfoBeenSaved
{
	BOOL					response = NO;
	NSManagedObjectContext	*context = self.tripManager.managedObjectContext;
	NSFetchRequest			*request = [[NSFetchRequest alloc] init];
	NSEntityDescription		*entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [context countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	if ( count )
	{	
		NSArray *fetchResults = [context executeFetchRequest:request error:&error];
		if ( fetchResults != nil )
		{
			User *user = (User*)[fetchResults objectAtIndex:0];
			if (user			!= nil &&
				(user.age		!= nil ||
				 user.gender	!= nil ||
				 user.email		!= nil ||
				 user.homeZIP	!= nil ||
				 user.workZIP	!= nil ||
				 user.schoolZIP	!= nil ||
				 ([user.cyclingFreq intValue] < 4 )))
			{
				NSLog(@"found saved user info");
				self.userInfoSaved = YES;
				response = YES;
			}
			else
				NSLog(@"no saved user info");
		}
		else
		{
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"PersonalInfo viewDidLoad fetch error %@, %@", error, [error localizedDescription]);
		}
	}
	else
		NSLog(@"no saved user");
	
	return response;
}

- (void)hasRecordingBeenInterrupted
{
	if ( [self.tripManager countUnSavedTrips] )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInterruptedTitle
														message:kInterruptedMessage
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Continue", nil];
		alert.tag = 101;
		[alert show];
	}
	else
		NSLog(@"no unsaved trips found");
}

- (void)infoAction:(id)sender
{
	if ( !self.recording )
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: kInfoURL]];
}


- (void)viewDidLoad
{
	NSLog(@"RecordTripViewController viewDidLoad");
    [super viewDidLoad];
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

	// init map region to San Francisco
	MKCoordinateRegion region = { { 37.7620, -122.4350 }, { 0.10825, 0.10825 } };
	[self.mapView setRegion:region animated:NO];
	[self createOpacityMask];
	
	self.locked = NO;
	self.recording = NO;
	self.shouldUpdateCounter = NO;
    //self.ispurposepending = NO;
	
	// Start the location manager.
	[[self getLocationManager] startUpdatingLocation];
	
	// Start receiving updates as to battery level
	UIDevice *device = [UIDevice currentDevice];
	device.batteryMonitoringEnabled = YES;
	switch (device.batteryState)
	{
		case UIDeviceBatteryStateUnknown:
			NSLog(@"battery state = UIDeviceBatteryStateUnknown");
			break;
		case UIDeviceBatteryStateUnplugged:
			NSLog(@"battery state = UIDeviceBatteryStateUnplugged");
			break;
		case UIDeviceBatteryStateCharging:
			NSLog(@"battery state = UIDeviceBatteryStateCharging");
			break;
		case UIDeviceBatteryStateFull:
			NSLog(@"battery state = UIDeviceBatteryStateFull");
			break;
	}

	NSLog(@"battery level = %f%%", device.batteryLevel * 100.0 );

	// check if any user data has already been saved and pre-select personal info cell accordingly
	if ( [self hasUserInfoBeenSaved] )
		[self setSaved:YES];
	
	// check for any unsaved trips / interrupted recordings
	[self hasRecordingBeenInterrupted];
}

- (void)resetPurpose
{
}


- (void)resetTimer
{	
	// invalidate timer
	if ( timer )
	{
		[timer invalidate];
		//[timer release];
		timer = nil;
	}
}


- (void)resetRecordingInProgress
{
	// reset button states
	self.recording = NO;
	self.startButton.enabled = YES;
	self.saveButton.enabled = NO;
	self.lockButton.enabled = NO;
	
	// reset trip, reminder managers
	NSManagedObjectContext *context = self.tripManager.managedObjectContext;
	[self initTripManager:[[TripManager alloc] initWithManagedObjectContext:context]];
	self.tripManager.dirty = YES;
	
	if ( self.reminderManager )
	{
		self.reminderManager = nil;
	}
	
	[self resetCounter];
	[self resetPurpose];
	[self resetTimer];
}


#pragma mark UIActionSheet delegate methods


// NOTE: implement didDismissWithButtonIndex to process after sheet has been dismissed
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSLog(@"actionSheet clickedButtonAtIndex %d", buttonIndex);
	switch ( buttonIndex )
	{
		case 0: // push Trip Purpose picker
			// stop recording new GPS data points
		{
			self.recording = NO;
			
			// update UI
			self.saveButton.enabled = NO;
			[self resetTimer];
			
			// Trip Purpose
			NSLog(@"Initiating trip purpose picker");
            [self performSegueWithIdentifier:@"recordToTripPurpose" sender:self];
            
			//PickerViewController *pickerViewController = [[PickerViewController alloc]
														  //initWithPurpose:[tripManager getPurposeIndex]];
			//											  initWithNibName:@"TripPurposePicker" bundle:nil];
			//[pickerViewController setVcdelegate:self];
			//[[self navigationController] pushViewController:pickerViewController animated:YES];
			//[self.navigationController presentModalViewController:pickerViewController animated:YES];
            
            
		}
			break;
			
		case kActionSheetButtonCancel:
		default:
			NSLog(@"Cancel");
			// re-enable counter updates
			self.shouldUpdateCounter = YES;
			break;
	}
}


// called if the system cancels the action sheet (e.g. homescreen button has been pressed)
- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	NSLog(@"actionSheetCancel");
}


#pragma mark UIAlertViewDelegate methods


// NOTE: method called upon closing save error / success alert
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		//NOTE: This case is called when an interrupted recording is found
        //This occurs when the app completely exits while recording.
        case 101:
		{
			NSLog(@"recording interrupted didDismissWithButtonIndex: %d", buttonIndex);
			switch (buttonIndex) {
				case 0:
					// new trip => do nothing (user clicked cancel in continue dialog)
					break;
				case 1:
				default:
					// continue => load most recent unsaved trip (user clicked continue)
					[self.tripManager loadMostRecetUnSavedTrip];
					
					// update UI to reflect trip once loading has completed
					[self setCounterTimeSince:self.tripManager.trip.start
									 distance:[self.tripManager getDistanceEstimate]];

					self.startButton.enabled = YES;					
					break;
			}
		}
        break;
		default:
		{
			NSLog(@"saving didDismissWithButtonIndex: %d", buttonIndex);
			
            //  show mapview for the saved trip
            NSLog(@"Performing recordToMapView segue...");
            // keep a pointer to our trip to pass to map view below
            //Trip *trip = tripManager.trip;
            self.displayTrip = self.tripManager.trip;
            
            //Reset for a new trip
            [self resetRecordingInProgress];
            
            //Display trip in map view
            [self performSegueWithIdentifier:
             @"recordToMapView"                                                    sender:self];
            //MapViewController *mvc = [[MapViewController alloc] initWithTrip:trip];
            //[[self navigationController] pushViewController:mvc animated:YES];
		}
			break;
	}
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"recordToTripPurpose"]){
        //NSLog(@"in RecordTripViewController:prepareForSegue: preparing to segue to trip purpose picker.");
        [[segue destinationViewController] setVcdelegate:self];
    } else if([[segue identifier] isEqualToString:@"recordToMapView"]){
        //NSLog(@"in RecordTripViewController:prepareForSegue: preparing to segue to map view.");
        [[segue destinationViewController] setTrip:self.displayTrip];
    }
}

// handle save button action
- (IBAction)save:(UIButton *)sender
{
	NSLog(@"save button action fired.");
    //  do the discrepancy checking here.
    int numpoints = [self.tripManager.trip.coords count];
    NSLog(@"trip has %d points", numpoints);
    
    // Trip Purpose
    NSLog(@"Switching to trip purpose picker...");
    [self performSegueWithIdentifier:@"recordToTripPurpose" sender:self];
}


- (NSDictionary *)newTripTimerUserInfo
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"StartDate",
			self.tripManager, @"TripManager", nil ];
}


- (NSDictionary *)continueTripTimerUserInfo
{
	if ( self.tripManager.trip && self.tripManager.trip.start )
		return [NSDictionary dictionaryWithObjectsAndKeys:self.tripManager.trip.start, @"StartDate",
				self.tripManager, @"TripManager", nil ];
	else {
		NSLog(@"WARNING: tried to continue trip timer but failed to get trip.start date");
		return [self newTripTimerUserInfo];
	}
	
}


// handle start button action
- (IBAction)start:(UIButton *)sender
{
	NSLog(@"start button action fired...");
	
	// start the timer if needed
	if ( timer == nil )
	{
		// check if we're continuing a trip
		if ( self.tripManager.trip && [self.tripManager.trip.coords count] )
		{
			timer = [NSTimer scheduledTimerWithTimeInterval:kCounterTimeInterval
													 target:self selector:@selector(updateCounter:)
												   userInfo:[self continueTripTimerUserInfo] repeats:YES];
            NSLog(@"Starting trip as a continuation of a previous trip...");
		}
		
		// or starting a new recording
		else {
			[self resetCounter];
			timer = [NSTimer scheduledTimerWithTimeInterval:kCounterTimeInterval
													 target:self selector:@selector(updateCounter:)
												   userInfo:[self newTripTimerUserInfo] repeats:YES];
            NSLog(@"Starting trip as a new trip...");
        }
	}

	// init reminder manager
	self.reminderManager = [[ReminderManager alloc] initWithRecordingInProgressDelegate:self];
	
	// disable start button
	self.startButton.enabled = NO;
	
	// enable save button
	self.saveButton.enabled = YES;
	self.saveButton.hidden = NO;
	
	// set recording flag so future location updates will be added as coords
	self.recording = YES;
	
	// update "Touch start to begin text"
	//[self.tableView reloadData];
	
	/*
	CGRect sectionRect = [self.tableView rectForSection:0];
	[self.tableView setNeedsDisplayInRect:sectionRect];
	[self.view setNeedsDisplayInRect:sectionRect];
	*/
	
	// set flag to start updating counter UI
	self.shouldUpdateCounter = YES;
	
	// lock the device
	[self lockDevice];
}


- (void)createCounter
{
	// create counter window
	/*
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LargeCounter.png"]];
	//CGRect frame = CGRectMake( 155, 181, 156, 89 );
	CGRect frame = CGRectMake( 155, 181, 156, 107 );
	imageView.frame = frame;
	[self.view addSubview:imageView];
	*/
	
	// create time counter text
	if ( timeCounter == nil )
	{
		/*
		frame = CGRectMake(	165, 179, 135, 50 );
		self.timeCounter = [[[UILabel alloc] initWithFrame:frame] autorelease];
		self.timeCounter.backgroundColor	= [UIColor clearColor];
		self.timeCounter.font				= [UIFont boldSystemFontOfSize:kCounterFontSize];
		self.timeCounter.textAlignment		= UITextAlignmentRight;
		self.timeCounter.textColor			= [UIColor darkGrayColor];
		[self.view addSubview:self.timeCounter];
		*/
		
		// time elapsed
		/*
		frame = CGRectMake(	165, 213, 135, 20 );
		UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
		label.backgroundColor	= [UIColor clearColor];
		label.font				= [UIFont systemFontOfSize:12.0];
		label.text				= @"time elapsed";
		label.textAlignment		= UITextAlignmentRight;
		label.textColor			= [UIColor grayColor];
		[self.view addSubview:label];
		 */
	}
	
	// create GPS counter (e.g. # coords) text
	if ( distCounter == nil )
	{
		/*
		frame = CGRectMake(	165, 226, 135, 50 );
		//frame = CGRectMake(	165, 255, 135, 20 );
		self.distCounter = [[[UILabel alloc] initWithFrame:frame] autorelease];
		self.distCounter.font = [UIFont boldSystemFontOfSize:kCounterFontSize];
		self.distCounter.textAlignment = UITextAlignmentRight;
		self.distCounter.textColor = [UIColor darkGrayColor];
		self.distCounter.backgroundColor = [UIColor clearColor];
		[self.view addSubview:self.distCounter];
		*/
		// distance
		/*
		frame = CGRectMake(	165, 260, 135, 20 );
		//frame = CGRectMake(	165, 218, 135, 50 );
		UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
		label.backgroundColor	= [UIColor clearColor];
		label.font				= [UIFont systemFontOfSize:12.0];
		label.text				= @"est. distance";
		label.textAlignment		= UITextAlignmentRight;
		label.textColor			= [UIColor grayColor];
		[self.view addSubview:label];
		 */
	}
	
	[self resetCounter];
}


- (void)resetCounter
{
    NSLog(@"resetting counters...");
	if ( timeCounter != nil )
		timeCounter.text = @"00:00:00";
	
	if ( distCounter != nil )
		distCounter.text = @"0 mi";
}


- (void)setCounterTimeSince:(NSDate *)startDate distance:(CLLocationDistance)distance
{
	if ( timeCounter != nil )
	{
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
		
		static NSDateFormatter *inputFormatter = nil;
		if ( inputFormatter == nil )
			inputFormatter = [[NSDateFormatter alloc] init];
		
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:fauxDate];
		
		timeCounter.text = [inputFormatter stringFromDate:outputDate];
	}
	
	if ( distCounter != nil )
		distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance / 1609.344];
;
}

- (void)updateCounter:(NSTimer *)theTimer
{
	//NSLog(@"updateCounter");
	if ( self.shouldUpdateCounter )
	{
		NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];

		static NSDateFormatter *inputFormatter = nil;
		if ( inputFormatter == nil )
			inputFormatter = [[NSDateFormatter alloc] init];
		
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:fauxDate];
		
		//NSLog(@"Timer started on %@", startDate);
		//NSLog(@"Timer started %f seconds ago", interval);
		//NSLog(@"elapsed time: %@", [inputFormatter stringFromDate:outputDate] );
		
		//self.timeCounter.text = [NSString stringWithFormat:@"%.1f sec", interval];
		self.timeCounter.text = [inputFormatter stringFromDate:outputDate];
	}
	/*
	if ( reminderManager )
		[reminderManager updateReminder:theTimer];
	 */
}


- (IBAction)lockAction:(UIButton*)sender
{
	[self lockDevice];
}


- (void)lockDevice
{
	NSLog(@"lockDevice");
	self.locked = YES;
	
	// dim screen
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
	self.opacityMask.hidden = NO;
	self.opacityMask.exclusiveTouch = YES;
	self.opacityMask.multipleTouchEnabled = YES;
	
	//self.tableView.hidden = YES;
	
	self.lockButton.enabled		= NO;
	self.saveButton.enabled		= NO;
	self.startButton.enabled		= NO;
	
	self.mapView.scrollEnabled	= NO;
	self.mapView.zoomEnabled		= NO;
	
	if ( self.slider )
	{
		self.slider.value = 0.0;
		self.slider.hidden = NO;
	}
	else
		NSLog(@"slide == nil");
	
	if ( self.sliderView )
		self.sliderView.hidden = NO;

	// enable reminders
	if ( self.reminderManager )
		[self.reminderManager enableReminders];
}


- (void)unlockDevice
{
	NSLog(@"unlockDevice");
	self.locked = NO;

	// un-dim screen
	//[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
	self.opacityMask.hidden = YES;
	//self.opacityMask.exclusiveTouch = NO;
	
	//self.tableView.hidden = NO;

	self.lockButton.enabled = YES;
	self.saveButton.enabled = YES;
	//startButton.enabled = YES;
	
	self.mapView.scrollEnabled	= YES;
	self.mapView.zoomEnabled		= YES;
	
	if ( self.slider )
		self.slider.hidden = YES;

	if ( self.sliderView )
		self.sliderView.hidden = YES;

	// disable reminders
	if ( self.reminderManager )
		[self.reminderManager disableReminders];
}


- (void)createOpacityMask
{
	self.opacityMask = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OpacityMask80.png"]];
	self.opacityMask.frame = CGRectMake( 0.0, 0.0, 320.0, 480.0 );
	self.opacityMask.hidden = YES;

	//[opacityMask addSubview:[self createSlideToUnlock]];
	//[self createSlideToUnlock:opacityMask];
	
	UIViewController *pvc = self.parentViewController;
	
	[pvc.view addSubview:self.opacityMask];
	[self createSlideToUnlock:pvc.view];

	/*
	if ( parentView )
		[parentView addSubview:opacityMask];
	*/
	
	//[self.view addSubview:opacityMask];
}


- (UISlider *)createSlideToUnlock:(UIView*)view
{
    if (self.slider == nil) 
    {
		// create background "slide to unlock" image
        CGRect frame = CGRectMake( 9.0, 365.0, 302.0, 39.0 );
        //CGRect frame = CGRectMake( 9.0, 372.0, 302.0, 39.0 );
		self.sliderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SlideToUnlock.png"]];
		self.sliderView.frame = frame;
		self.sliderView.hidden = YES;
		[view addSubview:self.sliderView];
		
		// create slider itself slightly larger per the thumb image
		frame = CGRectMake( 7.0, 362.0, 307.0, 46.0 );
		//frame = CGRectMake( 7.0, 369.0, 307.0, 46.0 );
        self.slider = [[UISlider alloc] initWithFrame:frame];
        [self.slider addTarget:self action:@selector(slideToUnlockAction:) forControlEvents:UIControlEventValueChanged];
        
		// in case the parent view draws with a custom color or gradient, use a transparent color
        self.slider.backgroundColor = [UIColor clearColor];	
		
		/*
		 UIImage *stetchLeftTrack = [[UIImage imageNamed:@"SlideToUnlock.png"]
		 stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
		 UIImage *stetchRightTrack = [[UIImage imageNamed:@"yellowslide.png"]
									 stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
		 //[slider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
		 //[slider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
		 */

        //[slider setThumbImage: [UIImage imageNamed:@"slider_ball.png"] forState:UIControlStateNormal];
        [self.slider setThumbImage: [UIImage imageNamed:@"ClearArrowButtonWideDark.png"] forState:UIControlStateNormal];
		//[slider setThumbImage: [UIImage imageNamed:@"whiteButton.png"] forState:UIControlStateNormal];

        self.slider.minimumValue = 0.0;
        self.slider.maximumValue = 100.0;
        self.slider.continuous = NO;
        self.slider.value = 0.0;
		self.slider.hidden = YES;
		[view addSubview:self.slider];
    }

    return self.slider;
}


- (void)slideToUnlockAction:(UISlider *)sender
{
	//NSLog(@"slideToUnlockAction: %f", [sender value]);
	if ( [sender value] < 90.0 )
	{
		[sender setValue:0.0 animated:YES];
		self.locked = YES;
	}
	else
	{
		// unlock the device
		[sender setValue:100.0 animated:YES];
		[self unlockDevice];
	}
}


- (void)viewWillAppear:(BOOL)animated 
{
    // listen for keyboard hide/show notifications so we can properly adjust the table's height
	[super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated 
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)aNotification 
{
	NSLog(@"keyboardWillShow");
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
	NSLog(@"keyboardWillHide");
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setStartButton:nil];
    //self.coords = nil;
    self.locationManager = nil;
    //self.startButton = nil;
}

- (NSString *)updatePurposeWithString:(NSString *)purpose
{
	// update UI
	/*
	 if ( tripPurposeCell != nil )
	 {
	 tripPurposeCell.accessoryType = UITableViewCellAccessoryCheckmark;
	 tripPurposeCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GreenCheckMark3.png"]];
	 tripPurposeCell.detailTextLabel.text = purpose;
	 tripPurposeCell.detailTextLabel.enabled = YES;
	 tripPurposeCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	 tripPurposeCell.detailTextLabel.minimumFontSize = kMinimumFontSize;
	 }
	 */
	
	// only enable start button if we don't already have a pending trip
	if ( timer == nil )
		self.startButton.enabled = YES;
	
	self.startButton.hidden = NO;
	
	return purpose;
}

- (NSString *)updateModeWithString:(NSString *)mode
{
	// update UI
	/*
	 if ( tripPurposeCell != nil )
	 {
	 tripPurposeCell.accessoryType = UITableViewCellAccessoryCheckmark;
	 tripPurposeCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GreenCheckMark3.png"]];
	 tripPurposeCell.detailTextLabel.text = purpose;
	 tripPurposeCell.detailTextLabel.enabled = YES;
	 tripPurposeCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	 tripPurposeCell.detailTextLabel.minimumFontSize = kMinimumFontSize;
	 }
	 */
	
	// only enable start button if we don't already have a pending trip
	if ( timer == nil )
		self.startButton.enabled = YES;
	
	self.startButton.hidden = NO;
	
	return mode;
}


- (NSString *)updatePurposeWithIndex:(unsigned int)index
{
	return [self updatePurposeWithString:[self.tripManager getPurposeString:index]];
}

- (NSString *)updateModeWithIndex:(unsigned int)index
{
	return [self updateModeWithString:[self.tripManager getModeString:index]];
}

#pragma mark UINavigationController

- (void)navigationController:(UINavigationController *)navigationController 
	   willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated
{
	if ( viewController == self )
	{
		//NSLog(@"willShowViewController:self");
		self.title = @"Record New Trip";
	}
	else
	{
		//NSLog(@"willShowViewController:else");
		self.title = @"Back";
		self.tabBarItem.title = @"Record New Trip"; // important to maintain the same tab item title
	}
}


#pragma mark UITabBarControllerDelegate


- (BOOL)tabBarController:(UITabBarController *)tabBarController 
shouldSelectViewController:(UIViewController *)viewController
{
	if ( self.locked )
		NSLog(@"locked: YES");
	if ( self.locked && viewController != self.parentViewController )
	{
		return NO;
	}
	else
		return YES;		
}


#pragma mark PersonalInfoDelegate methods


- (void)setSaved:(BOOL)value
{
	NSLog(@"setSaved");
	// update UI
	/*
	if ( personalInfoCell != nil )
	{
		NSLog(@"Personal Info saved");		
		personalInfoCell.accessoryType = UITableViewCellAccessoryCheckmark;
		personalInfoCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GreenCheckMark3.png"]];
		personalInfoCell.detailTextLabel.text = @"Saved";
		personalInfoCell.detailTextLabel.enabled = YES;
	}
	 */
}


#pragma mark TripPurposeDelegate methods


- (NSString *)setPurpose:(unsigned int)index
{
	NSString *purpose = [self.tripManager setPurpose:index];
	NSLog(@"setPurpose: %@", purpose);

	//[self.navigationController popViewControllerAnimated:YES];
	
	return [self updatePurposeWithString:purpose];
}

- (NSString *)setMode:(unsigned int)index
{
	NSString *mode = [self.tripManager setMode:index];
	NSLog(@"setMode: %@", mode);
    
	//[self.navigationController popViewControllerAnimated:YES];
	
	return [self updateModeWithString:mode];
}

- (NSString *)getModeString:(unsigned int)index
{
	return [self.tripManager getModeString:index];
}

- (NSString *)getPurposeString:(unsigned int)index
{
	return [self.tripManager getPurposeString:index];
}


- (void)didCancelPurpose
{
    //NSLog(@"in RecordTripViewController:didCancelPurpose");
	[self.navigationController dismissModalViewControllerAnimated:YES];
	self.recording = YES;
	self.saveButton.enabled = YES;
	self.shouldUpdateCounter = YES;
}


- (void)didPickPurpose:(NSInteger)index didPickMode:(NSInteger)index1
{
    NSLog(@"in RecordTripViewController:didPickPurpose");
	[self.navigationController dismissModalViewControllerAnimated:YES];
	
	// update UI
	self.recording = NO;	
	self.lockButton.enabled = NO;
	self.saveButton.enabled = NO;
	self.startButton.enabled = YES;
	[self resetTimer];

	[self.tripManager setPurpose:index];
  	[self.tripManager setMode:index1];
    
    [self.tripManager promptForTripNotes];
}


#pragma mark RecordingInProgressDelegate method
- (Trip*)getRecordingInProgress
{
	if ( self.recording )
		return self.tripManager.trip;
	else
		return nil;
}


@end

