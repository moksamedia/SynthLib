//
//  ASynth.m
//  SynthLib
//
//  Created by Andrew Hughes on 11/24/08.
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

#import "ASynth.h"
#import "SynthLib.h"

@implementation ASynth

+ (NSString*) synthStringForType: (int) i
{
	switch (i)  // row index is 0-indexed, synths are 1-indexed
	{
		case SYNTH_ANDROMEDA:
			return ANDROMEDA_STRING_VALUE;
			break;
		case SYNTH_PCM91:
			return PCM91_STRING_VALUE;
			break;
		case SYNTH_SUPERNOVA:
			return SUPERNOVA_STRING_VALUE;
			break;
		case SYNTH_WALDORFQ:
			return WALDORFQ_STRING_VALUE;
			break;
	}
	
	// just to get rid of warning
	NSAssert(true, @"This shouldn't happen!");
	return nil;
}

- (id)initWithInputPort: (int) _inputPort outputPort: (int) _outputPort
{

	if ((self = [super init]))
	{

		midi = nil;

		inputPort = _inputPort;
		outputPort = _outputPort;
		
		requestingCollection = nil;
		
		synthType = -1;
		
		NSLog(@"inputPort = %d, outputPort = %d", inputPort, outputPort);
		
		NSAssert(inputPort >= 0 && outputPort >= 0, @"ASynth - Invalid input or output port (less than zero)!");
		
		deviceID = 0;
	}
	return self;
	
}

- (void) dealloc
{
	[midi release];
	[super dealloc];
}

- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeInt: inputPort forKey:@"inputPort"];
	[coder encodeInt: outputPort forKey:@"outputPort"];
	return;
}

- (id)initWithCoder: (NSCoder *) coder
{
	inputPort = [coder decodeIntForKey:@"inputPort"];
	outputPort = [coder decodeIntForKey:@"outputPort"];	

	deviceID = 0;

	return self;
}

// Create the Midi object for the given port configuration
- (BOOL)createMidi
{
	midi = [[Midi alloc] initWithInputPort: inputPort outputPort: outputPort deviceID: deviceID synth: self];
	
	if (midi != nil) return TRUE;
	else return FALSE;
}

// get the port data
- (int) inputPort
{
	return inputPort;
}

- (int) outputPort
{
	return outputPort;
}

// used by table view for sorting by synth type
- (NSComparisonResult) compare: (ASynth*) aSynth
{
	return [[self name] compare:[aSynth name]];
}

- (int) synthType
{
	return synthType;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS

- (NSString*) name
{
	NSAssert(true, @"Subclass must override methods!");
	return nil;
}

- (int) tryImportData: (NSData*) dataToImport forCollection: (ACollection*) collection
{
	NSAssert(true, @"Subclass must override methods!");
	return -1;
}

- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{
	NSAssert(true, @"Subclass must override methods!");
	return nil;
}

- (int) receiveSysexMessage: (NSData *) data
{
	NSAssert(true, @"Subclass must override methods!");
	return -1;
}

- (BOOL) checkMatchForSynthFactory: (int) synthType inPort: (int) inPort outPort: (int) outPort
{
	NSAssert(true, @"Subclass must override methods!");
	return false;
}

- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber
{
	NSAssert(true, @"Subclass must override methods!");
}




@end
