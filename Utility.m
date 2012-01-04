//
//  Utility.m
//  StoryWriter
//
//  Created by Andrew Hughes on 1/10/08.
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

#import "Utility.h"

#define FORWARD 0
#define BACKWARD 1

@implementation Utility

#pragma mark Drag & Drop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DRAG AND DROP

static NSCharacterSet *cachedSet = nil;

static id dragSource = nil;
static NSArray * dragItems = nil;

+ (void) StartDragWithSource: (id) source items: (NSArray*) items
{
	dragSource = source;
	dragItems = items;
	[dragItems retain];
	/*
	NSLog(@"Utility");
	id object;
	int i;
	for (i=0; i < [items count]; i++)
	{
		object = [items objectAtIndex:i];
		NSLog([object nameString]);
	}
	 */
}

+ (id) GetDragSource
{
	return dragSource;
}

+ (NSArray*) GetDragItems
{
	[dragItems autorelease];
	return dragItems;
}

+ (Class) GetDragClass
{
	return [[dragItems objectAtIndex:0] class];
}

+ (id) GetFirstItem
{
	return [dragItems objectAtIndex:0];
}

+ (void) EndDrag
{
	dragItems = nil;
	dragSource = nil;
}


+ (void) runAlertWithMessage:(NSString*)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:message];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TEXT UTILITIES


+ (void) stripNewLinesFrom: (NSMutableAttributedString*) aString
{
	[aString beginEditing];
	
	unsigned int beginningOfString = 0;
	
	unsigned int firstNonWhitespace = [self findNextNonWhitespaceAfterIndex: beginningOfString attributedString: aString];
	[self removeNewLinesFromFront: aString inRange: NSMakeRange(beginningOfString, (firstNonWhitespace - beginningOfString))];
			
	unsigned int endOfString = [aString length]-1;
		
	unsigned int lastNonWhitespace = 1 + [self findNextNonWhitespaceBeforeIndex: endOfString attributedString: aString];	

	unsigned int length = (int)endOfString-(int)lastNonWhitespace;

	[Utility removeNewLinesFromEnd: aString inRange: NSMakeRange(lastNonWhitespace, length)];
	
	[aString endEditing];

}

+ (void) removeNewLinesFromFront: (NSMutableAttributedString *) string inRange: (NSRange) range
{
	[[string mutableString] replaceOccurrencesOfString: @"\n" withString: @"" options: NSCaseInsensitiveSearch range: range];
}

+ (void) removeNewLinesFromEnd: (NSMutableAttributedString *) string inRange: (NSRange) range
{

	[[string mutableString] deleteCharactersInRange: NSMakeRange(range.location, [string length] - range.location)];
	
}

// Returns the index of the next non whitespace character starting from index, can go either forward or backward
+ (int) findNextNonWhitespaceAfterIndex: (int) i attributedString: aString
{

	NSCharacterSet * whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	// Check parameters
	NSAssert(i >= 0 && i < [aString length], @"Exporter: findNextNonWhitespaceFromIndex: invalid index parameter");
	NSAssert([aString isKindOfClass:[NSAttributedString class]], @"Exporter: findNextNonWhitespaceFromIndex: invalid Attributed String parameter");

	// find next non-whitespace PAST i
	while (i < [aString length])
	{
		if (![whitespace characterIsMember: [[aString string] characterAtIndex: i]]) return i;
		i++;
	}
		
	return NSNotFound;
}

// Returns the index of the next non whitespace character starting from index, can go either forward or backward
+ (int) findNextNonWhitespaceBeforeIndex: (int) i attributedString: aString
{
	NSCharacterSet * whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	// Check parameters
	NSAssert(i >= 0 && i < [aString length], @"Exporter: findNextNonWhitespaceFromIndex: invalid index parameter");
	NSAssert([aString isKindOfClass:[NSAttributedString class]], @"Exporter: findNextNonWhitespaceFromIndex: invalid Attributed String parameter");
	
	// find next non-whitespace PAST i
	while (i >= 0)
	{
		if (![whitespace characterIsMember: [[aString string] characterAtIndex: i]]) return i;
		i--;
	}
		
	return NSNotFound;
}

+ (NSRange) rangeByTrimmingWhitspaceFromSelection: (NSRange) selectedRange attributedString: (NSAttributedString*) attrString
{

	int beginningIndex = [Utility findNextNonWhitespaceAfterIndex:selectedRange.location attributedString:attrString];
	int endIndex = [Utility findNextNonWhitespaceBeforeIndex:NSMaxRange(selectedRange) - 1 attributedString:attrString];
	
	NSAssert(beginningIndex != NSNotFound && endIndex != NSNotFound, @"non-whitespace not found!");
	
	return NSMakeRange(beginningIndex, selectedRange.length - (beginningIndex - selectedRange.location) - (NSMaxRange(selectedRange) - 1 - endIndex));
}

+ (NSCharacterSet *)whitespaceAndPunctuationSet
{
   if (!cachedSet)
   {
       NSMutableCharacterSet *tempSet = [NSMutableCharacterSet whitespaceCharacterSet];
       [tempSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

       cachedSet = [tempSet copy];
	   [tempSet autorelease];
 }

   return cachedSet;
}

+ (NSRange) rangeOfParagraphForCharacterAtIndex: (int) index textView: (NSTextView*) textView
{
	int beginnning;
	int end;
	NSRange result;
	unsigned int length = [[textView textStorage] length];
	
	// is the index at the last character?
	if (index > length - 1) 
	{
		result = [[[textView textStorage] string] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, index)];
	}
	else
	{
		result = [[[textView textStorage] string] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, index + 1)];
	}
	
	// did we get a result?
	if (result.location != NSNotFound)
	{
		beginnning = result.location;
	}
	else
	{
		beginnning = 0;
	}
	
	result = [[[textView textStorage] string] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:NSMakeRange(index, length - index)];
	
	if (result.location != NSNotFound)
	{
		end = result.location;
	}
	else
	{
		end = length - 1;
	}
	
	NSLog(@"Paragraph location = %d, length = %d, end = %d", beginnning, end - beginnning, end);
	
	return NSMakeRange(beginnning, end - beginnning);
}

		

#pragma mark Word Count 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WORD COUNT 


+ (unsigned) wordCountForAttributedString:(NSAttributedString*) attrString
{
	return [Utility wordCountForString: [attrString string]];
}


+ (unsigned) wordCountForString:(NSString *)textString
{
   NSScanner *wordScanner = [NSScanner scannerWithString:textString];
   NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceCharacterSet];
   NSCharacterSet *skipSet = [Utility whitespaceAndPunctuationSet];
   [wordScanner setCharactersToBeSkipped:skipSet];

   unsigned wordCount = 0;
   while ([wordScanner scanUpToCharactersFromSet:whiteSpace intoString:nil]) {wordCount++;}

   return wordCount;
}



+ (unsigned) altWordCountForString:(NSString *)textString
{
   NSScanner *wordScanner = [NSScanner scannerWithString:textString];
   NSCharacterSet *nonLetters = [[NSCharacterSet letterCharacterSet] invertedSet];
   [wordScanner setCharactersToBeSkipped:nonLetters];

   unsigned wordCount = 0;
   while ([wordScanner scanUpToCharactersFromSet:nonLetters intoString:nil]) {wordCount++;}

   return wordCount;
}


#pragma mark Alert and Exception  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ALERT & EXCEPTION

+ (void) throwAlertWithMessage:(NSString*) message
{
	NSAlert * theAlert = [[NSAlert alloc] init];
	[theAlert setMessageText:message];
	[theAlert runModal];
	[theAlert release];
}

+ (void) throwExceptionWithMessage:(NSString*) message
{

	NSException* myException = [NSException
								exceptionWithName:@"Utility"
								reason:message
								userInfo:nil];
							@throw myException;
}


#pragma mark Diagnostics
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DIAGNOSTICS

+ (void) printRect: (NSRect) rect
{
	NSLog(@"Rect {{x = %1.1f, y = %1.1f} , {w = %1.1f, h=%1.15}}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void) printArrayInfo: (NSArray*) array
{
	NSLog(@"\n\nArray Info: \nCount = %d", [array count]);
	
	int i;
	for (i=0; i<[array count]; i++)
	{
		NSLog(@"Object %d; retain count = %d", i, [[array objectAtIndex:i] retainCount]);
		NSLog(@"Parent retain count = %d", [[[array objectAtIndex:i] parent] retainCount]);
	}
}

+ (void) printViewInfo: (NSView*) view
{
	
	NSRect frame = [view frame];
	NSRect bounds = [view bounds];
	
	NSLog(@"(%@) Frame = {{%1.1f, %1.1f}, {%1.1f, %1.1f}}, Bounds = {{%1.1f, %1.1f}, {%1.1f, %1.1f}}", [view className], frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
		  bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	
	
}

NSString * RangeToString(NSRange aRange)
{
	return [NSString stringWithFormat:@"Range.location = %d, length = %d", aRange.location, aRange.length];
}


#pragma mark Menu
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Menu

+ (void) removeAllItemsFromMenu: (NSMenu*) menu
{
	NSEnumerator * enumerator = [[menu itemArray] objectEnumerator];
	id item;
	while (item = [enumerator nextObject])
	{
		[menu removeItem:item];
	}
}


#pragma mark Key States
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

BOOL ShiftKey()
{
	if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask)
	{
		//NSLog(@"modifier key down!");
		return TRUE;
	}
	else
	{
		//NSLog(@"modifier key NOT down!");
		return FALSE;
	}	
}

BOOL OptionKey()
{
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
		//NSLog(@"modifier key down!");
		return TRUE;
	}
	else
	{
		//NSLog(@"modifier key NOT down!");
		return FALSE;
	}	
}


BOOL CommandKey()
{
	if (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)
	{
		//NSLog(@"modifier key down!");
		return TRUE;
	}
	else
	{
		//NSLog(@"modifier key NOT down!");
		return FALSE;
	}	
}


BOOL ControlKey()
{
	if (([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) == NSControlKeyMask)
	{
		//NSLog(@"modifier key down!");
		return TRUE;
	}
	else
	{
		//NSLog(@"modifier key NOT down!");
		return FALSE;
	}	
}

NSString * MyStringFromRect(NSRect rect)
{
	return [NSString stringWithFormat:@"{{ %6.1f, %6.1f } { %6.1f, %6.1f }}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

NSString * MyStringFromObject(id object)
{
	return [NSString stringWithFormat:@"%p", object];
}
void LogTextSystemForLayoutManagers(NSArray * arrayOfLayoutManagers)
{
	NSEnumerator * etr = [arrayOfLayoutManagers objectEnumerator];
	NSLayoutManager * next;
	while (next = [etr nextObject])
	{
		LogTextSystemForLayoutManager(next);
	}
}

void LogTextSystemForLayoutManager(NSLayoutManager* layoutManager)
{
	NSLog(@"\n");
	NSLog(@"-------------------------------------------------------------------------------------------------");
	NSLog(@"\n");
	NSArray * textContainers = [layoutManager textContainers];
	NSLog(@"Layout Manager (%p) - text storage %d - has %d text containers.", layoutManager, [layoutManager textStorage], [textContainers count]);
	
	if ([layoutManager backgroundLayoutEnabled]) NSLog(@"Background Layout Enabled : YES");
	else NSLog(@"Background Layout Enabled : NO");

	if ([layoutManager allowsNonContiguousLayout]) NSLog(@"Non-Contiguous Layout Enabled : YES");
	else NSLog(@"Non-Contiguous Layout Enabled : NO");
	
	NSLog(@"\n");
	
	NSEnumerator * etr = [textContainers objectEnumerator];
	NSTextContainer * nextContainer;
	
	while (nextContainer = [etr nextObject])
	{
		NSLog(@"--%@", [nextContainer description]);
		NSLog(@"----%@", [[nextContainer textView] description]);
	}
	
	NSLog(@"\n");
	NSLog(@"-------------------------------------------------------------------------------------------------");
	NSLog(@"\n");	
	
}

+ (void) enqueueNotificationWithName:(NSString*)name object:(id) object
{
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:name object:object] postingStyle:NSPostWhenIdle];
}

@end
