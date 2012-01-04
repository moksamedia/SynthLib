//
//  AGlobalDump.m
//  SynthLib
//
//  Created by Andrew Hughes on 1/29/09.
//
//    -------------------------------------------
//
//
//    All code (c)2008 Moksa Media all rights reserved
//    Developer: Andrew Hughes
//
//    This file is part of SynthLib.
//
//    SynthLib is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    SynthLib is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with SynthLib.  If not, see <http://www.gnu.org/licenses/>.
//
//
//    -------------------------------------------
//

#import "AGlobalDump.h"


@implementation AGlobalDump

- (id) init
{
	NSAssert(true, @"This should not be called!");
	return nil;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data
{
	if ((self = [super initWithSynth:_synth data:_data type:GLOBAL]))
	{
		
		// INITIALIZE NAME TO CURRENT DATE AND TIME
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSDate *date = [NSDate date];
		NSString *formattedDateString = [dateFormatter stringFromDate:date];
		[self setName:formattedDateString];
	}
	return self;
}


- (BOOL) setData: (NSMutableData*) newData
{
	if (data!=nil) [data release];
	data = newData;
	[data retain];
	return TRUE;
}


- (NSString*) name
{
	return name;
}


- (BOOL) setName: (NSString*) newName
{	
	NSAssert([newName isKindOfClass:[NSString class]], @"invalid name!");		
	[name release];	
	name = [[NSString alloc] initWithString: newName];
	return TRUE;
}


- (NSString*) bankName
{
	return @"n/a";
}


- (NSString*) programNumberString
{
	return @"n/a";
}


// Called by TableView via collection to see if a column in the table view should be edited by user.
// - prog number and bank number for global data are meaningless, so we shouldn't edit
- (BOOL) shouldEditForIdentifier: (NSString*) identifier
{
	if ( [identifier isEqualToString:@"Prog"] || [identifier isEqualToString:@"Prog"] )
	{
		return false;
	}
	else
	{
		return true;
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// COPY AND MUTABLE COPY

- (id) copy
{
	return [self copyWithZone:nil];
}

- (id) copyWithZone: (NSZone*) zone
{
	if (zone != nil)
	{
		return [[AGlobalDump allocWithZone:zone] initWithSynth: synth data: [data mutableCopy] type: type];
	}
	else
	{
		return [[AGlobalDump alloc] initWithSynth: synth data: [data mutableCopy] type: type];
	}
}

- (id) mutableCopy
{
	return [self copyWithZone:nil];
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
	return [self copyWithZone:zone];
	
}

@end
