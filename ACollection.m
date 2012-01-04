//
//  Collection.m
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

#import "ACollection.h"
#import "ACollectionItem.h"
#import "AProgram.h"

@implementation ACollection

- (id) initForTableView: (NSTableView*) tb
{
	if ((self = [super init])) 
	{
		theCollection = [[NSMutableArray alloc] init];
		hiddenCollection = [[NSMutableArray alloc] init];
		tableView = tb;
		
		// Number formatter used to parse program numbers entered into the table view
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setFormat:@"0"];
		
		activeSynthForFilter = nil;

	}
	
	return self;
}

- (void) dealloc
{
	[theCollection release];
	[hiddenCollection release];
	[numberFormatter release];
	[super dealloc];
}

- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeObject: theCollection forKey:@"theCollection"];

	return;
}

- (id) initWithCoder: (NSCoder *) coder
{
	theCollection = [[coder decodeObjectForKey:@"theCollection"] retain];

	// Number formatter used to parse program numbers entered into the table view
	numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setFormat:@"0"];

	hiddenCollection = [[NSMutableArray alloc] init];

	return self;
}


// sets the associated table view
- (void) setTableView: (NSTableView*) tb
{
	tableView = tb;
}

// the array that holds the programs
- (NSMutableArray*) theCollection
{
	return theCollection;
}

- (NSMutableArray*) hiddenCollection
{
	return hiddenCollection;
}

- (void) setTheCollection: (NSArray*) aCollection
{
	NSAssert(aCollection != nil, @"NIL collection");
	[theCollection release];
	theCollection = [aCollection mutableCopy];
}
- (void) setHiddenCollection: (NSArray*) aCollection
{
	NSAssert(aCollection != nil, @"NIL collection");
	[hiddenCollection release];
	hiddenCollection = [aCollection mutableCopy];
}


// add an item
- (void) addItem: (id) newItem
{
	NSAssert([newItem isKindOfClass:[ACollectionItem class]], @"ACollection: addItem: trying to add item that is not ACollectionItem");
	[theCollection addObject:newItem];
	[self updateFilteredCollection];
	[tableView reloadData];
}

- (void) addItems: (NSArray*) newItems
{
	int i;
	for (i=0; i<[newItems count]; i++)
	{
		[self addItem:[newItems objectAtIndex:i]];
	}
}

// add an item inserted at the row selected in the table view
- (void) addItemAtSelectedRow: (id) newItem
{
	int selectedRow = [tableView selectedRow];
	if (selectedRow < 0) selectedRow = [theCollection count];
	NSAssert([newItem isKindOfClass:[ACollectionItem class]], @"ACollection: addItemAtSelectedRow: trying to add item that is not ACollectionItem");
	[theCollection insertObject:newItem atIndex:selectedRow];
	NSLog(@"adding new item %@ at row %d", [newItem name], selectedRow);
	[self updateFilteredCollection];
	[tableView reloadData];
}

// returns a specific item
- (id) getItem: (int) i
{
	NSAssert (i >=0 && i < [theCollection count], @"ACollection: getItem - out of bounds!");
	return [theCollection objectAtIndex: i];
}

- (int) numberOfItems
{
	return [theCollection count];
}

- (void) insertItems: (NSArray*) newItems atIndex: (int) i
{
	//if (i < 1) i=1;
	
	int j;
	for (j=0; j < [newItems count]; j++)
	{
		NSLog(@"Inserting %@ to collection %p at index %d in count %d.", [[newItems objectAtIndex:j] name], self, i, [theCollection count]);
		[theCollection insertObject: [newItems objectAtIndex:j] atIndex: i];
	}
	[self updateFilteredCollection];
}

- (void) insertItem: (id) newItem atIndex: (int) index
{
	NSAssert(index <= [theCollection count], @"index out of bounds!");
	[theCollection insertObject: newItem atIndex: index];
	[self updateFilteredCollection];
}

- (void) removeItems: (NSArray*) itemsToRemove
{
	int j;
	for (j=0; j < [itemsToRemove count]; j++)
	{
		NSLog(@"Removing %@ from collection %p", [[itemsToRemove objectAtIndex:j] name], self);
		[theCollection removeObject: [itemsToRemove objectAtIndex:j] ];
	}
	[self updateFilteredCollection];
}

- (int) indexOfItem: (id) item
{
	return [theCollection indexOfObject: item];
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// FILTERED ACCESS ROUTINES FOR TABLE VIEW


- (void) setSynthFilterForTableView: (id) activeSynth
{
	activeSynthForFilter = activeSynth;
	[self updateFilteredCollection];
}

- (void) updateFilteredCollection
{
	[theCollection addObjectsFromArray: hiddenCollection];
	[hiddenCollection removeAllObjects];
	
	ACollectionItem * prog;
	
	if (activeSynthForFilter == nil) 
	{
		return;
	}
	
	int i;
	for (i=0; i < [theCollection count]; i++)
	{
		prog = [theCollection objectAtIndex: i];
		if (![[prog synth] isKindOfClass: [activeSynthForFilter class]])
		{
			[hiddenCollection addObject: prog];
		}
	} 
	
	[theCollection removeObjectsInArray: hiddenCollection];
}	

///////////////////////////////////////////////////////////////////////////////////////////////////////
// TABLE DATA SOURCE GET AND SET HOOK ROUTINES

// query method called by table view data source to get the string value for a given column (identifier) and row
- (NSString *) stringForIdentifier: (NSString*) identifier row: (int) rowIndex
{
	NSAssert(rowIndex >= 0 && rowIndex < [theCollection count], @"rowIndex out of bounds!");
	

	if ([identifier isEqualToString: @"Name"])
	{
		return [[self getItem: rowIndex] name];	
	}
	else if ([identifier isEqualToString: @"Prog"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] programNumberString];	
	}
	else if ([identifier isEqualToString: @"Bank"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] bankName];
	}
	else if ([identifier isEqualToString: @"Synth"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] synthName];
	}
	else if ([identifier isEqualToString: @"Comments"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] comments];	
	}
	else if ([identifier isEqualToString: @"Comments2"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] comments2];	
	}
	else if ([identifier isEqualToString: @"Type"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] typeString];	
	}
	else
		return @"DOH!";

}

// method called by table view data source to set value for a given column (identifier) and row
// objectValue is assumed to be an NSString
- (BOOL) setValueForIdentifier: (NSString*) identifier row: (int) rowIndex objectValue: (id) anObject
{
	NSAssert(rowIndex >= 0 && rowIndex < [theCollection count], @"rowIndex out of bounds!");
	
	// NAME
	if ([identifier isEqualToString: @"Name"])
	{
		return [(ACollectionItem*)[self getItem: rowIndex] setName: anObject];
	}
	// PROGRAM NUMBER
	else if ([identifier isEqualToString: @"Prog"])
	{
		NSNumber * number = [numberFormatter numberFromString: anObject];
		return [(AProgram*)[self getItem: rowIndex] trySetProgramNumber: [number intValue] ];
	}
	// BANK NUMBER
	else if ([identifier isEqualToString: @"Bank"])
	{
		NSNumber * number = [numberFormatter numberFromString: anObject];
		return [(AProgram*)[self getItem: rowIndex] trySetBankNumber: [number intValue] ];
	}
	// COMMENTS
	else if ([identifier isEqualToString: @"Comments"])
	{
		return [[self getItem: rowIndex] setComments: anObject];
	}
	else
	{
		return FALSE;
	}
}

// TABLE VIEW DELEGATE METHOD - SHOULD A GIVEN ROW AND COLUMN BE EDITED - ASK THE ITEM
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [(ACollectionItem*)[self getItem: rowIndex] shouldEditForIdentifier: [aTableColumn identifier]];
}



@end
