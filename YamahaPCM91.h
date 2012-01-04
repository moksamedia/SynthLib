//
//  YamahaPCM91.h
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

#import <Cocoa/Cocoa.h>
#import "ASynth.h"
#import "YamahaPCM91Program.h"

enum 
{
	PCM91_NUMBER_OF_BANKS = 11,
	PCM91_NUM_PROGRAMS_PER_BANK = 50
};

enum
{
	PCM91_PROGRAM_NAME_OFFSET			= 5,
	PCM91_PROGRAM_NAME_LENGTH			= 12
};

enum
{
	PCM91_USER_BANK_1					= 9,
	PCM91_USER_BANK_2					= 10
};

// received message opcodes
enum
{	
	PCM91_OPCODE_SINGLE_EFFECT_DUMP = 0x02,
	PCM91_OPCODE_BANK_DUMP			= 0x01
};

enum
{
	PCM91_SYSEX_REQUEST_SIZE			= 12,		// PCM91 request size is a constant length
	PCM91_SYSEX_LEXICON_ID				= 0x06,
	PCM91_SYSEX_PCM91_ID				= 0x11,
	PCM91_SYSEX_DATA_REQUEST			= 0x7f,
	PCM91_SYSEX_PROGRAM_DUMP_REQUEST	= 0x02,
	PCM91_SYSEX_BANK_DUMP_REQUEST		= 0x01,
	PCM91_DEVICE_ID						= 0x00,
	PCM91_PROGRAM_DUMP_LENGTH			= 2345,
	PCM91_BANK_DUMP_LENGTH				= 116919
};



@interface YamahaPCM91 : ASynth 
{

}

// called by the associated midi object when a complete sysex message is received
- (int) receiveSysexMessage: (NSMutableData *) data;
- (int) tryImportData: (NSMutableData*) dataToImport forCollection: (ACollection*) collection;

// Sysex data request methods
- (void) requestProgramDump: (int) programNumber bankNumber: (int) bankNumber forCollection: (ACollection*) collection;
- (void) requestProgramEditBufferDumpForCollection: (ACollection*) collection;
- (void) requestProgramBankDump: (int) bankNumber forCollection: (ACollection*) collection;

- (void) sendProgramDump: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;
- (void) sendProgramDumpToEditBuffer: (id) program;
- (NSData*) prepareProgramToSend: (id) program programNumber: (int) programNumber bankNumber: (int) bankNumber;

@end
