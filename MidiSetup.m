//
//  MidiSetup.m
//  SynthLib
//
//  Created by Andrew Hughes on 1/27/09.
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

#import "MidiSetup.h"
#import "Definitions.h"
#import "SynthLib.h"
#import "ASynth.h"
#import <CoreMidi/MidiServices.h>


@implementation MidiSetup

@synthesize addOrEditWindow;
@synthesize midiSetupWindow;

- (id) initForDocument: (id) _document
{
	if ((self = [super init]))
	{
		document = _document;
				
		// load the NIB
		if (![NSBundle loadNibNamed:@"MidiSetup" owner:self])
		{
			NSLog(@"Warning! Could not load MidiSetup file.\n");
			NSAssert(true, @"Unable to load MidiSetup NIB!");
		}
		
		[tableView setDataSource: self];
		[tableView setDelegate:self];
		
		userDefaults = [NSUserDefaults standardUserDefaults];
		
		// Number formatter used to parse program numbers entered into the table view
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setFormat:@"0"];
		
		// Get number of sources and destinations
		int InCount = MIDIGetNumberOfSources();
		int OutCount = MIDIGetNumberOfDestinations();
		
		// SETUP GUI
		
		// synth type combo box
		[nameComboBox addItemWithObjectValue:ANDROMEDA_STRING_VALUE];
		[nameComboBox addItemWithObjectValue:PCM91_STRING_VALUE];
		[nameComboBox selectItemAtIndex:0];
		
		// in port
		int i;
		if (InCount > 0)
		{
			for (i=1; i <= InCount; i++)
			{
				[inPortComboBox addItemWithObjectValue:[NSString stringWithFormat:@"%d", i]];
			}
		}
		else
		{
			[inPortComboBox addItemWithObjectValue:[NSString stringWithFormat:@"NONE"]];			
		}
		
		[inPortComboBox selectItemAtIndex:0];
		
		// out port
		if (OutCount > 0)
		{
			for (i=0; i <= OutCount; i++)
			{
				[outPortComboBox addItemWithObjectValue:[NSString stringWithFormat:@"%d", i]];
			}
		}
		else
		{
			[outPortComboBox addItemWithObjectValue:[NSString stringWithFormat:@"NONE"]];			
		}
		
		[outPortComboBox selectItemAtIndex:0];
		
		[deviceIDComboBox addItemWithObjectValue:[NSString stringWithFormat:@"0"]];
		[deviceIDComboBox selectItemAtIndex:0];
		
		[tableView reloadData];
		
	}
	return self;
}

- (void) dealloc
{
	[midiSetupWindow release];
	[addOrEditWindow release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// READING FROM PREFS ARE CLASS METHODS - so they can be accessed without instantiating an object

+ (int) numberOfInstalledSynths
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"numberOfInstalledSynths"];
}

+ (int) readSynthTypeForSynthNumber: (int) i
{
	return [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"Synth_%d_SynthType", i]];
}

+ (int) readInPortForSynthNumber: (int) i
{
	return [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"Synth_%d_InPort", i]];
}

+ (int) readOutPortForSynthNumber: (int) i
{
	return [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"Synth_%d_OutPort", i]];	
}

+ (int) readDeviceIDForSynthNumber: (int) i
{
	return [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"Synth_%d_DeviceID", i]];	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// WRITING TO PREFS (not class methods)

- (void) writeSynthType: (int) type forSynthNumber: (int) i
{
	[userDefaults setInteger: type forKey:[NSString stringWithFormat:@"Synth_%d_SynthType", i]];
}

- (void) writeOutPort: (int) oPort forSynthNumber: (int) i
{
	[userDefaults setInteger: oPort forKey:[NSString stringWithFormat:@"Synth_%d_OutPort", i]];	
}

- (void) writeInPort: (int) iPort forSynthNumber: (int) i
{
	[userDefaults setInteger: iPort forKey:[NSString stringWithFormat:@"Synth_%d_InPort", i]];		
}

- (void) writeDeviceID: (int) dID forSynthNumber: (int) i
{
	[userDefaults setInteger: dID forKey:[NSString stringWithFormat:@"Synth_%d_DeviceID", i]];			
}

- (void) setNumberOfInstalledSynths: (int) num
{
	[userDefaults setInteger: num forKey:[NSString stringWithFormat:@"numberOfInstalledSynths"]];			
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ACTIONS

- (IBAction) finish: (id) sender
{
	[tableView setDataSource:nil]; // needed this because table view was trying to reload but throwing error
	[midiSetupWindow close];
	[(SynthLib*)document midiSetupFinished:self];		
}

- (IBAction) addSynth: (id) sender
{
	//NSLog(@"ADDING SYNTH");
	//[addOrEditWindow makeKeyAndOrderFront:self];
	addFlag = TRUE;
	[NSApp beginSheet:addOrEditWindow modalForWindow:midiSetupWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
}
- (IBAction) cancel: (id) sender
{
    [addOrEditWindow orderOut:nil];
    [NSApp endSheet:addOrEditWindow];
}

- (IBAction) confirm: (id) sender
{
	// get rid of sheet
    [addOrEditWindow orderOut:nil];
    [NSApp endSheet:addOrEditWindow];
	
	int newOrEditSynthNumber;
	
	// the new or edited port and device ID values
	int inPort = [inPortComboBox intValue];
	int outPort = [outPortComboBox intValue];
	int deviceID = [deviceIDComboBox intValue];
	
	NSLog(@"in = %d, out = %d, ID = %d", inPort, outPort, deviceID);

	// synth type
	
	NSString * synthType = [nameComboBox stringValue];
	int sType = -1;
	
	if ([synthType isEqualToString:ANDROMEDA_STRING_VALUE])
	{
		sType = SYNTH_ANDROMEDA;
	}
	else if ([synthType isEqualToString:PCM91_STRING_VALUE])
	{
		sType = SYNTH_PCM91;
	}
	else if ([synthType isEqualToString:MOOG_STRING_VALUE])
	{
		NSAssert(true, @"This shouldn't happen!");
		sType = SYNTH_MOOG;
	}
	else if ([synthType isEqualToString:SUPERNOVA_STRING_VALUE])
	{
		NSAssert(true, @"This shouldn't happen!");
		sType = SYNTH_SUPERNOVA;
	}
	else if ([synthType isEqualToString:WALDORFQ_STRING_VALUE])
	{
		NSAssert(true, @"This shouldn't happen!");	
		sType = SYNTH_WALDORFQ;
	}
	else
	{
		NSAssert(true, @"This shouldn't happen!");	
	}

	// if adding a new synth
	if (addFlag)
	{
	
		if ([[inPortComboBox stringValue] isEqualToString:@"NONE"] || [[outPortComboBox stringValue] isEqualToString:@"NONE"])
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Device information appeared to be invalid."];
			[alert addButtonWithTitle:@"OK"];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert runModal];
			[alert release];
			return;
		}
		
		// calculate the new number of synths, which is also the index of hte new synth
		newOrEditSynthNumber = [MidiSetup numberOfInstalledSynths] + 1;  // Synths are 1-indexed
		
		// increment the number of installed synths saved in prefs
		[self setNumberOfInstalledSynths: newOrEditSynthNumber];
			
	}
	// otherwise just editing
	else
	{
		newOrEditSynthNumber = [tableView selectedRow] + 1;
	}
	
	// SET SYNTH TYPE
	[self writeSynthType:sType forSynthNumber:newOrEditSynthNumber];
	
	// SET PORT CONFIG
	[self writeInPort:inPort forSynthNumber:newOrEditSynthNumber];
	[self writeOutPort:outPort forSynthNumber:newOrEditSynthNumber];
	
	// SET DEVICE ID
	[self writeDeviceID:deviceID forSynthNumber:newOrEditSynthNumber];
	
	// make sure the new values are stored to the persistent storage
	[userDefaults synchronize];
	
	[tableView reloadData];
	
}

- (IBAction) editSynth: (id) sender
{
	
	int selectedSynth = [tableView selectedRow];
	
	if (selectedSynth == -1) return;
	else selectedSynth = selectedSynth + 1; // add 1 to adjust from 0-index to 1-index
	
	[nameComboBox setStringValue:[ASynth synthStringForType: [MidiSetup readSynthTypeForSynthNumber:selectedSynth]]];
	[inPortComboBox setIntValue:[MidiSetup readInPortForSynthNumber:selectedSynth]];
	[outPortComboBox setIntValue:[MidiSetup readOutPortForSynthNumber:selectedSynth]];
	[deviceIDComboBox setIntValue:[MidiSetup readDeviceIDForSynthNumber:selectedSynth]];
	
	
	[NSApp beginSheet:addOrEditWindow modalForWindow:midiSetupWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction) deleteSynth: (id) sender
{
	int numberOfSynths = [MidiSetup numberOfInstalledSynths];
	int config[numberOfSynths][4];
	int i,j;
	int synthToDelete = [tableView selectedRow]; // get selected row, 0-indexed
	
	// read the synth configuration to temporary array
	for (i=0;i<numberOfSynths;i++)
	{
		config[i][0] = [MidiSetup readSynthTypeForSynthNumber:(i+1)];  // array is 0-indexed and synths are 1-indexed
		config[i][1] = [MidiSetup readInPortForSynthNumber:(i+1)];
		config[i][2] = [MidiSetup readOutPortForSynthNumber:(i+1)];
		config[i][3] = [MidiSetup readDeviceIDForSynthNumber:(i+1)];
	}
	
	// remove the defaults
	[userDefaults removeVolatileDomainForName:@"com.cantgetnosleep.SynthLib"];
	[userDefaults removePersistentDomainForName:@"com.cantgetnosleep.SynthLib"];
	
	// decrement the number of synths
	numberOfSynths--;
	
	// set to defaults
	[self setNumberOfInstalledSynths:numberOfSynths];
	
	// re-write the synth config, skipping the one to delete
	j=1;
	for (i=0;i<numberOfSynths;i++)
	{
		if (i != synthToDelete)
		{
			[self writeSynthType: config[i][0] forSynthNumber:j];
			[self writeInPort: config[i][1] forSynthNumber:j];
			[self writeOutPort: config[i][2] forSynthNumber:j];
			[self writeDeviceID: config[i][3] forSynthNumber:j];
			j++;
		}
	}
	
	// write to persistent store
	[userDefaults synchronize];
	
	// reload the table view data
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString * identifier = [aTableColumn identifier];
	
	if ([identifier isEqualToString:@"Synth Type"])
	{
		return [ASynth synthStringForType: [MidiSetup readSynthTypeForSynthNumber:rowIndex+1]];
	}
	else if ([identifier isEqualToString:@"In Port"])
	{
		return [NSString stringWithFormat:@"%d", [MidiSetup readInPortForSynthNumber:rowIndex+1]];
	}
	else if ([identifier isEqualToString:@"Out Port"])
	{
		return [NSString stringWithFormat:@"%d", [MidiSetup readOutPortForSynthNumber:rowIndex+1]];	
	}
	else if ([identifier isEqualToString:@"Device ID"])
	{
		return [NSString stringWithFormat:@"%d", [MidiSetup readDeviceIDForSynthNumber:rowIndex+1]];	
	}
	else
	{
		NSAssert(true, @"This shouldn't happen!");
		return @"DOH!";
	}
	
	return nil;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [MidiSetup numberOfInstalledSynths];
}


@end
