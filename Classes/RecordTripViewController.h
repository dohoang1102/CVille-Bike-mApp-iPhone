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
//  RecordTripViewController.h
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/10/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>


#import <CoreLocation/CoreLocation.h>
#import "ActivityIndicatorDelegate.h"
#import <MapKit/MapKit.h>
#import "PersonalInfoDelegate.h"
#import "RecordingInProgressDelegate.h"
#import "TripPurposeDelegate.h"
#import "Coord.h"

@class ReminderManager;
@class TripManager;


//@interface RecordTripViewController : UITableViewController 
@interface RecordTripViewController : UIViewController 
	<CLLocationManagerDelegate,
	MKMapViewDelegate,
	UINavigationControllerDelegate, 
	UITabBarControllerDelegate, 
	PersonalInfoDelegate,
	RecordingInProgressDelegate,
	TripPurposeDelegate,
	UIActionSheetDelegate,
	UIAlertViewDelegate,
	UITextViewDelegate>
    

//@property (nonatomic, strong) UIView   *parentView;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UIButton *lockButton;
@property (nonatomic, strong) IBOutlet UILabel *timeCounter;
@property (nonatomic, strong) IBOutlet UILabel *distCounter;
@property (nonatomic, strong) IBOutlet UILabel *speedCounter;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIView   *sliderView;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) UIView   *opacityMask;
@property (nonatomic, strong) Coord   *lasttriplastpoint;
@property (assign) BOOL locked;
@property (assign) BOOL recording;
@property (assign) BOOL shouldUpdateCounter;
@property (assign) BOOL userInfoSaved;
@property (assign) BOOL didUpdateUserLocation;
@property (nonatomic, strong) ReminderManager *reminderManager;
@property (nonatomic, strong) TripManager *tripManager;
@property (nonatomic, strong) Trip *displayTrip;

- (void)initTripManager:(TripManager*)manager;

// IBAction handlers
- (IBAction)lockAction:(UIButton*)sender;
- (IBAction)save:(UIButton *)sender;
- (IBAction)start:(UIButton *)sender;

// timer methods
- (void)start:(UIButton *)sender;
- (void)createCounter;
- (void)resetCounter;
- (void)setCounterTimeSince:(NSDate *)startDate distance:(CLLocationDistance)distance;
- (void)updateCounter:(NSTimer *)theTimer;
- (void)createOpacityMask;
- (UISlider *)createSlideToUnlock:(UIView*)view;
- (void)lockDevice;
- (void)unlockDevice;

@end
