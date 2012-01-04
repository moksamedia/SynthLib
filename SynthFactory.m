//
//  SynthFactory.m
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

#import "SynthFactory.h"
#import "ASynth.h"
#import "AlesisAndromeda.h"
#import "YamahaPCM91.h"

/*
	I needed this to fix a problem.  When I opened more than one document and tried to get programs from the synth, the programs always
	went to the first-opened document.  This happened because the first document opened the midi port first.  The solution was to
	create a factory that allowed the creation of only one of each synth/port combination.  Thus here, there can only be one Andromeda on inPort 1
	and outPort 1.  There can be multiple andromeda's - if they are on different ports.
	
	The factory iteself is implemented as a singleton.
*/

@implementation SynthFactory

static SynthFactory *sharedSynthFactory = nil;
 
+ (SynthFactory*)sharedSynthFactory
{
    @synchronized(self) 
	{
        if (sharedSynthFactory == nil) 
		{
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedSynthFactory;
}
 
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedSynthFactory == nil) {
            sharedSynthFactory = [super allocWithZone:zone];
            return sharedSynthFactory;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
 
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}
 
- (void)release
{
    //do nothing
}
 
- (id)autorelease
{
    return self;
}

- (id) init
{
	if ((self = [super init]))
	{
		synths = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) terminate
{
	NSLog(@"Terminating");
	[synths removeAllObjects];
	[synths release];
}

// checks the array of already created synth objects (synths) and returns the synth that matched the requested type and port config,
// returning nil if a synth that hasn't already been created is requested.
- (id) getSynth: (int) synthType inPort: (int) inPort outPort: (int) outPort
{
	int i;
	for (i=0; i<[synths count]; i++)
	{
		if ([[synths objectAtIndex: i] checkMatchForSynthFactory: synthType inPort: inPort outPort: outPort]) return [synths objectAtIndex:i];
	}
	
	NSAssert(true, @"This shouldn't happen!");
	return nil;
}

// creates a synth object for a given type and port conifguration.  called by SynthLib during windowControllerDidLoadNIB.
- (id) createSynth: (int) synthType inPort: (int) inPort outPort: (int) outPort
{
	ASynth * newSynth;
	
	if (synthType == SYNTH_ANDROMEDA)
	{
		newSynth = [[AlesisAndromeda alloc] initWithInputPort:inPort outputPort:outPort];
		[newSynth createMidi];
		[synths addObject: newSynth];
		[newSynth release];
		return newSynth;
	}
	else if (synthType == SYNTH_PCM91)
	{
		newSynth = [[YamahaPCM91 alloc] initWithInputPort:inPort outputPort:outPort];
		[newSynth createMidi];
		[synths addObject: newSynth];
		[newSynth release];
		return newSynth;
	}
	else
	{
		NSAssert(true, @"This shouldn't happen!");
		return nil;
	}
}

@end
