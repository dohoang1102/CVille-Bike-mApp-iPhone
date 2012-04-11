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
//  CDataScanner_Extensions.h
//  TouchJSON
//
//  Created by Jonathan Wight on 12/08/2005.
//  Copyright 2005 Toxic Software. All rights reserved.
//

#import "CDataScanner.h"

@interface CDataScanner (CDataScanner_Extensions)

- (BOOL)scanCStyleComment:(NSString **)outComment;
- (BOOL)scanCPlusPlusStyleComment:(NSString **)outComment;

@end
