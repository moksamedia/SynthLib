//
//  MyDocument.h
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

/*
	TODO:
		- implement edit multiple selections (ie, so I can change banks all at once)
		- implement the select item function.  send program change and bank change.
		- implement a preview function (send and select and play note or midi sequence)
 */
#import <Cocoa/Cocoa.h>
#import <CoreMidi/MidiServices.h>
#import "Midi.h"
#import "ASynth.h"
#import "TableDataSource.h"
#import "ACollection.h"
#import "MyTableView.h"
#import "Definitions.h"


// drag and drop data type
#define SynthProgramTableViewDataType @"SynthProgramTableViewDataType"


@interface SynthLib : NSDocument
{
	ASynth * andromeda;
	ASynth* pcm91;
	NSMutableArray * theInstalledSynths;
	
	TableDataSource * tableDataSource;
	ACollection * mainCollection;	// main data sturcture: holds the synth programs (patches) that are shown in the table vie
	
	NSUndoManager * undoManager;
	
	NSNumberFormatter * numberFormatter;
	
	BOOL loadFromFileFlag;

	IBOutlet MyTableView * tableView;	// main table view in window
	
	// ANDROMEDA
	IBOutlet NSComboBox * andromedaBankSelectComboBox; // for get button
	IBOutlet NSComboBox * andromedaProgramSelectComboBox; // for get button
	IBOutlet NSComboBox * andromedaSendProgramSelectComboBox;  // for send button
	
	// PCM91
	IBOutlet NSComboBox * pcm91SendBankSelectComboBox;
	IBOutlet NSComboBox * pcm91BankSelectComboBox; // for get button
	IBOutlet NSComboBox * pcm91ProgramSelectComboBox; // for get button
	IBOutlet NSComboBox * pcm91SendProgramSelectComboBox;  // for send button
	
	IBOutlet NSTabView * synthSelectTabView;	// tabless tabbed view used swap between controls for diff synths
	
	IBOutlet NSComboBox * synthSelectComboBox;
	IBOutlet NSButton * filterTableActiveSynthCheckBox; // when checked, the table view is filtered by the active synth (ie, only shows programs of the active synth)

	// Edit Multiple Selection Outlets (ems)
	IBOutlet NSTextField * emsNameTextField;
	IBOutlet NSTextField * emsCommentsTextField;
	IBOutlet NSTextField * emsProgramNumberTextField;
	IBOutlet NSTextField * emsBankNumberTextField;
	IBOutlet NSWindow * emsWindow;
	
}

// UTILITY FUNCTIONS
- (BOOL) checkNoSelectionWithMessage: (NSString*) message;
- (NSArray*) getItemsSelectedInTableView;
- (void) setUndoPoint;

// MODIFY COLLECTION METHODS
- (void) deleteItems: (NSArray*) itemsToDelete;
- (IBAction) deleteSelectedItems: (id) sender;

- (void) addItemsToCollection: (NSArray*) itemsToAdd;
- (void) addItemsToCollection: (NSArray*) itemsToAdd atIndex: (int) index;

- (void) setValueForIdentifier: (NSString*) identifier row: (int) rowIndex objectValue: (id) anObject collection: (ACollection*) collection;
- (void) setTheCollection: (NSArray*) newCollection hiddenCollection: (NSArray*) hiddenCollection forCollection: (ACollection*) aCollection;

// ANDROMEDA FUNCTIONS
- (IBAction) andromedaGetProgram: (id) sender;	// gets a program from the synth
- (IBAction) andromedaGetProgramEditBuffer: (id) sender;  // short cut to get the edit buffer from the synth
- (IBAction) andromedaSendProgram: (id) sender;  // sends a program to the synth, can select edit buffer
- (IBAction) andromedaGetProgramSelectComboBoxChange: (id) sender;
- (IBAction) andromedaSendProgramSelectComboBoxChange: (id) sender;

// PCM91 FUNCTIONS
- (IBAction) pcm91GetProgram: (id) sender;
- (IBAction) pcm91GetProgramEditBuffer: (id) sender;  // short cut to get the edit buffer from the synth
- (IBAction) pcm91SendProgram: (id) sender;  // sends a program to the synth, can select edit buffer
- (IBAction) pcm91GetProgramSelectComboBoxChange: (id) sender;
- (IBAction) pcm91SendProgramSelectComboBoxChange: (id) sender;
- (IBAction) pcm91GetProgramEditBuffer: (id) sender;

// ACTIVE SYNTH FUNCTIONS
- (IBAction) activeSynthDidChange: (id) sender;
- (ASynth*) activeSynth;
- (IBAction) activeSynthFilterButtonClicked: (id) sender;

- (IBAction) sendSelectedToStoredValues: (id) sender;

// EXPORT AND IMPORT SYSEX FILES
- (IBAction) exportFilesToSysex: (id) sender;
- (IBAction) importFilesFromSysex: (id) sender;

// sends a program change to the selected item's synth, telling it to change to the selected item's program number and bank number
- (IBAction) selectSelection: (id) synth;

// Edit Multiple Selection
- (IBAction) emsOKClicked: (id) sender;
- (IBAction) emsCancelClicked: (id) sender;
- (IBAction) editMultipleSelection: (id)sender;

- (IBAction) midiSetup: (id) sender;
- (void) midiSetupFinished: (id) sender;


@end
