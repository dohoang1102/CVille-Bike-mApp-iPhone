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
//  PersonalInfoViewController.h
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/23/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>

#import <UIKit/UIKit.h>
#import "PersonalInfoDelegate.h"


@class User;

@interface PersonalInfoViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) id <PersonalInfoDelegate> delegate;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) UITextField	*age;
@property (nonatomic, strong) UITextField	*email;
@property (nonatomic, strong) UITextField	*gender;
@property (nonatomic, strong) UITextField	*homeZIP;
@property (nonatomic, strong) UITextField	*workZIP;
@property (nonatomic, strong) UITextField	*schoolZIP;
@property (nonatomic, strong) UITextField	*name;
@property (nonatomic, strong) UISegmentedControl	*entersurveyswitch;
@property (nonatomic, strong) UISegmentedControl	*owncarswitch;
@property (nonatomic, strong) UISegmentedControl	*liveoncampusswitch;
@property (nonatomic, strong) NSNumber		*cyclingFreq;

//New properties
@property (nonatomic, strong) UITextField *cyclingLevel;
@property (nonatomic, strong) UISegmentedControl *uvaAffiliated;
@property (nonatomic, strong) UITextField	*uvaClassification;

//- (void)initTripManager:(TripManager*)manager;  

// DEPRECATED
- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;

- (void)done;


@end
