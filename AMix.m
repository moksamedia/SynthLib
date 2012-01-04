//
//  AMix.m
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

#import "AMix.h"


@implementation AMix
//////////////////////////////////////////////////////////////////////////////////////////////////
// INIT

- (id) init
{
	NSAssert(true, @"This should not be called!");
	return nil;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data
{
	if ((self = [super initWithSynth:_synth data:_data type:PROGRAM]))
	{
		numberOfPrograms = -1; // set to invalid numbers, must be overridden
		numberOfBanks = -1;
		type = PROGRAM;
	}
	return self;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// SAVE AND LOAD - keep all of this at the lowest level for easy versioning

- (void) encodeWithCoder: (NSCoder *) coder
{
	[super encodeWithCoder:coder];
	
	[coder encodeInt: programNumber forKey:@"programNumber"];
	[coder encodeInt: bankNumber forKey:@"bankNumber"];
	
	return;
}

- (id)initWithCoder: (NSCoder *) coder
{
	[super initWithCoder:coder];	
	
	bankNumber = [coder decodeIntForKey:@"bankNumber"];
	programNumber = [coder decodeIntForKey:@"programNumber"];
	
	return self;
}


//////////////////////////////////////////////////////////////////////////////////////////////////


// BANK

- (int) bankNumber
{
	return bankNumber;
}

- (BOOL) setBankNumber: (int) i
{
	NSAssert(numberOfBanks != -1, @"Sublass must set numberOfBanks!");
	NSAssert(i>=0 && i<3, @"AndromendaProgram: setBankNumber - invalid bank number!");
	
	bankNumber = i;
	
	return TRUE;
}

- (BOOL) trySetBankNumber: (int) i
{
	NSAssert(numberOfBanks != -1, @"Sublass must set numberOfBanks!");
	if (i>=0 && i < numberOfBanks)
	{
		[self setBankNumber: i];
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}


// PROGRAM

- (int) programNumber
{
	return programNumber;
}

- (NSString*) programNumberString
{
	return [NSString stringWithFormat:@"%d", programNumber];
}


- (BOOL) setProgramNumber: (int) i
{
	NSAssert(numberOfPrograms != -1, @"Sublass must set numberOfBanks!");
	NSAssert(i>=0 && i<numberOfPrograms, @"AndromendaProgram: setProgramNumber - invalid bank number!");
	NSLog(@"setting program number %d", i);
	
	programNumber = i;
	return TRUE;
}

- (BOOL) trySetProgramNumber: (int) i
{
	NSAssert(numberOfPrograms != -1, @"Sublass must set numberOfBanks!");
	
	if (i>=0 && i < numberOfPrograms)
	{
		[self setProgramNumber: i];
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS


- (void) sendToSynthAtProgramNumber: (int) pn bankNumber: (int) bn 
{
	NSAssert(true, @"Must be overridden by sublass!");
}

- (void) sendSelectedInSynth
{
	NSAssert(true, @"Must be overridden by sublass!");	
}

@end
