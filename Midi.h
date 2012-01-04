//
//  Midi.h
//  SynthLib
//
//  Created by Andrew Hughes on 11/23/08.
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
#import <CoreMidi/MidiServices.h>

typedef struct PendingPacketList {
    void *readProcRefCon;
    void *srcConnRefCon;
    MIDIPacketList packetList;
} PendingPacketList;

bool sysexInProgressFlag;

@interface Midi : NSObject {

	int inputPort;
	int outputPort;
	int deviceID;
	id synth;
	
	BOOL connected;


	MIDIClientRef MIDIClient;
	MIDIPortRef MIDIInPort;
	MIDIPortRef MIDIOutPort;
	MIDIEndpointRef MIDIInputEndPoint;
	MIDIEndpointRef MIDIOutputEndPoint;
	
	NSMutableData * incomingData;  // buffer that holds the incoming packets as they are accrued until F7 is received
								   // once the complete message is received, the midi object sends the data to the requesting synth object
	
}

// Create a midi object for a given port and device ID configureation
// in and out port passed in here are 1-indexed (ie, port 1 is port 1 and NOT port 0)
- (id)initWithInputPort: (int) _inputPort outputPort: (int) _outputPort deviceID: (int) _deviceID synth: (id) _synth;

// request a dump from synth - this clears the incoming buffer prior to sending request
- (void) sendSysexRequest: (Byte*) shortSysex size: (int) size;
- (void) prepareForIncomingSysex;

// send short and long sysex messages
-(void)sendShortSysex: (Byte*) shortSysex size: (int) size;
-(void)sendLongSysex: (Byte*) longSysex size: (int) size;


@end
