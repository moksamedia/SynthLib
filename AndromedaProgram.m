//
//  AndromedaProgram.m
//  SynthLib
//
//  Created by Andrew Hughes on 12/16/08.
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

#import "AndromedaProgram.h"
#import "AlesisAndromeda.h"
//#import "Utility.h"
#import "SynthFactory.h"


#define ANDROMEDA_PROGRAM_DUMP_HEADER {0xF0, 0x00, 0x00, 0x0E, 0x1D, 0x00, 0x00, 0x00}
#define ANDROMEDA_PROGRAM_DUMP_HEADER_LENGTH 8

@implementation AndromedaProgram

//////////////////////////////////////////////////////////////////////////////////////////////////
// INIT

- (id) init
{
	NSAssert(true, @"This should not be called!");
	return nil;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data
{
	if ((self = [super initWithSynth:_synth data:_data]))
	{
		[self extractNameFromDataAndSetToName];

		numberOfBanks = ANDROMEDA_NUMBER_OF_BANKS;
		numberOfPrograms = ANDROMEDA_NUM_PROGRAMS_PER_BANK;
	}
	return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// SAVE AND LOAD - keep all of this at the lowest level for easy versioning

- (void) encodeWithCoder: (NSCoder *) coder
{
	[super encodeWithCoder:coder];	
	
	return;
}

- (id)initWithCoder: (NSCoder *) coder
{
	[super initWithCoder:coder];
	
	synthType == SYNTH_ANDROMEDA;
	
	numberOfBanks = ANDROMEDA_NUMBER_OF_BANKS;
	numberOfPrograms = ANDROMEDA_NUM_PROGRAMS_PER_BANK;
	
	return self;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// GET AND SET PROGRAM PROPERTIES

- (NSString*) bankName
{
	switch (bankNumber) {
		case 0:
			return @"User";
			break;
		case 1:
			return @"Preset 1";
			break;
		case 2:
			return @"Preset 2";
			break;
		default:
			return @"DOH!";
			break;
	}
}

- (NSString*) name
{
	return name;
}

- (BOOL) setName: (NSString*) newName
{	
	NSAssert([newName isKindOfClass:[NSString class]], @"invalid name!");
	
	//[[Utility sharedUndoManager] registerUndoWithTarget:self selector:@selector(setName:) object:name];

	[name release];

	name = [[NSString alloc] initWithString: newName];
	// setting and extracting seems a little much, but it does take care of truncating the string and it insures that the string is written properly
	
	[self setNameToData];
	[self extractNameFromDataAndSetToName];
	
	return TRUE;
}

- (BOOL) setData: (NSMutableData*) newData
{
	if (data!=nil) [data release];
	data = newData;
	[data retain];
	[self extractNameFromDataAndSetToName]; 
	return TRUE;
}

- (void) sendToSynth: (ASynth*) aSynth programNumber: (int) pn bankNumber: (int) bn
{
	NSAssert([aSynth synthType] == SYNTH_ANDROMEDA, @"Trying to send patch to wrong synth type!");
	
	// if nil, used stored value
	if (pn == NOVALUE) pn = programNumber;
	
	if (bn == NOVALUE) bn = bankNumber;
	
	NSAssert(programNumber < ANDROMEDA_NUM_PROGRAMS_PER_BANK && bankNumber == 0, @"Trying to send to improper program number or bank number!");

	[aSynth sendProgramDump: self programNumber:pn bankNumber: bn];
	
}

- (void) sendToSynthAtProgramNumber: (int) pn bankNumber: (int) bn;
{
	// if nil, used stored value
	if (pn == (int)nil) pn = programNumber;  // the casting to (int) is just to get rid of warning
	
	if (bn == (int)nil) bn = bankNumber;
	
	NSAssert(programNumber <= 127 && bankNumber == 0, @"Trying to send to improper program number or bank number!");
	
	[synth sendProgramDump: self programNumber:pn bankNumber: bn];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// DEAL WITH PACK AND UNPACK FUNCTIONS

// extracts the name from the packed format and writes it to the program name string
- (void) extractNameFromDataAndSetToName
{
	unsigned char buffer[15];  //unpacked
	
	int i;
	for (i=0; i<17; i++)
	{
		buffer[i] = [self getByteFromData: i+2];
	}
	
	[name release]; 
	name = [NSString alloc];
	name = [name initWithBytes: &buffer[0] length: 15 encoding: NSASCIIStringEncoding];
}

// Writes the name to the data in packed format
- (void) setNameToData
{
	// get an NSData containing the string
	NSData * nameData = [name dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: TRUE];
	// then get the bytes from the NSData
	unsigned char * bytes = (unsigned char*) [nameData bytes];	

	int nameOffset = 2; // this is the  offset from the beginning of the unpacked data

	/*
		Iterates through bytes of name string, writing them to the packed data.  When end of string is reached, if it is reached
		before 15 bytes, zeros are filled in the rest of the bytes.  If the entered name is longer than 15 chars, it is truncated.
	*/
	int i;
	for (i=0; i<15; i++)
	{
		if( i < [name length] )
		{
			[self writeByteToData: bytes[i] atIndex: i+nameOffset];
		}
		else
		{
			[self writeByteToData: 0 atIndex: i+nameOffset];			
		}
	}
	
	//[nameData release];
}

// reads a byte from packed data and unpacks it
- (Byte) getByteFromData: (int) index
{
	NSAssert(index < [data length] && index >= 0, @"AndromedaProgram: getByteFromData, index out of range!");
	unsigned char * packedBytes = (unsigned char*) [data bytes];  //packed
	Byte unpackedByte = 0x0;
	
	//NSLog(@"index = %d, newIndex = %d", index, index + (int)round(index / 7));

	int offset = (int)round(index / 7);  
	/* 
		unpacked index + offset = packed index
		offset is necessary because 7 bytes of unpacked data map to 8 bytes of packed data
		offset increases by 1 every 7 UNPACKED bytes ( 0-6 maps to 0-7, 7-14 maps to 8-15, etc...)
		also, the offset only affects the starting point of reading from the unpacked buffer
	*/

	int ui = index;				//unpacked index
	int pi = index + offset;	//packed index
	
	// yes, it's fucking complicated
	unpackedByte = ( packedBytes[pi] >> (ui % 7) ) | ( packedBytes[pi+1] << (7 - ui % 7) );
	
	return unpackedByte;
}

// writes a byte of unpacked data to packed data
- (void) writeByteToData: (Byte) byte atIndex: (int) index
{
	NSAssert(index < [data length] && index >= 0, @"AndromedaProgram: getByteFromData, index out of range!");
	unsigned char * packedBytes = [data mutableBytes];  //packed

	int offset = (int)round(index / 7);  
	int ui = index;  // packed index
	int pi = index + offset;  //unpacked index

	// clear the appropriate bits
	packedBytes[pi]    = packedBytes[pi]   & ( 0xFF >> ( 8 - ui%7 ) );
	packedBytes[pi+1]  = packedBytes[pi+1] & ( 0xFF << ( ui%7 + 1 ) );

	// set the bytes
	packedBytes[pi]    = packedBytes[pi]   | (( byte << ( ui%7) ) & 0x7F );  // 0x7F = 0111 1111
	packedBytes[pi+1]  = packedBytes[pi+1] | (  byte >> ( 7 - ui%7) );

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
		return [[AndromedaProgram allocWithZone:zone] initWithSynth: synth data: [data mutableCopy]];
	}
	else
	{
		return [[AndromedaProgram alloc] initWithSynth: synth data: [data mutableCopy]];
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
