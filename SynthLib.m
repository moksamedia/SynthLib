//
//  MyDocument.m
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

#import "SynthLib.h"
#import "AlesisAndromeda.h"
#import "YamahaPCM91.h"
#import "AProgram.h"
#import "AndromedaProgram.h"
#import "YamahaPCM91Program.h"
#import "SynthFactory.h"
#import "Utility.h"
#import "Definitions.h"
#import "MidiSetup.h"

/*
	Notes: 
	- right now the program is hard-wired for just the Andromeda, and for reading and writing programs.  Need to geralize this.
	- problem with multiple documents open, all of the received programs go to the originally opened document.  Need to create
	  a SynthFactory object that gives out singleton synth/port objects.  ie, [SynthFactory get: Andromeda inPort: 2 outPort: 2],
	  and this will create it, if necessary, and check for conflicts, then give back the synth (and associated midi) objects.
*/


@implementation SynthLib

- (id)init
{
	NSLog(@"init");
    self = [super init];
    if (self) 
	{
		mainCollection = nil;
		tableDataSource = [[TableDataSource alloc] initWithDocument: self];
		loadFromFileFlag = FALSE;
		
		// Number formatter used to parse program numbers entered into combo boxes
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setFormat:@"0"];

    }
    return self;
}

- (void) dealloc
{
	[mainCollection release];
	[tableDataSource release];
	[numberFormatter release];
	[super dealloc];
}

- (NSString *)windowNibName
{
    return @"SynthLib";
}

- (void)awakeFromNib
{
	// register table view for drag and drop
	[tableView registerForDraggedTypes: [NSArray arrayWithObject: SynthProgramTableViewDataType] ];

	
	// ACTIVE SYNTH SELECT COMBO BOX

	[synthSelectComboBox removeAllItems];

	int i;
	for (i=1; i <= [MidiSetup numberOfInstalledSynths]; i++)
	{
			[synthSelectComboBox addItemWithObjectValue:[NSString stringWithFormat:@"%@  -  In: %d, Out: %d, ID: %d", 
														[ASynth synthStringForType:[MidiSetup readSynthTypeForSynthNumber:i]],
														[MidiSetup readInPortForSynthNumber:i],
														[MidiSetup readOutPortForSynthNumber:i],
														[MidiSetup readDeviceIDForSynthNumber:i]]];
			 
	}
	
	if ([MidiSetup numberOfInstalledSynths] == 0)
	{
		[synthSelectComboBox addItemWithObjectValue: PLEASE_INSTALL_STRING];
	}

	[synthSelectComboBox selectItemAtIndex:0];

	
	// ANDROMEDA PANEL
	
	// populate get button combo box for program number
	[andromedaProgramSelectComboBox removeAllItems];
	for (i=0; i<128; i++)
	{
		[andromedaProgramSelectComboBox addItemWithObjectValue: [NSString stringWithFormat: @"%d", i]];
	}
	[andromedaProgramSelectComboBox addItemWithObjectValue: @"All"];
	[andromedaProgramSelectComboBox selectItemAtIndex:0];
	[andromedaBankSelectComboBox selectItemAtIndex:0];
	
	// populate send button combo box for program number
	[andromedaSendProgramSelectComboBox removeAllItems];
	[andromedaSendProgramSelectComboBox addItemWithObjectValue: @"Stored"];
	for (i=0; i<128; i++)
	{
		[andromedaSendProgramSelectComboBox addItemWithObjectValue: [NSString stringWithFormat: @"%d", i]];
	}
	[andromedaSendProgramSelectComboBox selectItemAtIndex:0];
	
	
	// PCM91 PANEL
	
	// populate get button combo box for program number
	[pcm91ProgramSelectComboBox removeAllItems];

	for (i=0; i<50; i++)
	{
		[pcm91ProgramSelectComboBox addItemWithObjectValue: [NSString stringWithFormat: @"%d", i]];
	}
	[pcm91ProgramSelectComboBox addItemWithObjectValue: @"All"];
	[pcm91ProgramSelectComboBox selectItemAtIndex:0];
	[pcm91BankSelectComboBox selectItemAtIndex:0];
	
	// populate send button combo box for program number
	[pcm91SendProgramSelectComboBox removeAllItems];
	[pcm91SendProgramSelectComboBox addItemWithObjectValue: @"Stored"];
	for (i=0; i<50; i++)
	{
		[pcm91SendProgramSelectComboBox addItemWithObjectValue: [NSString stringWithFormat: @"%d", i]];
	}
	[pcm91SendProgramSelectComboBox selectItemAtIndex:0];

	//make sure that the right tab of controls is shown at start up
	[self activeSynthDidChange:self];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

	// setup undo manager
	undoManager = [self undoManager];
	[self setUndoManager:undoManager];
	
	
	// CREATE THE SYNTH OBJECTS FROM THE DATA STORED IN USER DEFAULTS
	
	int numberOfInstalledSynths = [MidiSetup numberOfInstalledSynths];
	theInstalledSynths = [[NSMutableArray alloc] init];

	int i;
	int inPort, outPort, synthType, deviceID;
	id aSynth;
	for (i=0; i<numberOfInstalledSynths; i++)
	{
		// read synth data from defaults
		synthType = [MidiSetup readSynthTypeForSynthNumber:i];
		inPort = [MidiSetup readInPortForSynthNumber:i];
		outPort = [MidiSetup readOutPortForSynthNumber:i];
		deviceID = [MidiSetup readDeviceIDForSynthNumber:i];
		
		// ask the SynthFactory to create the synth
		aSynth = [[SynthFactory sharedSynthFactory] createSynth: synthType inPort: inPort outPort: outPort];
		
		if (aSynth == nil)
		{
			[Utility runAlertWithMessage:[NSString stringWithFormat:@"Warning! Unable to make synth of type %@ with inPort: %d, outPort: %d, and deviceID: %d.",
										  [ASynth synthStringForType:synthType], inPort, outPort, deviceID]];
		}
			
		[theInstalledSynths addObject:aSynth];
	}
	
	//andromeda = [[SynthFactory sharedSynthFactory] getSynth: SYNTH_ANDROMEDA inPort: 2 outPort: 2];	// these port numbers are 1-indexed (not zero indexed)
	//pcm91 = [[SynthFactory sharedSynthFactory] getSynth: SYNTH_PCM91 inPort: 6 outPort: 6];
	//NSAssert (andromeda != nil, @"SynthLib: windowControllerDidLoadNib: unable to make andromeda!");
	
	
	// finish preparing the table view and data source
	
	if (!loadFromFileFlag)  // didn't load from file
	{
		mainCollection = [[ACollection alloc] initForTableView: tableView];
		[tableView setDataSource:tableDataSource];
		[tableView setDelegate: mainCollection];

	}
	else  // loaded from file
	{
		[mainCollection setTableView:tableView];	// no need to make the mainCollection because it was loaded from file
		[tableView setDataSource:tableDataSource];
		[tableView setDelegate: mainCollection];
		[tableView reloadData];
	}
	

}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSLog(@"Going to terminate.");
}

/////////////////////////////////////////////////////////////////////////////////////////
//// SAVE AND LOAD

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
  	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	data = [NSMutableData data];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

	[archiver encodeObject: mainCollection forKey:@"mainCollection"];
	
	[archiver finishEncoding];
	[archiver release];
	
	return data;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{   
	NSLog(@"loadDataRepresentation");
	NSKeyedUnarchiver *unarchiver;
	 
	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];

	mainCollection = [[unarchiver decodeObjectForKey: @"mainCollection"] retain];

 	[unarchiver finishDecoding];
	[unarchiver release]; 
	
	loadFromFileFlag = TRUE;   

	return YES;
}

/////////////////////////////////////////////////////////////////////////////////////////
//// EXPORT AND IMPORT SYSEX FILES

// Exports the selected files to Sysex files, allows user to select the destination directory
- (IBAction) exportFilesToSysex: (id) sender
{
    int result, i;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];  // panel used to select destination directory
	NSArray* selectedItems = [self getItemsSelectedInTableView];  // gets an array of the items selected in the table view
	
	NSLog (@"Exporting");
	if (![self checkNoSelectionWithMessage: @"Unable to export files: no selection!"]) return;  // if no selection, skip
	
	// configure the open panel, used to choose the destination directory
	[oPanel setCanChooseFiles: FALSE];	
	[oPanel setCanChooseDirectories: TRUE];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setTitle:@"Choose Folder"];
    [oPanel setMessage:@"Choose destination folder for export."];
    [oPanel setDelegate:self];
	
	// run the panel and get result, which we can ignore
    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];
 
	ASynth * theSynth;  // holds the synth of the current selection in the loop
	AProgram * theProgram;  // ditto for the program
	NSData * exportData;  // data to export, formatted with header and terminal 0xF7
	
	if (result == NSOKButton) 
	{
        NSArray *directoryArray = [oPanel filenames]; // the chosen directory in an array
		NSString *directoryPath = [directoryArray objectAtIndex:0];  // the chosen directory from the array
		NSMutableString * fileNameAndPath = [[NSMutableString alloc] init];  // string to hold the filename appended to the path
		
		for (i=0; i<[selectedItems count]; i++)
		{
			theProgram = [selectedItems objectAtIndex:i];
			theSynth = [theProgram synth];
			
			[fileNameAndPath appendFormat: @"%@/%@_%@.syx", directoryPath, [[theProgram synth] name], [theProgram name]];  // append the current filename to the path
			
			exportData = [theSynth  prepareProgramToSend: theProgram programNumber: [theProgram programNumber] bankNumber: [theProgram bankNumber]];  // get the export data from the program's synth object
			[exportData retain];
			
			NSLog(@"Writing to file: \"%@\"", fileNameAndPath);
			
			// Try and write the file
			if (![exportData writeToFile: fileNameAndPath atomically:YES])
			{
				NSBeep();
				NSAlert *alert = [[NSAlert alloc] init];
				[alert addButtonWithTitle:@"OK"];
				[alert setMessageText:[NSString stringWithFormat:@"Error Writing File: %@!", fileNameAndPath]];
				[alert setAlertStyle:NSWarningAlertStyle];
				[alert runModal];
				[alert release];
			}
			
			[fileNameAndPath setString:@""];  // reset the file name and path
			[exportData release];
		}
	
    }	
	
}

- (IBAction) importFilesFromSysex: (id) sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];  // panel used to select destination directory
	int result, i;
	
	// configure the open panel, used to choose the destination directory
	[oPanel setCanChooseFiles: TRUE];	
	[oPanel setCanChooseDirectories: FALSE];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setTitle:@"Choose Folder"];
    [oPanel setMessage:@"Choose destination folder for export."];
    [oPanel setDelegate:self];
	
	// run the panel and get result, which we can ignore
    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:[NSArray arrayWithObject:@"syx"]];

	NSMutableData * importedData;  // data to export, formatted with header and terminal 0xF0
	
	if (result == NSOKButton) 
	{
        NSArray *theFilesToImport = [oPanel filenames]; // the chosen directory in an array
		NSString *aFile;  // the chosen directory from the array
		
		for (i=0; i<[theFilesToImport count]; i++)
		{
			aFile = [theFilesToImport objectAtIndex:i];  // the chosen directory from the array
	
			importedData = [[NSMutableData alloc] initWithContentsOfFile: aFile];
				
			int result;
			
			NSLog(@"Importing file: \"%@\"", aFile);
			// run loop while we get a positive response AND imported data is greater than zero
			while ([importedData length] > 0)
			{				
				if ( (result = [andromeda tryImportData: importedData forCollection:mainCollection]) != -1 )
				{
					int remainder = [importedData length] - result;
					[importedData setData: [importedData subdataWithRange: NSMakeRange(result, remainder)]];
				}
				else if ( (result = [pcm91 tryImportData: importedData forCollection:mainCollection]) != -1)
				{
					int remainder = [importedData length] - result;
					[importedData setData: [importedData subdataWithRange: NSMakeRange(result, remainder)]];
				}
				else
				{
					break;
				}
			}
			
			[importedData release];
		}
		
    }	
	
}


/////////////////////////////////////////////////////////////////////////////////////////
//// Midi Setup


- (IBAction) midiSetup: (id) sender
{
	[[MidiSetup alloc] initForDocument: self];
}

- (void) midiSetupFinished: (id) sender
{
	[sender release];
}

/////////////////////////////////////////////////////////////////////////////////////////
//// Table View routines

// Utility function that checks to make sure the user has selected an item in the table view.
// - if not, shows an alert panel and returns false
// - is so, returns true
- (BOOL) checkNoSelectionWithMessage: (NSString*) message
{
	if ([tableView selectedRow] == -1)
	{
		NSBeep();
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"No Selection!"];
		[alert setInformativeText:message];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
		[alert release];
		return FALSE;
	}
	return TRUE;
}

- (NSArray*) getItemsSelectedInTableView
{
	// Array to hold the selected items
	NSMutableArray * selectedItems = [[NSMutableArray alloc] init];
	
	// get an index set of the row indexes
	NSIndexSet * rowIndexes = [tableView selectedRowIndexes];

	// the first index
	int currentIndex = [rowIndexes firstIndex];
	
	while (currentIndex != NSNotFound)
	{
		[selectedItems addObject: [mainCollection getItem: currentIndex] ];  // add the first index to the array
		currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex]; // get the next index
	}
	
	[selectedItems autorelease];
	return selectedItems;
}

- (IBAction) deleteSelectedItems: (id) sender
{
	// make sure there is a selection
	[self checkNoSelectionWithMessage:@"Unable to delete: no items selected!"];
	
	// UNDO STUFF
	[self setUndoPoint];
	
	// and array of the items selected in the table view (used for removal)
	NSArray * selectedItems = [[self getItemsSelectedInTableView] retain];
	
	// remove the items
	[mainCollection removeItems: selectedItems];
	
	// reload the data
	[tableView reloadData];
	
	[tableView deselectAll:self];
	
	[selectedItems release];
	//[selectedItemsAndRows release];
}

- (void) setUndoPoint
{
	// UNDO STUFF
	NSArray * undoTheCollection = [[mainCollection theCollection] mutableCopy];
	NSArray * undoHiddenCollection = [[mainCollection hiddenCollection] mutableCopy];
	
	[[[self undoManager] prepareWithInvocationTarget: self] setTheCollection: undoTheCollection  hiddenCollection: undoHiddenCollection forCollection: mainCollection];
	[[[self undoManager] prepareWithInvocationTarget: tableView] reloadData];
	
	[undoTheCollection release]; [undoHiddenCollection release];	
}

- (void) deleteItems: (NSArray*) itemsToDelete
{

	// UNDO STUFF
	[self setUndoPoint];
	
	//tell the collection to remove the items
	[mainCollection removeItems: itemsToDelete];
		
	// need to reload the table view data
	[tableView reloadData];
}

- (void) addItemsToCollection: (NSArray*) itemsToAdd
{	
	int i;
	for (i=0; i<[itemsToAdd count]; i++)
	{
		[mainCollection insertItems: itemsToAdd atIndex:0];
	}
	
	[tableView reloadData];

	[undoManager registerUndoWithTarget:self selector:@selector(deleteItems:) object:itemsToAdd];
}

- (void) addItemsToCollection: (NSArray*) itemsToAdd atIndex: (int) index
{
	[mainCollection insertItems: itemsToAdd atIndex:index];
	
	[tableView reloadData];
	[undoManager registerUndoWithTarget:self selector:@selector(deleteItems:) object:itemsToAdd];
}

- (void) setValueForIdentifier: (NSString*) identifier row: (int) rowIndex objectValue: (id) anObject collection: (ACollection*) collection
{
	// save the old value for undo
	id oldValue = [mainCollection stringForIdentifier:identifier row:rowIndex];
	
	// set the new value
	[mainCollection setValueForIdentifier: identifier row: rowIndex objectValue: anObject];	
	
	// register the undo invocations
	[[[self undoManager] prepareWithInvocationTarget:mainCollection] setValueForIdentifier: identifier row: rowIndex objectValue: oldValue];
	[[[self undoManager] prepareWithInvocationTarget:tableView] reloadData];
	
}

// replaces aCollection's collections (the array that holds the programs) with new arrays
// - used by table data source when array is sorted for Undo operations.  Necessary becasue user might have items in arbitrary (unsorted) order
//   in table view, so when we undo the sort, we have to be able to revert back to any arbitrary order, not just another sorted order
- (void) setTheCollection: (NSArray*) newCollection hiddenCollection: (NSArray*) hiddenCollection forCollection: (ACollection*) aCollection
{	
	[[[self undoManager] prepareWithInvocationTarget: self] setTheCollection: [[aCollection theCollection] mutableCopy] hiddenCollection: [[aCollection hiddenCollection] mutableCopy] forCollection: aCollection];
	[[[self undoManager] prepareWithInvocationTarget: tableView] reloadData];
	
	[aCollection setTheCollection:newCollection];
	[aCollection setHiddenCollection:hiddenCollection];
}


/////////////////////////////////////////////////////////////////////////////////////////
//// EDIT MULTIPLE SELECTION

// when OK is clicked on the sheet, this is called to fill in the values in the selected items
- (IBAction) emsOKClicked: (id) sender
{
	[NSApp endSheet: emsWindow];
	[emsWindow orderOut:self];
	
	BOOL namef, commentsf, progf, bankf;
	
	// flags to see if the text box has been edited
	namef = [[emsNameTextField stringValue] isEqualToString: @""];
	commentsf = [[emsCommentsTextField stringValue] isEqualToString: @""];
	bankf = [[emsBankNumberTextField stringValue] isEqualToString: @""];
	progf = [[emsProgramNumberTextField stringValue] isEqualToString: @""];
	
	// get an index set of the row indexes
	NSIndexSet * rowIndexes = [tableView selectedRowIndexes];
		
	// the first index
	int currentIndex = [rowIndexes firstIndex];
	
	while (currentIndex != NSNotFound)
	{
		if (!namef)
		{
			// set the new value
			[self setValueForIdentifier: @"Name" row: currentIndex objectValue: [emsNameTextField stringValue] collection:mainCollection];
		}
			
		if (!commentsf)
		{
			// set the new value
			[self setValueForIdentifier: @"Comments" row: currentIndex objectValue: [emsCommentsTextField stringValue] collection:mainCollection];
		}
				
		if (!bankf)
		{
			// set the new value
			[self setValueForIdentifier: @"Bank" row: currentIndex objectValue: [emsBankNumberTextField stringValue] collection:mainCollection];
		}
		
		if (!progf)
		{
			// set the new value
			[self setValueForIdentifier: @"Prog" row: currentIndex objectValue: [emsProgramNumberTextField stringValue] collection:mainCollection];
		}
			
		currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex]; // get the next index
	}
	
	[tableView reloadData];
	
	
}

- (IBAction) emsCancelClicked: (id) sender
{
	[NSApp endSheet: emsWindow];
	[emsWindow orderOut:self];
}

- (IBAction) editMultipleSelection: (id)sender
{
	[NSApp beginSheet:emsWindow modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


/////////////////////////////////////////////////////////////////////////////////////////
//// USER ACTIONS


// sends all of the selected items in the table view to their stored values
- (IBAction) sendSelectedToStoredValues: (id) sender
{
	NSArray * selectedItems = [self getItemsSelectedInTableView];
	
	int i;
	for (i=0; i<[selectedItems count]; i++)
	{
		[[selectedItems objectAtIndex:i] sendToSynthAtProgramNumber:NOVALUE bankNumber:NOVALUE];
	}
}

// sends a program change to the selected item's synth, telling it to change to the selected item's program number and bank number
- (IBAction) selectSelection: (id) synth
{
	int comboBoxIndex = [andromedaSendProgramSelectComboBox indexOfSelectedItem];
	
	// get the selected program
	int selectedRow = [tableView selectedRow];
	
	if (![self checkNoSelectionWithMessage: @"Unable to send program: no program selected!"]) return;
	
	AProgram * program = [mainCollection getItem: selectedRow];

	[program sendSelectedInSynth];
	
}


// returns the currently selected (active) synth in the combo box
// this determines to which synth requests will be sent
- (int) getSelectedSynth
{
	if ([synthSelectComboBox indexOfSelectedItem] == 0) return SYNTH_ANDROMEDA;
	else if ([synthSelectComboBox indexOfSelectedItem] == 1) return SYNTH_PCM91;
	else NSAssert(FALSE, @"SynthLib: getSelectedSynth: error!");
	return nil; // needed to placate warning message
}

// gets the edit buffer from the synth
- (IBAction) andromedaGetProgramEditBuffer: (id) sender
{
	[(AlesisAndromeda*)andromeda requestProgramEditBufferDump: 16 forCollection: mainCollection];
}

// gets a program from the synth
- (IBAction) andromedaGetProgram: (id) sender
{
	// retrieve from combo boxes the program number and bank of program to get from synth
	int programNumber = [andromedaProgramSelectComboBox indexOfSelectedItem];
	int bankNumber = [andromedaBankSelectComboBox indexOfSelectedItem];

		if (programNumber <=127) // user selected an individual program
		{
			[(AlesisAndromeda*)andromeda requestProgramDump: programNumber bankNumber: bankNumber forCollection: mainCollection];
		}
		else  // user wants the entire bank
		{
			[(AlesisAndromeda*)andromeda requestProgramBankDump: bankNumber forCollection: mainCollection];
		}

}

// Sends a program to the synth
- (IBAction) andromedaSendProgram: (id) sender
{
	int comboBoxIndex = [andromedaSendProgramSelectComboBox indexOfSelectedItem];
	
	// get the selected program
	int selectedRow = [tableView selectedRow];
	
	if (![self checkNoSelectionWithMessage: @"Unable to send program: no program selected!"]) return;
	
	AProgram * program = [mainCollection getItem: selectedRow];
	
	// make sure an Andromeda Program is selected
	if (![program isMemberOfClass:[AndromedaProgram class]])
	{
		[Utility runAlertWithMessage: @"Wrong Program Type Selected!"];
		return;
	}
	
	if (comboBoxIndex == 0)  // use stored program number, but ignore bank and send to user bank
	{
		[((AlesisAndromeda*)andromeda) sendProgramDump: (AndromedaProgram*)program programNumber: [program programNumber] bankNumber: ANDROMEDA_USER_BANK];
	}
	else  // else, use the program number selected in the combo box
	{
		[((AlesisAndromeda*)andromeda) sendProgramDump: (AndromedaProgram*)program programNumber: (comboBoxIndex - 1) bankNumber: ANDROMEDA_USER_BANK]; // 0 = USER BANK	
	}
	
}

- (IBAction) activeSynthDidChange: (id) sender
{
	[synthSelectTabView selectTabViewItemAtIndex: [synthSelectComboBox indexOfSelectedItem]];
	[self activeSynthFilterButtonClicked: self];
}

- (ASynth*) activeSynth
{
	int index = [synthSelectComboBox indexOfSelectedItem];
	if (index == 0) return andromeda;
	else if (index == 1) return pcm91;
	else return nil;
}

- (IBAction) activeSynthFilterButtonClicked: (id) sender
{
	if ([filterTableActiveSynthCheckBox state] == NSOnState)
	{
		[mainCollection setSynthFilterForTableView: [self activeSynth]];
	}
	else 
	{
		[mainCollection setSynthFilterForTableView: nil];
	}
	
	[tableView reloadData];
}

- (IBAction) pcm91GetProgram: (id) sender
{
	// retrieve from combo boxes the program number and bank of program to get from synth
	int programNumber = [pcm91ProgramSelectComboBox indexOfSelectedItem];
	int bankNumber = [pcm91BankSelectComboBox indexOfSelectedItem];

		if (programNumber <50) // user selected an individual program
		{
			[((YamahaPCM91*)pcm91) requestProgramDump: programNumber bankNumber: bankNumber forCollection: mainCollection];
		}
		else  // user wants the entire bank
		{
			[((YamahaPCM91*)pcm91) requestProgramBankDump: bankNumber forCollection: mainCollection];
		}
}


- (IBAction) pcm91GetProgramEditBuffer: (id) sender
{
	[((YamahaPCM91*)pcm91) requestProgramEditBufferDumpForCollection: mainCollection];
}


- (IBAction) pcm91SendProgram: (id) sender
{
	int programNumber = [pcm91SendProgramSelectComboBox indexOfSelectedItem];
	int bankNumber = [pcm91SendBankSelectComboBox indexOfSelectedItem];
	
	// get the selected program
	int selectedRow = [tableView selectedRow];
	
	if (![self checkNoSelectionWithMessage: @"Unable to send program: no program selected!"]) return;
	
	AProgram * program = [mainCollection getItem: selectedRow];
	
	// make sure an Andromeda Program is selected
	if (![program isMemberOfClass:[YamahaPCM91Program class]])
	{
		[Utility runAlertWithMessage: @"Wrong Program Type Selected!"];
		return;
	}

	
	if (programNumber == 0) programNumber = [program programNumber];
	else programNumber = programNumber - 1;
	
	if (bankNumber == 0) bankNumber = [program bankNumber];
	else if (bankNumber == 1) bankNumber = PCM91_USER_BANK_1;
	else if (bankNumber == 2) bankNumber = PCM91_USER_BANK_2;
	
	if (bankNumber < 9 || bankNumber > 10)
	{
		[Utility runAlertWithMessage: @"Invalid Bank Number!"];
		return;
	}

	[((YamahaPCM91*)pcm91) sendProgramDump: (YamahaPCM91Program*)program programNumber: programNumber bankNumber: bankNumber];

}

- (IBAction) pcm91SendProgramToEditBuffer: (id) sender
{
	int selectedRow = [tableView selectedRow];
	
	// no selection, ignore
	if (selectedRow < 0) 
	{
		[Utility runAlertWithMessage: @"No Program Selected!"];
		return;
	}
	
	AProgram * program = [mainCollection getItem: selectedRow];
	
	// make sure an Andromeda Program is selected
	if (![program isMemberOfClass:[YamahaPCM91Program class]])
	{
		[Utility runAlertWithMessage: @"Wrong Program Type Selected!"];
		return;
	}
	
	[((YamahaPCM91*)pcm91) sendProgramDumpToEditBuffer: (YamahaPCM91Program*)program];


}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// COMBO BOX ACTION ROUTINES - deal with formatting and parsing entered numbers or strings in combo boxes for selecting banks and programs

- (IBAction) andromedaGetProgramSelectComboBoxChange: (id) sender
{
		if ([andromedaProgramSelectComboBox objectValueOfSelectedItem] == @"All") 
		{
			[andromedaProgramSelectComboBox selectItemAtIndex: 128];
			return;
		}
	
		NSNumber * number = [numberFormatter numberFromString: [andromedaProgramSelectComboBox objectValueOfSelectedItem]];
		[andromedaProgramSelectComboBox selectItemAtIndex: [number intValue]];
}

- (IBAction) pcm91GetProgramSelectComboBoxChange: (id) sender
{
		if ([pcm91ProgramSelectComboBox objectValueOfSelectedItem] == @"All") 
		{
			[pcm91ProgramSelectComboBox selectItemAtIndex: 128];
			return;
		}
		
		NSNumber * number = [numberFormatter numberFromString: [pcm91ProgramSelectComboBox objectValueOfSelectedItem]];
		[pcm91ProgramSelectComboBox selectItemAtIndex: [number intValue]];

}

- (IBAction) andromedaSendProgramSelectComboBoxChange: (id) sender
{
		if ([andromedaSendProgramSelectComboBox objectValueOfSelectedItem] == @"Stored") 
		{
			[andromedaSendProgramSelectComboBox selectItemAtIndex: 0];
			return;
		}
		NSNumber * number = [numberFormatter numberFromString: [andromedaSendProgramSelectComboBox objectValueOfSelectedItem]];
		[andromedaSendProgramSelectComboBox selectItemAtIndex: [number intValue] + 1];

}

- (IBAction) pcm91SendProgramSelectComboBoxChange: (id) sender
{
		if ([pcm91SendProgramSelectComboBox objectValueOfSelectedItem] == @"Stored") 
		{
			[pcm91SendProgramSelectComboBox selectItemAtIndex: 0];
			return;
		}
		NSNumber * number = [numberFormatter numberFromString: [pcm91SendProgramSelectComboBox objectValueOfSelectedItem]];
		[pcm91SendProgramSelectComboBox selectItemAtIndex: [number intValue] + 1];

}



@end
