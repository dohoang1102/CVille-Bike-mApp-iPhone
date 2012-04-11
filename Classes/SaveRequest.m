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
//  SaveRequest.m
//  CycleTracks
//
//  Copyright 2009-2010 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/25/09.
//	For more information on the project, 
//	e-mail Billy Charlton at the SFCTA <billy.charlton@sfcta.org>

#import "constants.h"
#import "CVilleRidesAppDelegate.h"
#import "SaveRequest.h"


@implementation SaveRequest
{
	//NSMutableURLRequest *request;
	//NSString *deviceUniqueIdHash;
	//NSMutableDictionary *postVars;
}

@synthesize request = _request;
@synthesize deviceUniqueIdHash = _deviceUniqueIdHash;
@synthesize postVars = _postVars;

#pragma mark init

- initWithPostVars:(NSDictionary *)inPostVars
{
	if (self = [super init])
	{
		// Nab the unique device id hash from our delegate.
		CVilleRidesAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		self.deviceUniqueIdHash = delegate.uniqueIDHash;
		
		// create request.
		self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kSaveURL]]; // prop set retains
		// [request addValue:kServiceUserAgent forHTTPHeaderField:@"User-Agent"];

		// setup POST vars
		[self.request setHTTPMethod:@"POST"];
		self.postVars = [NSMutableDictionary dictionaryWithDictionary:inPostVars];
	
		// add hash of device id
		[self.postVars setObject:self.deviceUniqueIdHash forKey:@"device"];

		// convert dict to string
		NSMutableString *postBody = [NSMutableString string];

		for(NSString * key in self.postVars)
			[postBody appendString:[NSString stringWithFormat:@"%@=%@&", key, [self.postVars objectForKey:key]]];

		NSLog(@"initializing HTTP POST request to %@ with %d bytes", 
			  kSaveURL,
			  [[postBody dataUsingEncoding:NSUTF8StringEncoding] length]);
        NSLog(@"body: %@", postBody);
		[self.request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return self;
}


#pragma mark instance methods

// add POST vars to request
- (NSURLConnection *)getConnectionWithDelegate:(id)delegate
{
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:self.request delegate:delegate];
	return conn;
}

@end
