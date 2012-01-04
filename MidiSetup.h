//
//  MidiSetup.h
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

#import <Cocoa/Cocoa.h>


@interface MidiSetup : NSObject 
{

	id document;
	
	BOOL addFlag;
	NSMutableArray * prefsArray;
	NSUserDefaults * userDefaults;
	NSMutableArray * installedSynths;
	
	NSNumberFormatter * numberFormatter;
	
	IBOutlet NSComboBox * nameComboBox;
	IBOutlet NSComboBox * inPortComboBox;
	IBOutlet NSComboBox * outPortComboBox;
	IBOutlet NSComboBox * deviceIDComboBox;
	
	IBOutlet NSButton * addSynthButton;
	IBOutlet NSButton * editSynthButton;
	IBOutlet NSButton * deleteSynthButton;
	
	IBOutlet NSPanel * addOrEditWindow;
	IBOutlet NSWindow * midiSetupWindow;
	
	IBOutlet NSTableView * tableView;
}

@property (retain) NSWindow * midiSetupWindow;
@property (retain) NSPanel * addOrEditWindow;

- (id) initForDocument: (id) _document;

- (IBAction) addSynth: (id) sender;
- (IBAction) editSynth: (id) sender;
- (IBAction) deleteSynth: (id) sender;

- (IBAction) cancel: (id) sender;
- (IBAction) confirm: (id) sender;
- (IBAction) finish: (id) sender;


+ (NSString*) synthStringForType: (int) i;
+ (int) numberOfInstalledSynths;
+ (int) readSynthTypeForSynthNumber: (int) i;
+ (int) readInPortForSynthNumber: (int) i;
+ (int) readOutPortForSynthNumber: (int) i;
+ (int) readDeviceIDForSynthNumber: (int) i;

- (void) setNumberOfInstalledSynths: (int) num;
- (void) writeSynthType: (int) type forSynthNumber: (int) i;
- (void) writeOutPort: (int) type forSynthNumber: (int) i;
- (void) writeInPort: (int) type forSynthNumber: (int) i;
- (void) writeDeviceID: (int) type forSynthNumber: (int) i;



@end
