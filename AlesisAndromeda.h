//
//  AlesisAndromeda.h
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

#import <Cocoa/Cocoa.h>
#import "SynthLib.h"
#import "ASynth.h"

enum
{
	ANDROMEDA_USER_BANK				=	0,
	ANDROMEDA_PRESET1_BANK			=	1,
	ANDROMEDA_PRESET2_BANK			=	2,
	ANDROMEDA_NUMBER_OF_BANKS		=	3,
	ANDROMEDA_NUM_PROGRAMS_PER_BANK =	128
};

enum  
{
	A6_PROGRAM_DUMP_LENGTH				= 2350,	// number of packed data bytes (ie, as sent) with header and footer
	A6_PROGRAM_DUMP_HEADER_LENGTH		= 8,
	A6_PROGRAM_DATA_LENGTH				= 2341,    // 2341 = 2350 (program length) - 8 (header length) - 1 (termination byte)

	A6_EDIT_BUFFER_DUMP_LENGTH			= 2349,
	A6_EDIT_BUFFER_DUMP_HEADER_LENGTH	= 7,

	A6_MIX_DUMP_LENGTH					= 1180,
	A6_MIX_DATA_LENGTH					= 1171,
	A6_MIX_DUMP_HEADER_LENGTH			= 8
};

@interface AlesisAndromeda : ASynth {

}
// called by the associated midi object when a complete sysex message is received
- (int) receiveSysexMessage: (NSMutableData *) data;
- (int) tryImportData: (NSMutableData*) dataToImport forCollection: (ACollection*) collection;

// Sysex data request methods
- (void)requestProgramDump: (int) programNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection;
- (void)requestProgramEditBufferDump: (int) bufferNumber forCollection: (ACollection*) collection;
- (void)requestProgramBankDump: (int) bankNumber forCollection: (ACollection*) collection;
- (void)requestMixDump: (int) mixNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection;
- (void)requestMixEditBufferDumpForCollection: (ACollection*) collection;
- (void)requestMixBankDump: (int) bankNumber forCollection: (ACollection*) collection;
- (void)requestGlobalDataDumpForCollection: (ACollection*) collection;
- (void)requestAllDumpForCollection: (ACollection*) collection;

- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;
- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;

@end
