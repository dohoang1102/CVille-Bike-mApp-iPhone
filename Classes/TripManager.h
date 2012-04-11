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
//  TripManager.h
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/22/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "ActivityIndicatorDelegate.h"
#import "TripPurposeDelegate.h"


@class Trip;


@interface TripManager : NSObject
<ActivityIndicatorDelegate, 
TripPurposeDelegate, 
UIAlertViewDelegate, 
UITextViewDelegate>
@property (nonatomic, strong) id <ActivityIndicatorDelegate> activityDelegate;
@property (nonatomic, strong) id <UIAlertViewDelegate> alertDelegate;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIAlertView *saving;
@property (nonatomic, strong) UIAlertView *tripNotes;
@property (nonatomic, strong) UITextView *tripNotesText;

@property (assign) BOOL dirty;
@property (nonatomic, strong) Trip *trip;

@property (nonatomic, strong) NSMutableArray *coords;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableData *receivedData;
@property (assign) NSInteger purposeIndex;
@property (assign) NSInteger modeIndex;
@property(assign) CLLocationDistance distance;

//@property(nonatomic, strong) NSMutableArray *unSavedTrips;
//@property(nonatomic, strong) NSMutableArray *unSyncedTrips;
//@property(nonatomic, strong) NSMutableArray *zeroDistanceTrips;


- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;
- (id)initWithTrip:(Trip*)trip;
- (BOOL)loadTrip:(Trip*)trip;
- (void)createTrip;
- (bool)checkForInit;
- (void)createTrip:(unsigned int)index;
- (CLLocationDistance)addCoord:(CLLocation*)location;
- (void)addLastUsedCoord;
- (void)saveNotes:(NSString*)notes;
- (void)saveTrip;
- (CLLocationDistance)getDistanceEstimate;
- (NSInteger)getPurposeIndex;
- (NSInteger)getModeIndex;
- (void)promptForTripNotes;
- (int)countUnSavedTrips;
- (int)countUnSyncedTrips;
- (int)countZeroDistanceTrips;
- (BOOL)loadMostRecetUnSavedTrip;
- (int)recalculateTripDistances;
- (CLLocationDistance)calculateTripDistance:(Trip*)_trip;

@end


@interface TripPurpose : NSObject { }

+ (unsigned int)getPurposeIndex:(NSString*)string;
+ (NSString *)getPurposeString:(unsigned int)index;
+ (unsigned int)getModeIndex:(NSString*)string;
+ (NSString *)getModeString:(unsigned int)index;

@end


