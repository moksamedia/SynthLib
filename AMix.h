//
//  AMix.h
//  SynthLib
//
//  Created by Andrew Hughes on 1/29/09.
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
#import "ACollectionItem.h"

@interface AMix : ACollectionItem
{
	int programNumber, bankNumber;
	int numberOfPrograms, numberOfBanks; // THESE VALUES MUST BE SET BY THE SUBLASS
}

- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data;

- (int) bankNumber;
- (BOOL) setBankNumber: (int) i;
- (BOOL) trySetBankNumber: (int) i;

- (int) programNumber;
- (BOOL) setProgramNumber: (int) i;
- (BOOL) trySetProgramNumber: (int) i;

//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS REQUIRED TO IMPLEMENT IN SUBCLASS

- (void) sendToSynthAtProgramNumber: (int) pn bankNumber: (int) bn;
- (void) sendSelectedInSynth;

@end
