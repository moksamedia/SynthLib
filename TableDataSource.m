//
//  TableDataSource.m
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

#import "TableDataSource.h"
#import "ACollection.h"
#import "AProgram.h"
#import "SynthLib.h"
#import "Utility.h"

// aTableView's delegate is the object for which the data source should look up the information - this allows to use one data source for
// multiple table views and model objects (collections of programs)

@implementation TableDataSource

- (id) initWithDocument: (id) _document
{
	if ((self = [super init])) 
	{
		document = _document;
	}
	
	return self;

}

// this is used by the undo architecture to access the data source's document to make changes to the collection
- (id) document
{
	return document;
}

// Asks the data structure (the collection) for the display values for a given column and row
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ACollection * collection = [aTableView delegate];
	
	return [collection stringForIdentifier: [aTableColumn identifier] row:rowIndex];
}

// Allows user to edit cells in the table view and have those edits propogated to the data
// - go through the document to make these changes (and others) to keep edits of data in same place, mostly for consistency with Undo operations
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	[document setValueForIdentifier:[aTableColumn identifier] row:rowIndex objectValue:anObject collection: [aTableView delegate]];
}

// returns the number of rows in the view, ie. the number of items in the collection of programs
// - this corresponds to the number of items in the "theCollection" array.  the hiddenCollection array is just that, hidden and not accessed by the table view
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[aTableView delegate] numberOfItems];
}

/*
	SORTING
	
	This uses the NSArray's sort function to sort the collection according to an array of descriptor.  The items in the array must
	have properties that are key-value coding compliant to match the descriptors.  For example, if sort by descriptor "name", then
	the items in the collection must respond to [item name], etc...
	
	The descriptors for each column are set in Interface Builder in the inspector window.
 */
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	//**UNDO STUFF
	
	// Get the collection object
	//ACollection * collection = [aTableView delegate];
	
	[document setUndoPoint];
	
	/*
	// This is what happens at [document setUndoPoint];
	// Get the a copy of the collection arrays from the collection object for the undo stack push
	NSArray * oldTheCollection = [[collection theCollection] mutableCopy];
	NSArray * oldHiddenCollection = [[collection hiddenCollection] mutableCopy];
	
	// Use this implementation of the undo so that we can revert to any arbitrary order (and not just a sorted order).  Also, by making it a function call, this allows redo to work.
	[[[Utility sharedUndoManager] prepareWithInvocationTarget: document] setTheCollection: oldTheCollection hiddenCollection: oldHiddenCollection forCollection: collection];
	[[[Utility sharedUndoManager] prepareWithInvocationTarget: aTableView] reloadData];  // will also need to reload the data
	
	[oldTheCollection release]; [oldHiddenCollection release];
	*/
	
	//**DO THE SORTING
	
	// get the sort descriptors
	NSArray *newDescriptors = [aTableView sortDescriptors];
	// tell the collection to sort itself according to the descriptors (requires that the properties are key/vaule coded properly for the descripters)
    [[[aTableView delegate] theCollection] sortUsingDescriptors:newDescriptors];
	// need to reload the data
    [aTableView reloadData];
}

- (void)sortUsingSameDescriptorForTableView:(NSTableView*) aTableView
{
    [[[aTableView delegate] theCollection] sortUsingDescriptors:[aTableView sortDescriptors]];
    [aTableView reloadData];	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DRAG AND DROP 

// BEGIN DROP
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{

	// get the collection from the table view
	ACollection * collection = [tv delegate];

	// ridiculously complicated way to get the indexes of the selected rows from the index set
	unsigned int maxSizeOfIndexSet = [tv numberOfRows];
	unsigned int buffer[maxSizeOfIndexSet];	// buffer into which the selected rows will be copied
	int numberOfIndexes;
	NSRange range = NSMakeRange(0, maxSizeOfIndexSet);
	NSRangePointer rangePointer = &range;
	numberOfIndexes = [rowIndexes getIndexes: buffer maxCount: maxSizeOfIndexSet inIndexRange: rangePointer];

	// Array to hold the selected items
	NSMutableArray * selectedItems = [[NSMutableArray alloc] init];

	// iterate through the selected rows and add the selected objects to selectedItems array
	int i;		
	for (i=0; i<numberOfIndexes; i++)
	{	
		[selectedItems addObject: [collection getItem: buffer[i] ] ];
	}
	
	NSLog(@"Copying %d items, %d", [selectedItems count], [rowIndexes count]);
	
	// give the selected items to my Utility pasteboard server
	[Utility StartDragWithSource: tv items: selectedItems];
	[selectedItems release];  // utility retains, to release
	
	// still have to do this even though we're using our own pasteboard
    [pboard declareTypes:[NSArray arrayWithObject:SynthProgramTableViewDataType] owner:self];
    [pboard setData:nil forType:SynthProgramTableViewDataType];
   
	 return YES;
}

// VALIDATE DROP
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Add code here to validate the drop
    NSLog(@"validate Drop at Row %d", row);
    return NSDragOperationEvery;
}

// ACCEPT DROP
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	BOOL commandKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
	
	id dragSource = [[Utility GetDragSource] dataSource];
	id dragDestination = [[aTableView dataSource] document];
	
	if (row == -1) row = 0;  // no selection, insert at first row
	
	NSLog(@"Adding items at row %d", row);	
	
	// if the command key is NOT down, then we want to MOVE the items, so remove them from the original collection.  otherwise, leave them in place and copy.
	// MOVE
	if (!commandKeyDown)
	{
		// remove the drag items from the drag source
		[[dragSource document] deleteItems: [Utility GetDragItems]];
		
		/*
			This is necessary to avoid a sublte bug.  We must first remove the items from the drag source, then, if the drag source is also the destination,
		    we must adjust the row index by subtracting the number of items deleted before adding them back in.  It's important that the items are deleted before
			being added back in, otherwise both copies are removed.
		 */
		if (dragDestination == [[[Utility GetDragSource] dataSource] document])
		{
			row = row - [[Utility GetDragItems] count];
			if (row < 0) row = 0;  // TODO: need to fix this so that row is decremented by the number of items < the row
		}

		// add the items to the destination
		[[[aTableView dataSource] document] addItemsToCollection: [Utility GetDragItems] atIndex: row];
	}
	
	// COPY
	else
	{
		NSArray * copy = [[NSArray alloc] initWithArray:[Utility GetDragItems] copyItems:YES];
		// add the items to the destination
		[[[aTableView dataSource] document] addItemsToCollection:copy atIndex:row];
		
		[copy release];
	}

	// reload the data
	[[Utility GetDragSource] reloadData];
	if (aTableView != [Utility GetDragSource]) [aTableView reloadData];

	// this cleard the pasteboard and releases the array of drag items
	[Utility EndDrag];
	
	return TRUE;
}

@end
