//
//  YamahaPCM91Program.m
//  SynthLib
//
//  Created by Andrew Hughes on 12/18/08.
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

#import "YamahaPCM91Program.h"
#import "SynthFactory.h"
#import "SynthLib.h"


@implementation YamahaPCM91Program

- (id) init
{
	NSAssert(true, @"This should not be called!");
	return nil;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data
{
	if ((self = [super initWithSynth:_synth data:_data]))
	{
		numberOfBanks = PCM91_NUMBER_OF_BANKS;
		numberOfPrograms = PCM91_NUM_PROGRAMS_PER_BANK;
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
	
	synthType == SYNTH_PCM91;

	numberOfBanks = PCM91_NUMBER_OF_BANKS;
	numberOfPrograms = PCM91_NUM_PROGRAMS_PER_BANK;
	
	return self;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// GET AND SET PROGRAM PROPERTIES

- (NSString*) bankName
{
	switch (bankNumber) {
		case 0:
			return @"P0 - Halls";
			break;
		case 1:
			return @"P1 - Rooms";
			break;
		case 2:
			return @"P2 - Plates";
			break;
		case 3:
			return @"P3 - Post";
			break;
		case 4:
			return @"P4 - Splits";
			break;
		case 5:
			return @"P5 - Studio";
			break;
		case 6:
			return @"P6 - Live";
			break;
		case 7:
			return @"P7 - Post";
			break;
		case 8:
			return @"P8 - Surround";
			break;
		case 9:
			return @"R0 - User 1";
			break;
		case 10:
			return @"R1 - User 2";
			break;
		default:
			return @"DOH!";
			break;
	}
}

- (NSString*) name
{
	// get an NSData from the main data with the name in it
	NSData * nameData = [self getBytesFromDataForRange: NSMakeRange(PCM91_PROGRAM_NAME_OFFSET, PCM91_PROGRAM_NAME_LENGTH)];

	[nameData retain];
	
	// convert nameData to string
	NSString * aName = [[NSString alloc] initWithBytes: [nameData bytes]  length: PCM91_PROGRAM_NAME_LENGTH encoding: NSASCIIStringEncoding];

	[nameData release];

	return aName;
}

- (BOOL) setName: (NSString*) newName
{	
	NSMutableData * nameData = [[newName dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: TRUE] mutableCopy];
	NSLog(@"New Name: %@", newName);
	
	[nameData setLength: PCM91_PROGRAM_NAME_LENGTH];
	
	[self writeBytesToData:NSMakeRange(PCM91_PROGRAM_NAME_OFFSET, PCM91_PROGRAM_NAME_LENGTH) data: nameData];
	return TRUE;
}

- (BOOL) setData: (NSMutableData*) newData
{
	if (data!=nil) [data release];
	data = newData;
	[data retain];
	return TRUE;
}

- (void) sendToSynth: (ASynth*) aSynth programNumber: (int) pn bankNumber: (int) bn;
{
	NSAssert([aSynth synthType] == SYNTH_PCM91, @"Trying to send patch to wrong synth type!");
	
	if (pn == NOVALUE) pn = programNumber;
	if (bn == NOVALUE) bn = bankNumber;
	
	NSAssert(pn <= 50 && ( bn == PCM91_USER_BANK_1 || bn == PCM91_USER_BANK_2 ), @"Trying to send to improper program number or bank number!");
	
	[aSynth sendProgramDump: self programNumber:pn bankNumber: bn];
}

- (void) sendToSynthAtProgramNumber: (int) pn bankNumber: (int) bn;
{
	if (pn == NOVALUE) pn = programNumber;
	if (bn == NOVALUE) bn = bankNumber;
	
	NSAssert(pn <= 50 && ( bn == PCM91_USER_BANK_1 || bn == PCM91_USER_BANK_2 ), @"Trying to send to improper program number or bank number!");
	
	[synth sendProgramDump: self programNumber:pn bankNumber: bn];
}


- (NSMutableData*) getBytesFromDataForRange: (NSRange) range
{
	int index = range.location;
	int length = range.length;
	int i;
	
	NSMutableData * unpackedData = [[NSMutableData alloc] initWithLength:length];
	Byte * unpackedBytes = [unpackedData mutableBytes];
	
	for (i=0; i < length; i++)
	{
		unpackedBytes[i] = [self getByteFromData: i + index];
	}
	
	[unpackedData autorelease];
	
	return unpackedData;
}

- (void) writeBytesToData: (NSRange) range data: (NSData*) dataToWrite
{
	int index = range.location;
	int length = range.length;
	int i;
	
	Byte * unpackedBytes = (Byte*)[dataToWrite bytes];
	
	for (i=0; i < length; i++)
	{
		[self writeByteToData: unpackedBytes[i] atIndex: i + index];
	}


}

// reads a byte from packed data and unpacks it
- (Byte) getByteFromData: (int) index
{
	NSAssert(index < [data length] && index >= 0, @"YamahaPCM91Program: getByteFromData, index out of range!");
	unsigned char * packedBytes = (unsigned char*) [data bytes];  //packed
	Byte unpackedByte = 0x0;
	
	index = index * 2;
	
	unpackedByte = packedBytes[index] | ( packedBytes[index+1] << 4);
	
	//NSLog(@"Byte %d = %d - %c", index, unpackedByte, unpackedByte);
	
	return unpackedByte;
}

// writes a byte of unpacked data to packed data
- (void) writeByteToData: (Byte) byte atIndex: (int) index
{
	NSLog(@"Writing %X to index %d", byte, index);
	
	// needed to translate between nibble-ized index and unpacked index (bc there are two bytes of packed (nibble-ized) data per unpacked data
	index = index * 2;
	
	NSAssert(index < [data length] && index >= 0, @"YamahaPCM91Program: getByteFromData, index out of range!");
	unsigned char * packedBytes = [data mutableBytes];  //packed

	// clear the appropriate bits
	packedBytes[index]    = 0x00;
	packedBytes[index+1]  = 0x00;

	// set the LSB
	packedBytes[index]    = byte & 0x0F;  // 0x0F = 0000 1111
	
	// set the MSB
	packedBytes[index+1]  = byte >> 4;

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
		return [[YamahaPCM91Program allocWithZone:zone] initWithSynth: synth data: [data mutableCopy]];
	}
	else
	{
		return [[YamahaPCM91Program alloc] initWithSynth: synth data: [data mutableCopy]];	
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
