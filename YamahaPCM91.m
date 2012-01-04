//
//  YamahaPCM91.m
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

#import "YamahaPCM91.h"
#import "YamahaPCM91Program.h"
#import "ACollectionItem.h"
#import "SynthLib.h"
#import "Utility.h"
#import "AProgram.h"


@implementation YamahaPCM91

- (id)initWithInputPort: (int) _inputPort outputPort: (int) _outputPort
{
	if ((self = [super initWithInputPort:_inputPort outputPort:_outputPort]))
	{
		synthType = SYNTH_PCM91;
		
	}
	return self;
}


- (NSString*) name
{
	return @"PCM91";
}

// Sysex data request methods
- (void)requestProgramDump: (int) programNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection
{
	NSAssert(programNumber >= 0 && programNumber <= PCM91_NUM_PROGRAMS_PER_BANK - 1, @"PCM91: patchNumber out of bounds!");
	NSAssert(bankNumber >= 0 && bankNumber <= PCM91_NUMBER_OF_BANKS - 1, @"PCM91: bankNumber out of bounds!");
	NSAssert([collection isKindOfClass: [ACollection class]], @"YamahaPCM91: requestProgramDump: collection invalid!");
	
	requestingCollection = collection;

	NSLog(@"Sending to PCM91");
		
	Byte request[]= {	0xF0,		// SYSEX MESSAGE START
						PCM91_SYSEX_LEXICON_ID,
						PCM91_SYSEX_PCM91_ID,		
						PCM91_DEVICE_ID,
						PCM91_SYSEX_DATA_REQUEST,
						PCM91_SYSEX_PROGRAM_DUMP_REQUEST,		
						0x00,		// BANK
						0x00,		// OFFSET (program)
						0x00,		// NOT USED
						0x00,		// NOT USED
						0x00,		// NOT USED
						0xf7		// END OF MESSAGE
					};

	request[6] = bankNumber;
	request[7] = programNumber;

	[midi sendSysexRequest: request size: PCM91_SYSEX_REQUEST_SIZE];
}

- (void)requestProgramEditBufferDumpForCollection: (ACollection*) collection
{
	NSLog(@"HERE");
	NSAssert([collection isKindOfClass: [ACollection class]], @"YamahaPCM91: requestProgramEditBufferDump: collection invalid!");
	
	requestingCollection = collection;

	Byte request[]= {	0xF0,		// SYSEX MESSAGE START
						PCM91_SYSEX_LEXICON_ID,
						PCM91_SYSEX_PCM91_ID,		
						PCM91_DEVICE_ID,
						PCM91_SYSEX_DATA_REQUEST,
						PCM91_SYSEX_PROGRAM_DUMP_REQUEST,		
						0x00,		// BANK
						0x00,		// OFFSET (program)
						0x00,		// NOT USED
						0x00,		// NOT USED
						0x00,		// NOT USED
						0xf7		// END OF MESSAGE
					};


	request[6] = 0x7f;
	request[7] = 0x7f;

	[midi sendSysexRequest: request size: PCM91_SYSEX_REQUEST_SIZE];

}

- (void)requestProgramBankDump: (int) bankNumber forCollection: (ACollection*) collection
{
	NSAssert(bankNumber >= 0 && bankNumber <= PCM91_NUMBER_OF_BANKS - 1, @"PCM91: bankNumber out of bounds!");

	requestingCollection = collection;

	Byte request[]= {	0xF0,		// SYSEX MESSAGE START
						PCM91_SYSEX_LEXICON_ID,
						PCM91_SYSEX_PCM91_ID,		
						PCM91_DEVICE_ID,
						PCM91_SYSEX_DATA_REQUEST,
						PCM91_SYSEX_BANK_DUMP_REQUEST,		
						0x00,		// BANK
						0x00,		// OFFSET (program)
						0x00,		// NOT USED
						0x00,		// NOT USED
						0x00,		// NOT USED
						0xf7		// END OF MESSAGE
					};


	request[6] = bankNumber;

	[midi sendSysexRequest: request size: PCM91_SYSEX_REQUEST_SIZE];

}

- (int) tryImportData: (NSMutableData*) dataToImport forCollection: (ACollection*) collection
{
	requestingCollection = collection;
	return [self receiveSysexMessage: dataToImport];
}

-(int) receiveSysexMessage: (NSMutableData *) data
{

	Byte header[7];
	[data getBytes: header range: NSMakeRange(0, 7)];
	
	//NSAssert(header[1] == PCM91_SYSEX_LEXICON_ID && header[2] == PCM91_SYSEX_PCM91_ID, @"YamahaPCM91: receiveSysexMessage: message has wrong header!");
	
	Byte opcode = header[4];
	
	// check to makes sure this is an Andromeda Program
	if ( header[0] != 0xF0 || header[1] != PCM91_SYSEX_LEXICON_ID || header[2] != PCM91_SYSEX_PCM91_ID || header[3] != PCM91_DEVICE_ID )
	{
		NSLog(@"PCM91 Synth: Attempting to receive sysex that is not proprerly formed or is not PCM91 message."); 
		return -1;
	}
	
	if (opcode == PCM91_OPCODE_SINGLE_EFFECT_DUMP)  // edit buffer dump
	{
		NSLog(@"PCM91 program dump received.");
		
		if ([data length] < PCM91_PROGRAM_DUMP_LENGTH)
		{
			[Utility runAlertWithMessage: @"Improper Sysex Received from PCM91"];
			return -1;
		}	
		
		NSMutableData * dataBytes = [[NSMutableData alloc] initWithLength:2337];
			
		[data getBytes: [dataBytes mutableBytes] range: NSMakeRange(7, 2337)];
		
		YamahaPCM91Program * newProgram = [[YamahaPCM91Program alloc] initWithSynth: self data: [dataBytes mutableCopy]];
		
		// when you request an edit buffer dump, it comes back with bank number 127 - this changes that to 0
		if (header[5] = 0x7f) { header[5] = 0x00; header[6] = 0x00; }
		
		NSLog(@"Program Created %@ at pn %d and bn %d of length %d.", [newProgram name], header[6], header[5], [dataBytes length]);
		[newProgram setBankNumber: header[5] ];
		[newProgram setProgramNumber: header[6] ];
		[requestingCollection addItemAtSelectedRow: newProgram];
		[newProgram autorelease];
		[dataBytes autorelease];
		
		return PCM91_PROGRAM_DUMP_LENGTH;
	}
	else if (opcode == PCM91_OPCODE_BANK_DUMP)
	{
		NSLog(@"PCM91 bank dump received.");
		
		if ([data length] < PCM91_BANK_DUMP_LENGTH)
		{
			[Utility runAlertWithMessage: @"Improper Sysex (Bank Dump) Received from PCM91"];
			return -1;
		}	
		
		Byte * dumpBytes = (Byte*)[data bytes];
		
		int bankNumber = dumpBytes[5];
		int programNumber = 0;
		int offset = 68;
		
		NSMutableData * newProgramBytes;
		YamahaPCM91Program * newProgram;
		
		int i;
		for (i=0; i < PCM91_NUM_PROGRAMS_PER_BANK; i++)
		{
			newProgramBytes = [[NSMutableData alloc] initWithLength:2337];
			[data getBytes: [newProgramBytes mutableBytes] range: NSMakeRange(offset, 2337)];
			
			newProgram = [[YamahaPCM91Program alloc] initWithSynth: self data: [newProgramBytes mutableCopy]];
			
			NSLog(@"Program Created %@ at pn %d and bn %d of length %d.", [newProgram name], programNumber, bankNumber, [newProgramBytes length]);
			[newProgram setBankNumber: bankNumber ];
			[newProgram setProgramNumber: programNumber ];
			[requestingCollection addItemAtSelectedRow: newProgram];
			
			offset += 2337;
			programNumber += 1;
			
			[newProgram autorelease];
			[newProgramBytes release];	
		}
		
		return PCM91_BANK_DUMP_LENGTH;
	}
	else
	{
		return -1;
	}


}

- (BOOL) checkMatchForSynthFactory: (int) _synthType inPort: (int) inPort outPort: (int) outPort
{
	if (_synthType == SYNTH_PCM91 && inPort == inputPort && outPort == outputPort) return TRUE;
	else return FALSE;
}


- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{

	NSAssert1(programNumber >= 0 && programNumber <= PCM91_NUM_PROGRAMS_PER_BANK, @"patchNumber (%d) out of bounds!", programNumber);
	NSAssert1(bankNumber >= 9 && bankNumber <= 10, @"bankNumber (%d) out of bounds!", bankNumber);
	NSAssert([program isMemberOfClass: [YamahaPCM91Program class]], @"Trying to send wrong program type!");
	
	NSData * toSend = [self prepareProgramToSend:(AProgram*)program programNumber:programNumber bankNumber:bankNumber];
	
	[toSend retain];
	
	[midi sendLongSysex: (Byte*)[toSend bytes] size: [toSend length]];
	
	[toSend release];

}

- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{
	NSAssert1(programNumber >= 0 && programNumber <= PCM91_NUM_PROGRAMS_PER_BANK, @"patchNumber (%d) out of bounds!", programNumber);
	NSAssert1(bankNumber >= 0 && bankNumber <= 10, @"bankNumber (%d) out of bounds!", bankNumber);
	
	Byte header[]= {	0xF0,		// SYSEX MESSAGE START
		PCM91_SYSEX_LEXICON_ID,
		PCM91_SYSEX_PCM91_ID,		
		PCM91_DEVICE_ID,
		PCM91_OPCODE_SINGLE_EFFECT_DUMP,
		0x00,		// BANK NUM
		0x00,		// PROGRAM NUM
	};
	
	
	Byte termination[] ={ 0xF7 };
	
	NSMutableData * toSend = [[NSMutableData alloc] initWithLength:0];
	
	header[5] = bankNumber;
	header[6] = programNumber;
	
	
	// copy header to send buffer
	[toSend appendBytes: header length: 7];
	
	// append packed program data
	[toSend appendData: [(AProgram*)program data]];
	
	// copy header to send buffer
	[toSend appendBytes: termination length: 1];
	
	NSLog(@"Sending %@ at pn %d and bn %d of length %d.", [(AProgram*)program name], programNumber, bankNumber, [toSend length]);
	NSAssert([toSend length] == 2345, @"AlesisAndromeda: sendProgramDump: toSend length wrong!");
	
	[toSend autorelease];
	
	return toSend;
	
}

- (void) sendProgramDumpToEditBuffer: (id) program
{

	Byte header[]= {	0xF0,		// SYSEX MESSAGE START
						PCM91_SYSEX_LEXICON_ID,
						PCM91_SYSEX_PCM91_ID,		
						PCM91_DEVICE_ID,
						PCM91_OPCODE_SINGLE_EFFECT_DUMP,
						0x00,		// BANK NUM
						0x00,		// PROGRAM NUM
					};
					
						
	Byte termination[] ={ 0xF7 };
	
	NSMutableData * toSend = [[NSMutableData alloc] initWithLength:0];
	
	header[5] = 0x7f;
	header[6] = 0x7f;
	
	
	// copy header to send buffer
	[toSend appendBytes: header length: 7];
	
	// append packed program data
	[toSend appendData: [(AProgram*)program data]];

	// copy header to send buffer
	[toSend appendBytes: termination length: 1];
	
	NSAssert([toSend length] == 2345, @"AlesisAndromeda: sendProgramDump: toSend length wrong!");
	
	[midi sendLongSysex: (Byte*)[toSend bytes] size: [toSend length]];
	
	[toSend release];

}


@end
