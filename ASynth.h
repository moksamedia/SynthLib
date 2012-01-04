//
//  ASynth.h
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

#import <Cocoa/Cocoa.h>
#import "Midi.h"
#import "ACollection.h"

/*
	Data:
		Port, Channel, DeviceID
	
	Functions:
		Request Patch Dump
		Request Bank Dump
		Send Patch
		Send Patches
		Send Bank
		

*/


@interface ASynth : NSObject {

	int inputPort, outputPort, deviceID;
	
	// The midi object associated with the synth, created by the synth object using the port data
	Midi * midi;
	
	// The collection for which the current incoming sysex data is intended for.  Passed in
	// when a sysex request is made
	ACollection * requestingCollection;
	
	// Type of synth, ie: Andromeda, PCM91, Moog, etc...
	int synthType;

}

// returns the string value for a synth given its type (as both defined in Definitions.h)
+ (NSString*) synthStringForType: (int) i;

- (id) initWithInputPort: (int) _inputPort outputPort: (int) _outputPort;

- (BOOL) createMidi;  // creates the midi object for the given port configuration

- (NSComparisonResult) compare: (ASynth*) aSynth;

- (int) inputPort;
- (int) outputPort;


//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS

// the name of the synth as a string
- (NSString*) name;

- (int) synthType;

// attempts to import data (loaded from sysex file in SynthLib)
- (int) tryImportData: (NSData*) dataToImport forCollection: (ACollection*) collection;

// receives a sysex message from the Midi class
- (int) receiveSysexMessage: (NSData *) data;

// Send program and helper method
- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;
- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;

// used by Synth factory to see if synth is of type and port configuration needed (should only be one synth with given port configuration)
- (BOOL) checkMatchForSynthFactory: (int) _synthType inPort: (int) inPort outPort: (int) outPort;


@end
