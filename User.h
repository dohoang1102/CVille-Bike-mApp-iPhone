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
//  User.h
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/25/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>

#import <CoreData/CoreData.h>

@class Trip;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, strong) NSString * age;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * gender;
@property (nonatomic, strong) NSNumber * cyclingFreq;
@property (nonatomic, strong) NSString * schoolZIP;
@property (nonatomic, strong) NSString * workZIP;
@property (nonatomic, strong) NSString * homeZIP;
@property (nonatomic, strong) NSString * ownacar;
@property (nonatomic, strong) NSString * enterdrawing;
@property (nonatomic, strong) NSString * liveoncampus;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * hasaccepted;
@property (nonatomic, strong) NSString * hasenteredvalidinfo;
@property (nonatomic, strong) NSNumber * lastendlat;
@property (nonatomic, strong) NSNumber * lastendlong;
@property (nonatomic, strong) NSSet* trips;


@property (nonatomic, strong) NSString * cyclingLevel;
@property (nonatomic, strong) NSString * uvaAffiliated;
@property (nonatomic, strong) NSString * uvaClassification;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addTripsObject:(Trip *)value;
- (void)removeTripsObject:(Trip *)value;
- (void)addTrips:(NSSet *)value;
- (void)removeTrips:(NSSet *)value;

@end

