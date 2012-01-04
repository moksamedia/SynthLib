//
//  ACollectionItem.m
//  SynthLib
//
//  Created by Andrew Hughes on 12/20/08.
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

#import "ACollectionItem.h"
#import "SynthFactory.h"
#import "SynthLib.h"


@implementation ACollectionItem

//////////////////////////////////////////////////////////////////////////////////////////////////
// INIT AND DEALLOC 

- (id) init
{
	NSAssert(true, @"This should not be called!");
	return nil;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data type: (int) _type
{
	if ((self = [super init])) 
	{
		data = _data;
		[data retain];
		comments = [[NSString alloc] initWithString:@"-"];
		comments2 = [[NSString alloc] initWithString:@"-"];
		type = _type;  //item type, ie. Program, Bank, Global Dump, etc.
		name = [[NSString alloc] initWithString:@"unset"];
		
		synthType = [synth synthType];
		inPort = [synth inputPort];
		outPort = [synth outputPort];
	}
	return self;
}

- (void) dealloc
{
	[data release];
	[comments release];
	[comments2 release];
	[name release];
	[super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// SAVE AND LOAD 

- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeObject: data forKey:@"data"];
	[coder encodeObject: comments forKey:@"comments"];
	[coder encodeObject: comments2 forKey:@"comments2"];
	[coder encodeInt: type forKey: @"type"];
	[coder encodeInt:inPort forKey:@"inPort"];
	[coder encodeInt:outPort forKey:@"outPort"];
	[coder encodeInt:synthType forKey:@"outPort"];
	
	return;
}

- (id)initWithCoder: (NSCoder *) coder
{	
	[self setData:[coder decodeObjectForKey:@"data"]];
	
	comments = [[coder decodeObjectForKey:@"comments"] retain];
	comments2 = [[coder decodeObjectForKey:@"comments2"] retain];
	
	type = [coder decodeIntForKey:@"type"];
	
	inPort = [coder decodeIntForKey:@"inPort"];
	outPort = [coder decodeIntForKey:@"outPort"];
	synthType = [coder decodeIntForKey:@"synthType"];
		
	NSAssert(data != nil && synth != nil && comments != nil, @"nil value on load!");
	
	return self;
}


//////////////////////////////////////////////////////////////////////////////////////////////////


- (NSMutableData*) data
{
	return data;
}

- (ASynth*) synth
{
	return synth;
}

// Ask the item's synth for it's name string so we can give it to the table view
- (NSString*) synthName
{
	return [synth name];
}


- (BOOL) setSynth: (ASynth*) newSynth
{
	synth = newSynth;
	return TRUE;
}

- (NSString*) typeString
{
	if (type == 0) return @"PROGRAM";
	else if (type == 1) return @"GLOBAL";
	else if (type == 2) return @"MIX";
	else return nil;
}

- (NSString*) comments
{
	return comments;
}

- (BOOL) setComments: (NSString*) newComments
{
	[comments release];
	comments = [[NSString alloc] initWithString: newComments];
	return TRUE;
}

- (NSString*) comments2
{
	return comments2;
}

- (BOOL) setComments2: (NSString*) newComments2
{
	[comments2 release];
	comments2 = [[NSString alloc] initWithString: newComments2];
	return TRUE;
}


// Called by TableView via collection to see if a column in the table view should be edited by user.  Default behavior is yes.
- (BOOL) shouldEditForIdentifier: (NSString*) identifier
{
	return true;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS

- (BOOL) setData: (NSMutableData*) newData
{
	NSAssert(true, @"Must be overriden by sublass!  May want to set name when data is set.");
	return false;	
}

- (NSString*) name
{
	NSAssert(true, @"Must be overriden by sublass!  May need to read name from data.");
	return nil;	
}

- (BOOL) setName: (NSString*) newName
{
	NSAssert(true, @"Must be overriden by sublass!  May need to set name to data file.");
	return false;	
}

- (NSString*) bankName
{
	NSAssert(true, @"Must be overriden by sublass!");
	return nil;	
}

- (NSString*) programNumberString
{
	NSAssert(true, @"Must be overriden by sublass!");
	return nil;
}

- (id) copy
{
	NSAssert(true, @"Must be implemented by subclass!");
	return nil;
}

- (id) copyWithZone: (NSZone*) zone
{
	NSAssert(true, @"Must be implemented by subclass!");
	return nil;
}

- (id) mutableCopy
{
	NSAssert(true, @"Must be implemented by subclass!");
	return nil;
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
	NSAssert(true, @"Must be implemented by subclass!");
	return nil;
}

@end
