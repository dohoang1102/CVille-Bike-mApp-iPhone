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
//  TripManager.m
//	CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/22/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import "CJSONSerializer.h"
#import "constants.h"
#import "Coord.h"
#import "SaveRequest.h"
#import "Trip.h"
#import "TripManager.h"
#import "User.h"


// use this epsilon for both real-time and post-processing distance calculations
#define kEpsilonAccuracy		100.0

// use these epsilons for real-time distance calculation only
#define kEpsilonTimeInterval	10.0
#define kEpsilonSpeed			30.0	// meters per sec = 67 mph

#define kSaveProtocolVersion_1	1
#define kSaveProtocolVersion_2	2

//#define kSaveProtocolVersion	kSaveProtocolVersion_1
#define kSaveProtocolVersion	kSaveProtocolVersion_2

@implementation TripManager

@synthesize activityDelegate = _activityDelegate;
@synthesize activityIndicator = _activityIndicator;
@synthesize alertDelegate = _alertDelegate;
@synthesize saving = _saving;
@synthesize tripNotes = _tripNotes;
@synthesize tripNotesText = _tripNotesText;
@synthesize coords = _coords;
@synthesize dirty = _dirty;
@synthesize trip = _trip;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize receivedData = _receivedData;
@synthesize purposeIndex = _purposeIndex;
@synthesize modeIndex = _modeIndex;
@synthesize distance = _distance;

//@synthesize unSavedTrips = _unSavedTrips;
//@synthesize unSyncedTrips = _unSyncedTrips;
//@synthesize zeroDistanceTrips = _zeroDistanceTrips;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if ( self = [super init] )
	{
		self.activityDelegate		= self;
		self.coords					= [[NSMutableArray alloc] initWithCapacity:1000];
		self.distance					= 0.0;
		self.managedObjectContext	= context;
		self.trip					= nil;
		self.purposeIndex				= -1;
        self.modeIndex                   = -1;
        
    }
    return self;
}


- (BOOL)loadTrip:(Trip*)tripIn
{
    if ( tripIn )
	{
		self.trip					= tripIn;
		self.distance					= [tripIn.distance doubleValue];
		self.managedObjectContext	= [tripIn managedObjectContext];
		
		// NOTE: loading coords can be expensive for a large trip
		NSLog(@"loading %fm trip started at %@...", self.distance, tripIn.start);

		// sort coords by recorded date DESCENDING so that the coord at index=0 is the most recent
		NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recorded"
																		ascending:NO];
		NSArray *sortDescriptors	= [NSArray arrayWithObjects:dateDescriptor, nil];
		self.coords					= [[[tripIn.coords allObjects] sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
		
		NSLog(@"loading %d coords completed.", [self.coords count]);

		// recalculate duration
		if ( self.coords && [self.coords count] > 1 )
		{
			Coord *last		= [self.coords objectAtIndex:0];
			Coord *first	= [self.coords lastObject];
			NSTimeInterval duration = [last.recorded timeIntervalSinceDate:first.recorded];
			NSLog(@"duration = %.0fs", duration);
			[self.trip setDuration:[NSNumber numberWithDouble:duration]];
		}
		
		// save updated duration to CoreData
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"loadTrip error %@, %@", error, [error localizedDescription]);
		}
		
		/*
		// recalculate trip distance
		CLLocationDistance newDist	= [self calculateTripDistance:tripIn];
		
		NSLog(@"newDist: %f", newDist);
		NSLog(@"oldDist: %f", distance);
		*/
		
		// TODO: initialize purposeIndex from trip.purpose
		self.purposeIndex				= -1;
        self.modeIndex = -1;
    }
    return YES;
}


- (id)initWithTrip:(Trip*)tripIn
{
    if ( self = [super init] )
	{
		self.activityDelegate = self;
		[self loadTrip:tripIn];
    }
    return self;
}


- (UIActivityIndicatorView *)createActivityIndicator
{
	if ( self.activityIndicator == nil )
	{
		CGRect frame = CGRectMake( 130.0, 88.0, kActivityIndicatorSize, kActivityIndicatorSize );
		self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		[self.activityIndicator sizeToFit];
	}
	return self.activityIndicator;
}


- (void)createTripNotesText
{
	self.tripNotesText = [[UITextView alloc] initWithFrame:CGRectMake( 12.0, 50.0, 260.0, 65.0 )];
	self.tripNotesText.delegate = self;
	self.tripNotesText.enablesReturnKeyAutomatically = NO;
	self.tripNotesText.font = [UIFont fontWithName:@"Arial" size:16];
	self.tripNotesText.keyboardAppearance = UIKeyboardAppearanceAlert;
	self.tripNotesText.keyboardType = UIKeyboardTypeDefault;
	self.tripNotesText.returnKeyType = UIReturnKeyDone;
	self.tripNotesText.text = kTripNotesPlaceholder;
	self.tripNotesText.textColor = [UIColor grayColor];
}


#pragma mark UITextViewDelegate


- (void)textViewDidBeginEditing:(UITextView *)textView
{
	NSLog(@"textViewDidBeginEditing");
	
	if ( [textView.text compare:kTripNotesPlaceholder] == NSOrderedSame )
	{
		textView.text = @"";
		textView.textColor = [UIColor blackColor];
	}
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	NSLog(@"textViewShouldEndEditing: \"%@\"", textView.text);
	
	if ( [textView.text compare:@""] == NSOrderedSame )
	{
		textView.text = kTripNotesPlaceholder;
		textView.textColor = [UIColor grayColor];
	}
	
	return YES;
}


// this code makes the keyboard dismiss upon typing done / enter / return
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"])
	{
		[textView resignFirstResponder];
		return NO;
	}
	
	return YES;
}


- (CLLocationDistance)distanceFrom:(Coord*)prev to:(Coord*)next realTime:(BOOL)realTime
{
	CLLocation *prevLoc = [[CLLocation alloc] initWithLatitude:[prev.latitude doubleValue] 
													 longitude:[prev.longitude doubleValue]];
	CLLocation *nextLoc = [[CLLocation alloc] initWithLatitude:[next.latitude doubleValue] 
													 longitude:[next.longitude doubleValue]];
	
	//CLLocationDistance	deltaDist	= [nextLoc getDistanceFrom:prevLoc];
    CLLocationDistance deltaDist = [nextLoc distanceFromLocation:prevLoc];
	NSTimeInterval		deltaTime	= [next.recorded timeIntervalSinceDate:prev.recorded];
	CLLocationDistance	newDist		= 0.;
	
	/*
	 NSLog(@"prev.date = %@", prev.recorded);
	 NSLog(@"deltaTime = %f", deltaTime);
	 
	 NSLog(@"deltaDist = %f", deltaDist);
	 NSLog(@"est speed = %f", deltaDist / deltaTime);
	 
	 if ( [next.speed doubleValue] > 0.1 ) {
	 NSLog(@"est speed = %f", deltaDist / deltaTime);
	 NSLog(@"rec speed = %f", [next.speed doubleValue]);
	 }
	 */
	
	// sanity check accuracy
	if ( [prev.hAccuracy doubleValue] < kEpsilonAccuracy && 
		 [next.hAccuracy doubleValue] < kEpsilonAccuracy )
	{
		// sanity check time interval
		if ( !realTime || deltaTime < kEpsilonTimeInterval )
		{
			// sanity check speed
			if ( !realTime || (deltaDist / deltaTime < kEpsilonSpeed) )
			{
				// consider distance delta as valid
				newDist += deltaDist;
				
				// only log non-zero changes
				/*
				 if ( deltaDist > 0.1 )
				 {
				 NSLog(@"new dist  = %f", newDist);
				 NSLog(@"est speed = %f", deltaDist / deltaTime);
				 }
				 */
			}
			else
				NSLog(@"WARNING speed exceeds epsilon: %f => throw out deltaDist: %f, deltaTime: %f", 
					  deltaDist / deltaTime, deltaDist, deltaTime);
		}
		else
			NSLog(@"WARNING deltaTime exceeds epsilon: %f => throw out deltaDist: %f", deltaTime, deltaDist);
	}
	else
		NSLog(@"WARNING accuracy exceeds epsilon: %f => throw out deltaDist: %f", 
			  MAX([prev.hAccuracy doubleValue], [next.hAccuracy doubleValue]) , deltaDist);
	
	return newDist;
}

- (bool)checkForInit
{
    bool result = NO;
    
    NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	
	if ( count )
	{
		NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) 
        {
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"TripManager fetch saved user data error %@, %@", error, [error localizedDescription]);
		}
		
		User *user = [mutableFetchResults objectAtIndex:0];
        NSArray *filteredCoords	= [self.trip.coords allObjects];
        int numcount = [self.trip.coords count];
        Coord *temploc = [filteredCoords objectAtIndex:numcount-1];
        
        if ([[user lastendlat] doubleValue] == 0.0 || [[user lastendlong] doubleValue] == 0.0)
        {
            
            [user setLastendlat:[NSNumber numberWithDouble:[temploc.latitude doubleValue]]];
            [user setLastendlong:[NSNumber numberWithDouble:[temploc.longitude doubleValue]]];
            //NSLog(@"initializing saved end point from zero....");
        }
        
        CLLocation *storedLoc = [[CLLocation alloc] initWithLatitude:[[user lastendlat] doubleValue] longitude:[[user lastendlong] doubleValue]];
        
        CLLocation *storedLoc1 = [[CLLocation alloc] initWithLatitude:[temploc.latitude doubleValue] longitude:[temploc.longitude doubleValue]];
        
        //  get distance in meters
        if ([storedLoc distanceFromLocation:storedLoc1] > 200)
            result = YES;
        
        //  now update stored distance
        [user setLastendlat:[NSNumber numberWithDouble:[temploc.latitude doubleValue]]];
        [user setLastendlong:[NSNumber numberWithDouble:[temploc.longitude doubleValue]]];
        NSLog(@"updating stored distance to current last point of trip");
        
    }
    return result;
    
}




- (void)addLastUsedCoord
{
    NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	
	if ( count )
	{
		NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"TripManager fetch saved user data error %@, %@", error, [error localizedDescription]);
		}
		
		User *user = [mutableFetchResults objectAtIndex:0];
        [self addCoord:[[CLLocation alloc] initWithLatitude:[[user lastendlat] doubleValue] longitude:[[user lastendlong] doubleValue]]];
        NSLog(@"adding last used coord of %@ %@", [user lastendlat], [user lastendlong]);
        
    }
    
}


- (CLLocationDistance)addCoord:(CLLocation *)location
{
	//NSLog(@"addCoord");
	
	if ( !self.trip )
		[self createTrip];	

	// Create and configure a new instance of the Coord entity
	Coord *coord = (Coord *)[NSEntityDescription insertNewObjectForEntityForName:@"Coord" inManagedObjectContext:self.managedObjectContext];
	
	[coord setAltitude:[NSNumber numberWithDouble:location.altitude]];
	[coord setLatitude:[NSNumber numberWithDouble:location.coordinate.latitude]];
	[coord setLongitude:[NSNumber numberWithDouble:location.coordinate.longitude]];
	
	// NOTE: location.timestamp is a constant value on Simulator
	//[coord setRecorded:[NSDate date]];
	[coord setRecorded:location.timestamp];
	
	[coord setSpeed:[NSNumber numberWithDouble:location.speed]];
	[coord setHAccuracy:[NSNumber numberWithDouble:location.horizontalAccuracy]];
	[coord setVAccuracy:[NSNumber numberWithDouble:location.verticalAccuracy]];
	
	[self.trip addCoordsObject:coord];
	//[coord setTrip:trip];

	// check to see if the coords array is empty
	if ( [self.coords count] == 0 )
	{
		NSLog(@"updated trip start time");
		// this is the first coord of a new trip => update start
		[self.trip setStart:[coord recorded]];
		self.dirty = YES;
	}
	else
	{
		// update distance estimate by tabulating deltaDist with a low tolerance for noise
		Coord *prev  = [self.coords objectAtIndex:0];
		self.distance	+= [self distanceFrom:prev to:coord realTime:YES];
		[self.trip setDistance:[NSNumber numberWithDouble:self.distance]];
		
		// update duration
		Coord *first	= [self.coords lastObject];
		NSTimeInterval duration = [coord.recorded timeIntervalSinceDate:first.recorded];
		//NSLog(@"duration = %.0fs", duration);
		[self.trip setDuration:[NSNumber numberWithDouble:duration]];
		
		/*
		Coord *prev = [coords objectAtIndex:0];
		CLLocation *prevLoc = [[CLLocation alloc] initWithLatitude:[prev.latitude doubleValue] 
														 longitude:[prev.longitude doubleValue]];

		CLLocationDistance	deltaDist = [location getDistanceFrom:prevLoc];
		NSTimeInterval		deltaTime = [location.timestamp timeIntervalSinceDate:prev.recorded];
		
		NSLog(@"deltaDist = %f", deltaDist);
		NSLog(@"deltaTime = %f", deltaTime);
		NSLog(@"est speed = %f", deltaDist / deltaTime);
		
		// sanity check accuracy
		if ( [prev.hAccuracy doubleValue] < kEpsilonAccuracy && 
			 location.horizontalAccuracy < kEpsilonAccuracy )
		{
			// sanity check time interval if non-zero
			if ( !kEpsilonTimeInterval || deltaTime < kEpsilonTimeInterval )
			{
				// sanity check speed
			self.	if ( deltaDist / deltaTime < kEpsilonSpeed )
				{
					// consider distance delta as valid
					distance += deltaDist;
					dirty = YES;

					NSLog(@"distance: %f", distance);
				}
				else
					NSLog(@"WARNING speed exceeds epsilon: %f", deltaDist / deltaTime);
			}
			else
				NSLog(@"WARNING deltaTime exceeds epsilon: %f", deltaTime);
		}
		else
			NSLog(@"WARNING accuracy exceeds epsilon: %f", location.horizontalAccuracy);
		 */
	}
	
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"TripManager addCoord error %@, %@", error, [error localizedDescription]);
	}

	[self.coords insertObject:coord atIndex:0];
	//NSLog(@"# coords = %d", [coords count]);
	
	return self.distance;
}


- (CLLocationDistance)getDistanceEstimate
{
	return self.distance;
}


- (NSString*)jsonEncodeUserData
{
	//NSLog(@"jsonEncodeUserData");
	NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithCapacity:14];
	
	NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	
	if ( count )
	{
		NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"TripManager fetch saved user data error %@, %@", error, [error localizedDescription]);
		}
		
		User *user = [mutableFetchResults objectAtIndex:0];
		if ( user != nil )
		{
			// initialize text fields to saved personal info
			//[userDict setValue:user.age			forKey:@"age"];
			[userDict setValue:user.email		forKey:@"email"];
			//[userDict setValue:user.gender		forKey:@"gender"];
			//[userDict setValue:user.homeZIP		forKey:@"homeZIP"];
			//[userDict setValue:user.workZIP		forKey:@"workZIP"];
			//[userDict setValue:user.schoolZIP	forKey:@"schoolZIP"];
			[userDict setValue:user.cyclingFreq	forKey:@"cyclingFreq"];
            
   			//[userDict setValue:user.ownacar	forKey:@"ownacar"];
   			//[userDict setValue:user.liveoncampus	forKey:@"liveoncampus"];
   			[userDict setValue:user.enterdrawing	forKey:@"enterDrawing"];
  			[userDict setValue:user.uvaClassification	forKey:@"uvaClassification"];
   			[userDict setValue:user.name	forKey:@"name"];
            [userDict setValue:user.uvaAffiliated forKey:@"uvaAffiliated"];
            [userDict setValue:user.cyclingLevel forKey:@"cyclingLevel"];
		}
		else
			NSLog(@"TripManager fetch user FAIL");
		
	}
	else
		NSLog(@"TripManager WARNING no saved user data to encode");
	
	NSLog(@"serializing user data to JSON...");
	NSString *jsonUserData = [[CJSONSerializer serializer] serializeObject:userDict];
	NSLog(@"%@", jsonUserData );
	
	return jsonUserData;
}


- (void)saveNotes:(NSString*)notes
{
	if ( self.trip && notes )
		[self.trip setNotes:notes];
}


- (void)saveTrip
{
	//NSLog(@"about to save trip with %d coords...", [self.coords count]);
	[self.activityDelegate updateSavingMessage:kPreparingData];
	//NSLog(@"%@", self.trip);

	// close out Trip record
	// NOTE: this code assumes we're saving the current recording in progress
	
	/* TODO: revise to work with following edge cases:
	 o coords unsorted
	 o break in recording => can't calc duration by comparing first & last timestamp,
	   incrementally tally delta time if < epsilon instead
	 o recalculate distance
	 */
    NSDate * endTime = nil;
    
	if ( self.trip && [self.coords count] )
	{
		CLLocationDistance newDist = [self calculateTripDistance:self.trip];
		//NSLog(@"real-time distance = %.0fm", self.distance);
		//NSLog(@"post-processing    = %.0fm", newDist);
		
		self.distance = newDist;
		[self.trip setDistance:[NSNumber numberWithDouble:self.distance]];
		
		Coord *last		= [self.coords objectAtIndex:0];
		Coord *first	= [self.coords lastObject];
		NSTimeInterval duration = [last.recorded timeIntervalSinceDate:first.recorded];
		//NSLog(@"duration = %.0fs", duration);
		[self.trip setDuration:[NSNumber numberWithDouble:duration]];
        endTime = last.recorded;
    }
	
	[self.trip setSaved:[NSDate date]];
	
	NSError *error;
	if (![self.managedObjectContext save:&error])
	{
		// Handle the error.
		NSLog(@"TripManager setSaved error %@, %@", error, [error localizedDescription]);
	}
	else
		//NSLog(@"Saved trip: %@ (%.0fm, %.0fs)", self.trip.purpose, [self.trip.distance floatValue], [self.trip.duration floatValue] );

	self.dirty = YES;
	
	// get array of coords
	NSMutableDictionary *tripDict = [NSMutableDictionary dictionaryWithCapacity:[self.coords count]];
	NSEnumerator *enumerator = [self.coords objectEnumerator];
	Coord *coord;
	
	// format date as a string
	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];		
	[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	// TODO: test more campact float representations with NSString, NSNumberFormatter

#if kSaveProtocolVersion == kSaveProtocolVersion_2
	//NSLog(@"saving using protocol version 2");
	
    // interpolate only 100 points
    if ([self.coords count] > 100)
    {
        NSMutableArray* hundcoords = [[NSMutableArray alloc] init];
        float step = [self.coords count]/(float)100;
        for (int i = 0; i < 100; i++) {
            Coord* temper = [self.coords objectAtIndex:(int)round(i*step)];
            [hundcoords addObject:temper];
        }
        
        enumerator = [hundcoords objectEnumerator];
        //NSLog(@"count of hundcoords is %d", [hundcoords count]);
    }
    
    //NSLog(@"coords has %d objects. enumerating...", [self.coords count]);
//    NSLog(@"coords is %@", coords);
//    NSLog(@"enum is %@", enumerator);
    
	// create a tripDict entry for each coord
    // IGNORE ERROR BELOW 
	while (coord = [enumerator nextObject])
	{
		NSMutableDictionary *coordsDict = [NSMutableDictionary dictionaryWithCapacity:7];
		[coordsDict setValue:coord.altitude  forKey:@"alt"];
		[coordsDict setValue:coord.latitude  forKey:@"lat"];
		[coordsDict setValue:coord.longitude forKey:@"lon"];
		[coordsDict setValue:coord.speed     forKey:@"spd"];
		[coordsDict setValue:coord.hAccuracy forKey:@"hac"];
		[coordsDict setValue:coord.vAccuracy forKey:@"vac"];
		
       //NSLog(@"coord is %@ %@", coord.latitude, coord.longitude);

        
		NSString *newDateString = [outputFormatter stringFromDate:coord.recorded];
		[coordsDict setValue:newDateString forKey:@"rec"];
		[tripDict setValue:coordsDict forKey:newDateString];
	}
#else
	NSLog(@"saving using protocol version 1");
	
	// create a tripDict entry for each coord
	while (coord = [enumerator nextObject])
	{
		NSMutableDictionary *coordsDict = [NSMutableDictionary dictionaryWithCapacity:7];
		[coordsDict setValue:coord.altitude  forKey:@"altitude"];
		[coordsDict setValue:coord.latitude  forKey:@"latitude"];
		[coordsDict setValue:coord.longitude forKey:@"longitude"];
		[coordsDict setValue:coord.speed     forKey:@"speed"];
		[coordsDict setValue:coord.hAccuracy forKey:@"hAccuracy"];
		[coordsDict setValue:coord.vAccuracy forKey:@"vAccuracy"];
		
		NSString *newDateString = [outputFormatter stringFromDate:coord.recorded];
		[coordsDict setValue:newDateString forKey:@"recorded"];		
		[tripDict setValue:coordsDict forKey:newDateString];
	}
#endif

	//NSLog(@"serializing trip data to JSON...");
	NSString *jsonTripData = [[CJSONSerializer serializer] serializeObject:tripDict];
	//NSLog(@"%@", jsonTripData );
	
	// get trip purpose
	NSString *purpose;
	if ( self.trip.purpose )
		purpose = self.trip.purpose;
	else
		purpose = @"unknown";
	
    NSString *mode;
    if ( self.trip.mode )
		mode = self.trip.mode;
	else
		mode = @"unknown";
	
	// get trip notes
	NSString *notes = @"";
	if ( self.trip.notes )
		notes = self.trip.notes;
	
	// get start date
	NSString *start = [outputFormatter stringFromDate:self.trip.start];
	//NSLog(@"start: %@", start);

    //Get saved date
    NSString *end = nil;
    if(endTime != nil) {
        end = [outputFormatter stringFromDate:endTime];
    } else {
        end = @"";
    }
        
	// encode user data
	NSString *jsonUserData = [self jsonEncodeUserData];

	// NOTE: device hash added by SaveRequest initWithPostVars
	NSDictionary *postVars = [NSDictionary dictionaryWithObjectsAndKeys:
							  jsonTripData, @"coords",
							  purpose, @"purpose",
                              mode, @"weather",
							  notes, @"notes",
							  start, @"start",
                              end, @"end",
							  jsonUserData, @"user",
							  [NSString stringWithFormat:@"%d", kSaveProtocolVersion], @"version",
							  nil];
	
	// create save request
	SaveRequest *saveRequest = [[SaveRequest alloc] initWithPostVars:postVars];
	
	// create the connection with the request and start loading the data
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:[saveRequest request]
																   delegate:self];
	
	if ( theConnection )
	{
		self.receivedData=[NSMutableData data];		
	}
	else
	{
		// inform the user that the download could not be made
	}
}


#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	//NSLog(@"%d bytesWritten, %d totalBytesWritten, %d totalBytesExpectedToWrite",
	//	  bytesWritten, totalBytesWritten, totalBytesExpectedToWrite );
	
	[self.activityDelegate updateBytesWritten:totalBytesWritten
			   totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	//NSLog(@"didReceiveResponse: %@", response);
	
	NSHTTPURLResponse *httpResponse = nil;
	if ( [response isKindOfClass:[NSHTTPURLResponse class]] &&
		( httpResponse = (NSHTTPURLResponse*)response ) )
	{
		BOOL success = NO;
		NSString *title   = nil;
		NSString *message = nil;
		switch ( [httpResponse statusCode] )
		{
			case 200:
			case 201:
				success = YES;
				title	= kSuccessTitle;
				message = kSaveSuccess;
				break;
			case 202:
				success = YES;
				title	= kSuccessTitle;
				message = kSaveAccepted;
				break;
			case 500:
			default:
				title = @"Internal Server Error";
				//message = [NSString stringWithFormat:@"%d", [httpResponse statusCode]];
				message = kServerError;
		}
		
		//NSLog(@"%@: %@", title, message);
		
		// update trip.uploaded 
		if ( success )
		{
			[self.trip setUploaded:[NSDate date]];
			
			NSError *error;
			if (![self.managedObjectContext save:&error]) {
				// Handle the error.
				NSLog(@"TripManager setUploaded error %@, %@", error, [error localizedDescription]);
			}
		}
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:self.alertDelegate
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		
		[self.activityDelegate dismissSaving];
		[self.activityDelegate stopAnimating];
	}
	
    // it can be called multiple times, for example in the case of a
	// redirect, so each time we reset the data.
	
    // receivedData is declared as a method instance elsewhere
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{	
    // append the new data to the receivedData	
    // receivedData is declared as a method instance elsewhere
	[self.receivedData appendData:data];	
	[self.activityDelegate startAnimating];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object	
	
    // receivedData is declared as a method instance elsewhere
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	
	[self.activityDelegate dismissSaving];
	[self.activityDelegate stopAnimating];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kConnectionError
													message:[error localizedDescription]
												   delegate:self.alertDelegate
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// do something with the data
    NSLog(@"Succeeded! Received %d bytes of data", [self.receivedData length]);
	NSLog(@"%@", [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] );

	[self.activityDelegate dismissSaving];
	[self.activityDelegate stopAnimating];

    // release the connection, and the data object
}


- (NSInteger)getPurposeIndex
{
	NSLog(@"%d", self.purposeIndex);
	return self.purposeIndex;
}

- (NSInteger)getModeIndex
{
	NSLog(@"%d", self.modeIndex);
	return self.modeIndex;
}

#pragma mark TripPurposeDelegate methods


- (NSString *)getPurposeString:(unsigned int)index
{
	return [TripPurpose getPurposeString:index];
}

- (NSString *)getModeString:(unsigned int)index
{
	return [TripPurpose getModeString:index];
}

- (NSString *)setPurpose:(unsigned int)index
{
	NSString *purpose = [self getPurposeString:index];
	NSLog(@"setPurpose: %@", purpose);
	self.purposeIndex = index;
	
	if ( self.trip )
	{
		[self.trip setPurpose:purpose];
		
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"setPurpose error %@, %@", error, [error localizedDescription]);
		}
	}
	else
		[self createTrip:index];

	self.dirty = YES;
	return purpose;
}

- (NSString *)setMode:(unsigned int)index
{
	NSString *mode = [self getModeString:index];
	NSLog(@"setMode: %@", mode);
	self.modeIndex = index;
	
	if ( self.trip )
	{
		[self.trip setMode:mode];
		
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"setPurpose error %@, %@", error, [error localizedDescription]);
		}
	}
	else
		[self createTrip:index];
    
	self.dirty = YES;
	return mode;
}


- (void)createTrip
{
	NSLog(@"createTrip");
	
	// Create and configure a new instance of the Trip entity
	self.trip = (Trip *)[NSEntityDescription insertNewObjectForEntityForName:@"Trip" 
												  inManagedObjectContext:self.managedObjectContext];
	[self.trip setStart:[NSDate date]];
	
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"createTrip error %@, %@", error, [error localizedDescription]);
	}
}


// DEPRECATED
- (void)createTrip:(unsigned int)index
{
	NSString *purpose = [self getPurposeString:index];
	NSLog(@"createTrip: %@", purpose);

    NSString *mode = [self getModeString:index];
	NSLog(@"createTrip: %@", mode);

    
	// Create and configure a new instance of the Trip entity
	self.trip = (Trip *)[NSEntityDescription insertNewObjectForEntityForName:@"Trip" 
												  inManagedObjectContext:self.managedObjectContext];
	
	[self.trip setPurpose:purpose];
   	[self.trip setMode:mode];
	[self.trip setStart:[NSDate date]];
	
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"createTrip error %@, %@", error, [error localizedDescription]);
	}
}

- (void)promptForTripNotes
{
	self.tripNotes = [[UIAlertView alloc] initWithTitle:kTripNotesTitle
										   message:@"\n\n\n"
										  delegate:self
								 cancelButtonTitle:@"Skip"
								 otherButtonTitles:@"OK", nil];

	[self createTripNotesText];
	[self.tripNotes addSubview:self.tripNotesText];
	[self.tripNotes show];
}


#pragma mark UIAlertViewDelegate methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"tripNotes didDismissWithButtonIndex: %d", buttonIndex);
    
    //Force entry of notes if purpose or weather is set to "Other"
    if (
        ([self.trip.purpose isEqualToString:@"Other"] || 
         [self.trip.mode isEqualToString:@"Other"])
        && (
            [self.tripNotesText.text isEqualToString:kTripNotesPlaceholder] || 
            [self.tripNotesText.text isEqualToString:@"Please specify custom purpose/weather here"]
            )
        )
    {
        // they have to specify something in comments
        self.tripNotes = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                    message:@"\n\n\n"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
        
        [self createTripNotesText];
        self.tripNotesText.text = @"Please specify custom purpose/weather here";
        
        [self.tripNotes addSubview:self.tripNotesText];
        [self.tripNotes show];
        
        return;
        
    }
    
    NSLog(@"alertView: %@", alertView);
    
    // save trip notes
    if ( buttonIndex == 1 || ([alertView.title isEqualToString:@"Oops!"] && buttonIndex == 0))
    {
        if ( [self.tripNotesText.text compare:kTripNotesPlaceholder] != NSOrderedSame )
        {
            //NSLog(@"saving trip notes: %@", self.tripNotesText.text);
            [self saveNotes:self.tripNotesText.text];
        }
    }
    
    // present UIAlertView "Saving..."
    self.saving = [[UIAlertView alloc] initWithTitle:kSavingTitle
                                             message:kConnecting
                                            delegate:nil
                                   cancelButtonTitle:nil
                                   otherButtonTitles:nil];
    
    //NSLog(@"created saving dialog: %@", self.saving);
    
    [self createActivityIndicator];
    [self.activityIndicator startAnimating];
    [self.saving addSubview:self.activityIndicator];
    [self.saving show];
    
    // save / upload trip
    [self saveTrip];		
}


#pragma mark ActivityIndicatorDelegate methods


- (void)dismissSaving
{
	if ( self.saving )
		[self.saving dismissWithClickedButtonIndex:0 animated:YES];
}


- (void)startAnimating {
	[self.activityIndicator startAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)stopAnimating {
	//[activityIndicator stopAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)updateBytesWritten:(NSInteger)totalBytesWritten
 totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	if ( self.saving )
		self.saving.message = [NSString stringWithFormat:@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite];
}


- (void)updateSavingMessage:(NSString *)message
{
	if ( self.saving )
		self.saving.message = message;
}


#pragma mark methods to allow continuing a previously interrupted recording


// count trips that have not yet been saved
- (int)countUnSavedTrips
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	// configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"saved = nil"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	NSLog(@"countUnSavedTrips = %d", count);
	
	return count;
}

// count trips that have been saved but not uploaded
- (int)countUnSyncedTrips
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	// configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"saved != nil AND uploaded = nil"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	NSLog(@"countUnSyncedTrips = %d", count);
	
	return count;
}

// count trips that have been saved but have zero distance
- (int)countZeroDistanceTrips
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	// configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"saved != nil AND distance < 0.1"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
	NSLog(@"countZeroDistanceTrips = %d", count);
	
	return count;
}

- (BOOL)loadMostRecetUnSavedTrip
{
	BOOL success = NO;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	// configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"saved = nil"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"no UNSAVED trips");
		if ( error != nil )
			NSLog(@"Unresolved error2 %@, %@", error, [error userInfo]);
	}
	else if ( [mutableFetchResults count] )
	{
		NSLog(@"UNSAVED trip(s) found");

		// NOTE: this will sort the trip's coords and make it ready to continue recording
		success = [self loadTrip:[mutableFetchResults objectAtIndex:0]];
	}
	
	return success;
}





// filter and sort all trip coords before calculating distance in post-processing
- (CLLocationDistance)calculateTripDistance:(Trip*)tripIn
{
	//NSLog(@"calculateTripDistance for trip started %@ having %d coords", tripIn.start, [tripIn.coords count]);
	
	CLLocationDistance newDist = 0.;

	if ( tripIn != self.trip )
		[self loadTrip:tripIn];
	
	// filter coords by hAccuracy
	NSPredicate *filterByAccuracy	= [NSPredicate predicateWithFormat:@"hAccuracy < 100.0"];
	NSArray		*filteredCoords		= [[tripIn.coords allObjects] filteredArrayUsingPredicate:filterByAccuracy];
	//NSLog(@"count of filtered coords = %d", [filteredCoords count]);
	
	if ( [filteredCoords count] )
	{
		// sort filtered coords by recorded date
		NSSortDescriptor *sortByDate	= [[NSSortDescriptor alloc] initWithKey:@"recorded" ascending:YES];
		NSArray		*sortDescriptors	= [NSArray arrayWithObjects:sortByDate, nil];
		NSArray		*sortedCoords		= [filteredCoords sortedArrayUsingDescriptors:sortDescriptors];
		
		// step through each pair of neighboring coors and tally running distance estimate
		
		// NOTE: assumes ascending sort order by coord.recorded
		// TODO: rewrite to work with DESC order to avoid re-sorting to recalc
		for (int i=1; i < [sortedCoords count]; i++)
		{
			Coord *prev	 = [sortedCoords objectAtIndex:(i - 1)];
			Coord *next	 = [sortedCoords objectAtIndex:i];
			newDist	+= [self distanceFrom:prev to:next realTime:NO];
		}
	}
	
	//NSLog(@"oldDist: %f => newDist: %f", self.distance, newDist);	
	return newDist;
}


- (int)recalculateTripDistances
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	// configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"saved != nil AND distance < 0.1"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"no trips with zero distance found");
		if ( error != nil )
			NSLog(@"Unresolved error2 %@, %@", error, [error userInfo]);
	}
	int count = [mutableFetchResults count];

	NSLog(@"found %d trip(s) in need of distance recalcuation", count);

	for (Trip *tripIt in mutableFetchResults)
	{
		CLLocationDistance newDist = [self calculateTripDistance:tripIt];
		[tripIt setDistance:[NSNumber numberWithDouble:newDist]];

		NSError *error;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"TripManager addCoord error %@, %@", error, [error localizedDescription]);
		}
		break;
	}
	
	
	return count;
}


@end


@implementation TripPurpose

+ (unsigned int)getPurposeIndex:(NSString*)string
{
	if ( [string isEqualToString:kTripPurposeCommuteString] )
		return kTripPurposeCommute;
	else if ( [string isEqualToString:kTripPurposeSchoolString] )
		return kTripPurposeSchool;
	else if ( [string isEqualToString:kTripPurposeWorkString] )
		return kTripPurposeWork;
	else if ( [string isEqualToString:kTripPurposeExerciseString] )
		return kTripPurposeExercise;
	else if ( [string isEqualToString:kTripPurposeSocialString] )
		return kTripPurposeSocial;
	else if ( [string isEqualToString:kTripPurposeShoppingString] )
		return kTripPurposeShopping;
	else if ( [string isEqualToString:kTripPurposeErrandString] )
		return kTripPurposeErrand;
	//	else if ( [string isEqualToString:kTripPurposeOtherString] )
	else
		return kTripPurposeOther;
}

+ (unsigned int)getModeIndex:(NSString*)string
{
	/*if ( [string isEqualToString:kTripModeCommuteString] )
		return kTripPurposeCommute;
	else if ( [string isEqualToString:kTripModeSchoolString] )
		return kTripPurposeSchool;
	else if ( [string isEqualToString:kTripModeWorkString] )
		return kTripPurposeWork;
	else if ( [string isEqualToString:kTripModeExerciseString] )
		return kTripPurposeExercise;
	else if ( [string isEqualToString:kTripModeSocialString] )
		return kTripPurposeSocial;
	else if ( [string isEqualToString:kTripModeShoppingString] )
		return kTripPurposeShopping;
	else if ( [string isEqualToString:kTripModeOtherString] )
		return kTripPurposeErrand;
	//	else if ( [string isEqualToString:kTripPurposeOtherString] )
	else
        return kTripPurposeOther;
    */
     
    if( [string isEqualToString:kTripWeatherSunnyString])
        return kTripWeatherSunny;
    else if([string isEqualToString: kTripWeatherRainingString])
        return kTripWeatherRaining;
    else if( [string isEqualToString:kTripWeatherSnowingString])
        return kTripWeatherSnowing;
    else if ( [string isEqualToString:kTripWeatherOtherString])
        return kTripWeatherOther;
    else 
        return kTripWeatherOther;
    
}

/*
 * Class
 * Home/Dorm
 * Work
 * School-related
 * Social/Rec.
 * Shopping
 * Errand
 * Other
 */

+ (NSString *)getPurposeString:(unsigned int)index
{
	switch (index) {
		case kTripPurposeCommute:
			return kTripPurposeCommuteString;
			break;
		case kTripPurposeSchool:
			return kTripPurposeSchoolString;
			break;
		case kTripPurposeWork:
			return kTripPurposeWorkString;
			break;
		case kTripPurposeExercise:
			return kTripPurposeExerciseString;
			break;
		case kTripPurposeSocial:
			return kTripPurposeSocialString;
			break;
		case kTripPurposeShopping:
			return kTripPurposeShoppingString;
			break;
		case kTripPurposeErrand:
			return kTripPurposeErrandString;
			break;
		case kTripPurposeOther:
		default:
			return kTripPurposeOtherString;
			break;
	}
}

/*
 * Walk
 * Bike
 * MotorBike
 * Carpool
 * Bus
 * Car
 * Other
 */

+ (NSString *)getModeString:(unsigned int)index
{
	switch (index) {
        case kTripWeatherSunny:
            return kTripWeatherSunnyString;
            break;
        case kTripWeatherRaining:
            return kTripWeatherRainingString;
            break;
        case kTripWeatherSnowing:
            return kTripWeatherSnowingString;
            break;
        case kTripWeatherOther:
            return kTripWeatherOtherString;
            break;
        default:
            return kTripWeatherOtherString;
            break;
		/*case kTripPurposeCommute:
			return @"Walk";
			break;
		case kTripPurposeSchool:
			return @"Bike";
			break;
		case kTripPurposeWork:
			return @"Motorbike";
			break;
		case kTripPurposeExercise:
			return @"Carpool";
			break;
		case kTripPurposeSocial:
			return @"Bus";
			break;
		case kTripPurposeShopping:
			return @"Car";
			break;
		case kTripPurposeErrand:
			return @"Other";
			break;
		case kTripPurposeOther:
		default:
			return @"MagicCarpet";
			break;
         */
	}
}
@end

