//
//  Collection.h
//  SynthLib
//
//  Created by Andrew Hughes on 12/16/08.
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


@interface ACollection : NSObject 
{
	NSMutableArray * theCollection;
	NSTableView * tableView;
	NSNumberFormatter *numberFormatter;

	NSMutableArray * hiddenCollection;	
	id activeSynthForFilter;
}

- (id) initForTableView:(NSTableView*) tb;
- (void) setTableView: (NSTableView*) tb;

- (void) addItem: (id) newItem;
- (void) addItemAtSelectedRow: (id) newItem;
- (void) addItems: (NSArray*) newItems;
- (id) getItem: (int) i;
- (int) numberOfItems;
- (void) insertItem: (id) newItem atIndex: (int) index;
- (void) insertItems: (NSArray*) newItems atIndex: (int) i;
- (void) removeItems: (NSArray*) itemsToRemove;
- (int) indexOfItem: (id) item;

- (NSMutableArray*) theCollection;
- (void) setTheCollection: (NSArray*) aCollection;

// used to filter what items are shown in table view
- (NSMutableArray*) hiddenCollection;
- (void) setHiddenCollection: (NSArray*) aCollection;
- (void) setSynthFilterForTableView: (id) activeSynth;
- (void) updateFilteredCollection;

// TABLE VIEW DELEGATE METHOD - SHOULD A GIVEN ROW AND COLUMN BE EDITED - ASK THE ITEM
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Used by table view data source to change item properties.  Returns true if successful (result used by undo manager to decide whether to set and undo event)
- (BOOL) setValueForIdentifier: (NSString*) identifier row: (int) rowIndex objectValue: (id) anObject;

// Used by table view data source to retrieve item properties
- (NSString *) stringForIdentifier: (NSString*) identifier row: (int) rowIndex;


@end
