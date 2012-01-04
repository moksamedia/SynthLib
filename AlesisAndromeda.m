//
//  AlesisAndromeda.m
//  SynthLib
//
//  Created by Andrew Hughes on 11/25/08.
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

#import "AlesisAndromeda.h"
#import "AProgram.h"
#import "ACollectionItem.h"
#import "AndromedaProgram.h"
#import "AndromedaMix.h"

@implementation AlesisAndromeda

- (id)initWithInputPort: (int) _inputPort outputPort: (int) _outputPort
{

	if ((self = [super initWithInputPort:_inputPort outputPort:_outputPort]))
	{
		synthType = SYNTH_ANDROMEDA;

	}
	return self;
	
}

- (NSString*) name
{
	return ANDROMEDA_STRING_VALUE;
}


// Used by SynthFactory object to see if already existing synth is a match for a synth requested to be created
// because the synths with a given port configuration should be singletons 
- (BOOL) checkMatchForSynthFactory: (int) _synthType inPort: (int) inPort outPort: (int) outPort
{
	if (_synthType == SYNTH_ANDROMEDA && inPort == inputPort && outPort == outputPort) return TRUE;
	else return FALSE;
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TRY IMPORT
// - called by SynthLib (document) to try and import a loaded sysex file.  returns -1 if the import is unrecognized
//   otherwise returns the length of the 'accepted' data and adds the new item to the receiving collection

- (int) tryImportData: (NSMutableData*) dataToImport forCollection: (ACollection*) collection
{
	requestingCollection = collection;
	return [self receiveSysexMessage: dataToImport];
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Recieve sysex messages from associated Midi object

-(int) receiveSysexMessage: (NSMutableData *) data
{

	Byte header[10];
	[data getBytes: header range: NSMakeRange(0, 10)];
	Byte opcode = header[5];
	
	// check to makes sure this is an Andromeda Program
	if (header[0] != 0xF0 || header[1] != 0x00 || header[2] != 0x00 || header[3] != 0x0E || header[4] != 0x1D)
	{
		NSLog(!"AndromedaSynth: Attempting to receive sysex that is not proprerly formed or is not andromeda message."); 
		return -1;
	}
	
	// check to see what type of message it is
	if (opcode == 0x00) // program dump
	{
		NSLog(@"Program dump received of length %d.", [data length]);
		
		// create a data object to hold the program data
		NSMutableData * dataBytes = [[NSMutableData alloc] initWithLength:A6_PROGRAM_DATA_LENGTH]; 
		
		// copy the program data (minus the header and the terminal F7) to the new data object
		[data getBytes: [dataBytes mutableBytes] range: NSMakeRange(A6_PROGRAM_DUMP_HEADER_LENGTH, A6_PROGRAM_DATA_LENGTH)];
		
		// create a new program
		AndromedaProgram * newProgram = [[AndromedaProgram alloc] initWithSynth: self data: [dataBytes mutableCopy]];
		
		// set the bank and program numbers
		[newProgram setBankNumber: header[6]];
		[newProgram setProgramNumber: header[7]];
		
		// add the program to the requesting collection
		[requestingCollection addItemAtSelectedRow: newProgram];
		
		[newProgram autorelease];
		[dataBytes autorelease];
		
		// remove the bytes from the data object (in case this is an import with multiple 
		//int remainder = [data length] - A6_PROGRAM_DUMP_LENGTH;
		//[data setData: [data subdataWithRange: NSMakeRange(A6_PROGRAM_DUMP_LENGTH, remainder)]];
		
		return A6_PROGRAM_DUMP_LENGTH;
	}
	else if (opcode == 0x02)  // edit buffer dump
	{
		NSLog(@"Edit Buffer dump received.");
		
		NSMutableData * dataBytes = [[NSMutableData alloc] initWithLength:A6_EDIT_BUFFER_DUMP_LENGTH];
		
		[data getBytes: [dataBytes mutableBytes] range: NSMakeRange(A6_EDIT_BUFFER_DUMP_HEADER_LENGTH, A6_PROGRAM_DATA_LENGTH)];
		
		AndromedaProgram * newProgram = [[AndromedaProgram alloc] initWithSynth: self data: [dataBytes mutableCopy]];
		
		[newProgram setBankNumber: 0];
		[newProgram setProgramNumber: 0];
		
		[requestingCollection addItemAtSelectedRow: newProgram];
		
		[newProgram autorelease];
		[dataBytes autorelease];
		
		return A6_EDIT_BUFFER_DUMP_LENGTH;

		//int remainder = [data length] - A6_EDIT_BUFFER_DUMP_LENGTH;
		//[data setData: [data subdataWithRange: NSMakeRange(A6_EDIT_BUFFER_DUMP_LENGTH, remainder)]];
	}
	else if (opcode == 0x04)  // mix dump
	{
		NSLog(@"Mix dump received.");
		
		NSMutableData * dataBytes = [[NSMutableData alloc] initWithLength:A6_MIX_DUMP_LENGTH];
		
		[data getBytes: [dataBytes mutableBytes] range: NSMakeRange(A6_MIX_DUMP_HEADER_LENGTH, A6_MIX_DATA_LENGTH)];
		
		AndromedaMix * newMix = [[AndromedaMix alloc] initWithSynth: self data: [dataBytes mutableCopy]];
				
		[requestingCollection addItemAtSelectedRow: newMix];
		
		[newMix autorelease];
		[dataBytes autorelease];
		
		return A6_MIX_DUMP_LENGTH;
		
	}
	else
	{
		return -1;
	}

}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PROGRAM SEND

// main program send function
- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{
	NSData * toSend;

	NSAssert([program isMemberOfClass: [AndromedaProgram class]], @"Trying to send wrong program type!");
	NSAssert(programNumber >= 0 && programNumber <= 127, @"AlesisAndromeda: sendProgramDump: patchNumber out of bounds!");
	NSAssert(bankNumber == 0, @"AlesisAndromeda: sendProgramDump: bankNumber out of bounds!");
	
	toSend = [self prepareProgramToSend: (AProgram*)program programNumber: programNumber bankNumber: bankNumber]; 
	
	[toSend retain];
	
	[midi sendLongSysex: (Byte*)[toSend bytes] size: [toSend length]];
	
	[toSend release];
	
}

// helper function that adds the header and footer
- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{
	NSLog(@"Preparing program to send %@ at pn %d and bn %d.", [program name], programNumber, bankNumber);
	NSAssert(programNumber >= 0 && programNumber <= 127, @"AlesisAndromeda: sendProgramDump: patchNumber out of bounds!");
	NSAssert(bankNumber >= 0 && bankNumber <= 2, @"AlesisAndromeda: sendProgramDump: bankNumber out of bounds!");
	
	/*
	 AProgram Dump Request Message
	 bank: 0=User, 1=Preset1, 2=Preset2
	 prog: 0...127
	 */
	//				  FO	00   00   0E   1D  00 bank prog
	Byte header[]= {0xf0,0x00,0x00,0x0e,0x1d,0x00,0x00, 0x00};
	Byte termination[] ={ 0xF7 };
	
	NSMutableData * toSend = [[NSMutableData alloc] initWithLength:0];
	
	header[6] = bankNumber;
	header[7] = programNumber;
	
	
	// copy header to send buffer
	[toSend appendBytes: header length: 8];
	
	// append packed program data
	[toSend appendData: [(AProgram*)program data]];
	
	// copy header to send buffer
	[toSend appendBytes: termination length: 1];
	
	NSAssert([toSend length] == 2350, @" toSend length wrong!");
	
	[toSend autorelease];
	return toSend;
}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SYSEX REQUEST MESSAGES

// Request AProgram from Andromeda
- (void)requestProgramDump: (int) programNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection
{
	
	requestingCollection = collection;
	
	NSAssert(programNumber >= 0 && programNumber <= 127, @"AlesisAndromeda: patchNumber out of bounds!");
	NSAssert(bankNumber >= 0 && bankNumber <= 2, @"AlesisAndromeda: bankNumber out of bounds!");

	/*
		AProgram Dump Request Message
		bank: 0=User, 1=Preset1, 2=Preset2
		prog: 0...127
	*/
	//				   FO	00   00   0E   1D   01 bank prog F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x01,0x00,0x00,0xf7};

	request[6] = bankNumber;
	request[7] = programNumber;

	[midi sendSysexRequest: request size: 9];

}

// Request one of the 17 edit buffers (16 for mix programs, 1 for program)
- (void)requestProgramEditBufferDump: (int) bufferNumber forCollection: (ACollection*) collection
{
	requestingCollection = collection;

	NSAssert(bufferNumber >= 0 && bufferNumber <= 16, @"AlesisAndromeda: bufferNumber out of bounds!");

	/*
		AProgram Edit Buffer Dump Request Message
		num: 0-15=mix program edit buffers for mix channels 1-16
			 16=program edit buffer
	*/
	//				   FO	00   00   0E   1D   03  num   F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x03,0x00,0xf7};

	request[6] = bufferNumber;

	[midi sendSysexRequest: request size: 8];
}

// Request program bank
- (void)requestProgramBankDump: (int) bankNumber forCollection: (ACollection*) collection
{
	requestingCollection = collection;

	NSAssert(bankNumber >= 0 && bankNumber <= 2, @"AlesisAndromeda: bankNumber out of bounds!");

	/*
		AProgram Bank Dump Request Message
		num: 0=user, 1=preset1, 2=preset2
	*/
	//				   FO   00   00   0E   1D   0A num  F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x0a,0x00,0xf7};

	request[6] = bankNumber;

	[midi sendSysexRequest: request size: 8];
}

// Request mix
- (void)requestMixDump: (int) mixNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection
{
	NSAssert(mixNumber >= 0 && mixNumber <= 127, @"AlesisAndromeda: mixNumber out of bounds!");
	NSAssert(bankNumber >= 0 && bankNumber <= 2, @"AlesisAndromeda: bankNumber out of bounds!");

	requestingCollection = collection;

	/*
		Mix Dump Request Message
		bank: 0=User, 1=Preset1, 2=Preset2
		mix: 0...127
	*/
	//						  FO   00   00   0E   1D   05 bank mix  F7
	Byte mixDumpRequest[]= {0xf0,0x00,0x00,0x0e,0x1d,0x05,0x00,0x00,0xf7};

	mixDumpRequest[6] = bankNumber;
	mixDumpRequest[7] = mixNumber;

	[midi sendSysexRequest: mixDumpRequest size: 9];

}

// Request mix edit buffer
- (void)requestMixEditBufferDumpForCollection: (ACollection*) collection
{
	requestingCollection = collection;

	//				   FO	00   00   0E   1D   07   00   F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x07,0x00,0xf7};

	[midi sendSysexRequest: request size: 8];

}

// Request mix bank
- (void)requestMixBankDump: (int) bankNumber forCollection: (ACollection*) collection
{
	NSAssert(bankNumber >= 0 && bankNumber <= 1, @"AlesisAndromeda: bankNumber out of bounds!");

	requestingCollection = collection;

	/*
		Mix Bank Dump Request Message
		num: 0=user, 1=preset1
	*/
	//				   FO   00   00   0E   1D   0B num  F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x0b,0x00,0xf7};

	request[6] = bankNumber;

	[midi sendSysexRequest: request size: 8];
}

// Request global data dump
- (void)requestGlobalDataDumpForCollection: (ACollection*) collection
{
	requestingCollection = collection;

	//				   FO	00   00   0E   1D   09   00   F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x09,0x00,0xf7};

	[midi sendSysexRequest: request size: 8];

}

// Request to dump all: User programs, user mixes, and global data
-(void)requestAllDumpForCollection: (ACollection*) collection
{
	requestingCollection = collection;

	//				   FO	00   00   0E   1D   0C   00   F7
	Byte request[]= {0xf0,0x00,0x00,0x0e,0x1d,0x0c,0x00,0xf7};

	[midi sendSysexRequest: request size: 8];

}

@end
