//
//  ACollectionItem.h
//  SynthLib
//
//  Created by Andrew Hughes on 12/20/08.
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
#import "ASynth.h"

// for Collection Item type information
enum
{
		PROGRAM = 0,
		GLOBAL = 1,
		MIX = 2
};

@interface ACollectionItem : NSObject <NSCoding>
{

	NSMutableData * data;
	ASynth * synth;
	NSString * comments;
	NSString * comments2;
	NSString * name;
	int type; // patch type
	
	int synthType;
	int inPort;
	int outPort;
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) data type: (int) type;

// NAME
- (NSString*) name;
- (BOOL) setName: (NSString*) newName;

// COMMENTS 1
- (NSString*) comments;
- (BOOL) setComments: (NSString*) newComments;

// COMMENTS 2
- (NSString*) comments2;
- (BOOL) setComments2: (NSString*) newComments2;

// DATA
- (NSMutableData*) data;
- (BOOL) setData: (NSMutableData*) newData;

// SYNTH
- (ASynth*) synth;
- (BOOL) setSynth: (ASynth*) newSynth;

- (BOOL) shouldEditForIdentifier: (NSString*) identifier;

// Returns a string value for the type, ie: PROGRAM, GLOBAL, MIX, etc...
- (NSString*) typeString;

// returns a string for the name of the synth
- (NSString*) synthName;

//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS

// used for displaying values in table column
- (NSString*) bankName;
- (NSString*) programNumberString;

// copy
- (id) copy;
- (id) copyWithZone: (NSZone*) zone;
- (id) mutableCopy;
- (id) mutableCopyWithZone: (NSZone*) zone;

@end
