//
//  Midi.m
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

#define INPUT_PORT 0
#define OUTPUT_PORT 0

#import "Midi.h"
#import "ASynth.h"

@implementation Midi

// Midi input callback (specified in init method when MIDIInputPortCreate is called
static void MidiReadProc(const MIDIPacketList *packetList, void *readProcRefCon, void *srcConnRefCon)
{
    const MIDIPacket *packet;
    int i;
    NSMutableData *data;
    	
	// Find the size of the whole packet list
	packet = &packetList->packet[0];
	
	// if sysex is in progress or we are recieving a new sysex message
	if (sysexInProgressFlag == TRUE || packet->data[0] == 0xF0)
	{
	
		if (packet->data[0] == 0xF0)
		{
	
			// need this in case old transmission wasn't terminated and hung, this clears the instance object's incoming buffer (incomingData)
			//[(id) srcConnRefCon performSelectorOnMainThread:@selector(startNewIncomingSysex) withObject:nil waitUntilDone:NO];
		
			// need this becuase once initial 0xF0 is recieved, we need to know that we are in the middle of recieving
			// a stream of sysex data
			sysexInProgressFlag = TRUE;
		}
		
		// initialize new data object to hold packet data
		data = [[NSMutableData alloc] initWithLength:0];
		
		for (i = 0; i < packetList->numPackets; i++) 
		{			
			// append packet data to data object
			[data appendBytes: packet->data length: packet->length];
			
			// macro to get next packet
			packet = MIDIPacketNext(packet);
		}
							
		
		//NSLog(@"PacketListSize = %d, NumPackets = %d", packetListSize, packetList->numPackets);
		
		
		/*
			This pushes the incoming packets (now copied into NSData data) to an instance method of the synth's midi object.  This allows each synth
			to deal with their own incoming sysex stream.
			
			Also, below, we check the last byte of the last package to see if the 0xF7 sysex termination message is recieved.  If so, processFinalMidiPackets
			is called instead of processMidiPackets.
		*/
		
		// get the last midi packet
		const MIDIPacket * lastPacket = &packetList->packet[(packetList->numPackets - 1)];
		// if the last byte of the last packet is equal to F7, this should be the last packet in the message
		if ( lastPacket->data[(lastPacket->length - 1)] == 0xF7 )
		{
			[(id) srcConnRefCon performSelectorOnMainThread:@selector(processFinalMidiPackets:) withObject:data waitUntilDone:NO];
			sysexInProgressFlag = FALSE;		
		}
		else
		{
			// srcConnRefCon is the instance of the Midi class that set up the input connection, this allows the callback
			// to route the incoming packets to the proper Midi object (Andro vs Moog vs FS1r)
			[(id) srcConnRefCon performSelectorOnMainThread:@selector(processMidiPackets:) withObject:data waitUntilDone:NO];
		}
		
		[data release];
		
	}
}

/*
	Need to implement returning nil if failure to connect.
*/
- (id)initWithInputPort: (int) _inputPort outputPort: (int) _outputPort deviceID: (int) _deviceID synth: (id) _synth
{
	
	if ((self = [super init])) {// superclass may return nil
	
		connected = FALSE;
	
		synth = _synth;
		inputPort = _inputPort - 1;		// convert from 1-indexed used by software to zero-indexed used by driver
		outputPort = _outputPort - 1;
		deviceID = _deviceID;
		
		NSAssert(inputPort >=0 && outputPort >=0 && deviceID >= 0, @"Improper inputPort, outputPort, or deviceID!");

		NSLog(@"Creating midi client.");

		// Create Midi Client
		MIDIClientCreate(CFSTR("SynthLib Client"), NULL, NULL, &MIDIClient);
				
		NSLog(@"Creating midi ports.");

		// Create Midi Ports
		MIDIOutputPortCreate(MIDIClient, CFSTR("MIDI Output port"), &MIDIOutPort);
		MIDIInputPortCreate(MIDIClient, CFSTR("MIDI Input port"), MidiReadProc, self, &MIDIInPort);
		
		// Get number of sources and destinations
		int InCount = MIDIGetNumberOfSources();
		int OutCount = MIDIGetNumberOfDestinations();

		// Insure that Midi Device is connected
		if(InCount == 0 || OutCount == 0)
		{
			NSRunAlertPanel(@"SynthLib",
							@"MIDI device is not found!",
							@"OK",NULL,NULL);
			//[NSApp terminate:self];
			connected = FALSE;
		}
		else
		{
			NSLog(@"Creating midi endpoints.");

			// Create Midi Endpoints
			MIDIInputEndPoint   = MIDIGetSource(inputPort);
			MIDIOutputEndPoint  = MIDIGetDestination(outputPort);

			NSLog(@"Connecting in port to input end point.");
			
			// Connect "In Port" to "Input End Point"
			MIDIPortConnectSource(MIDIInPort, MIDIInputEndPoint, self);
			connected = TRUE;
		}
		// Used by MidiReadProc to process incoming sysex streams
		
		incomingData = nil;
		sysexInProgressFlag = FALSE;

	}
    return self;
}

- (void) dealloc
{
	MIDIClientDispose(MIDIClient);
	[super dealloc];
}


// Instance method called by midi callback to deal with midi packets as they are recieved
-(void)processMidiPackets: (NSData*) data
{
	[data retain];
	
	// If incomingData is uninitialized (first packet on this incoming sysex message), create a new data object
	// with the contents of the first packet
	if (incomingData == nil)
	{
		incomingData = [[NSMutableData dataWithData: data] retain];
	}
	// incomingData is not nil, thus we are in the middle of recieving a message, so append the new packet
	else
	{
		[incomingData appendData: data];
	}
	
	//NSLog(@"Recieveing Data on port %d of size %d.", inputPort, [data length]);

	[data release];
}

// Instance method called by midi callback when LAST packet is recieved to deal with midi packets
-(void)processFinalMidiPackets: (NSData*) data
{
	[data retain];
	
	// If incomingData is uninitialized (first packet on this incoming sysex message), create a new data object
	// with the contents of the first packet
	if (incomingData == nil)
	{
		incomingData = [NSMutableData dataWithData: data];
	}
	// incomingData is not nil, thus we are in the middle of recieving a message, so append the new packet
	else
	{
		[incomingData appendData: data];
	}
	
	NSLog(@"%d bytes recieved on port %d.", [incomingData length], inputPort);
	
	[synth receiveSysexMessage: [incomingData mutableCopy]];
	
	[incomingData release];
	incomingData = nil;

	[data release];
}

// Requests for patches should call this because it clears the incoming data buffer (incomingData) in case the previous request
// was not fulfilled and finished for some reason
- (void) sendSysexRequest: (Byte*) shortSysex size: (int) size
{
	// if we are not connected, then ignore all requests to send
	if (!connected) return;
	
	[self prepareForIncomingSysex];
	[self sendShortSysex: shortSysex size: size];
}

- (void) prepareForIncomingSysex
{
	[incomingData release];
	incomingData = nil;
}

-(void)sendShortSysex: (Byte*) shortSysex size: (int) size
{
	// if we are not connected, then ignore all requests to send
	if (!connected) return;

	NSLog(@"Sending %d bytes on port %d.", size, outputPort);
	Byte *sysex = shortSysex;
	MIDIPacket *Packet;
	MIDIPacketList PacketList;
	MIDITimeStamp NowTime;
	NowTime = 0; // Zero means Now
	Packet = MIDIPacketListInit(&PacketList);
	Packet = MIDIPacketListAdd(&PacketList, sizeof(PacketList), Packet, NowTime, size, sysex);
	MIDISend(MIDIOutPort, MIDIOutputEndPoint, &PacketList);
}

- (void)sendLongSysex: (Byte*) longSysex size: (int) size
{
	// if we are not connected, then ignore all requests to send
	if (!connected) return;

	MIDISysexSendRequest SendRequest;

	SendRequest.destination = MIDIOutputEndPoint;
	SendRequest.data = longSysex;
	SendRequest.bytesToSend = size;
	SendRequest.complete = FALSE;
	SendRequest.completionProc = NULL;
	SendRequest.completionRefCon = NULL;
		
	MIDISendSysex(&SendRequest);
	
	// waits until processing finishes.
	while (SendRequest.complete != TRUE){
		usleep(10000);
	}
	
	NSLog(@"Done sending.");

}



@end
