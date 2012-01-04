//
//  Utility.h
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

#import <Cocoa/Cocoa.h>

/*
	Static Class to hold utility class methods used across the project, so as not to repeat code.
 */
@interface Utility : NSObject 
{

}

// DRAG & DROP
+ (NSArray*) GetDragItems;
+ (Class) GetDragClass;
+ (id) GetDragSource;
+ (void) StartDragWithSource: (id) source items: (NSArray*) items;
+ (id) GetFirstItem;
+ (void) EndDrag;

+ (void) runAlertWithMessage:(NSString*)message;

// FORMATTING
+ (void) removeNewLinesFromEnd: (NSMutableAttributedString *) string inRange: (NSRange) range;
+ (void) stripNewLinesFrom: (NSMutableAttributedString*) aString;
+ (void) removeNewLinesFromFront: (NSMutableAttributedString *) string inRange: (NSRange) range;
+ (int) findNextNonWhitespaceBeforeIndex: (int) i attributedString: aString;
+ (int) findNextNonWhitespaceAfterIndex: (int) i attributedString: aString;
+ (NSCharacterSet *)whitespaceAndPunctuationSet;
+ (NSRange) rangeOfParagraphForCharacterAtIndex: (int) index textView: (NSTextView*) textView;
+ (NSRange) rangeByTrimmingWhitspaceFromSelection: (NSRange) selectedRange attributedString: (NSAttributedString*) attrString;

//+ (NSString*) convertQuotesAndDashesToASCII:(NSString*)toFix;

// WORD COUNT
//+ (unsigned) averageWordCountForString: (NSString*) textString;
//+ (unsigned) averageWordCountForAttributedString: (NSAttributedString*) attrString;
+ (unsigned) wordCountForAttributedString:(NSAttributedString *)attrString;
+ (unsigned) wordCountForString:(NSString *)textString;
//+ (unsigned) altWordCountForString:(NSString *)textString;
//+ (unsigned) altWordCountForAttributedString:(NSAttributedString *)attrString;
//+ (unsigned) altWordCountForAttributedString:(NSAttributedString *)attrString excludeIntertextNotes: (BOOL) excludeIntertextNotes;

// ALERT & EXCEPTION
+ (void) throwAlertWithMessage:(NSString*) message;
+ (void) throwExceptionWithMessage:(NSString*) message;

// DIAGNOSTICS
+ (void) printRect: (NSRect) rect;
+ (void) printArrayInfo: (NSArray*) array;
+ (void) printViewInfo: (NSView*) view;

NSString * MyStringFromRect(NSRect rect);
NSString * MyStringFromObject(id object);
void LogTextSystemForLayoutManager(NSLayoutManager* layoutManager);
void LogTextSystemForLayoutManagers(NSArray * arrayOfLayoutManagers);

NSArray * GetAllLayoutManagersForTextViews(NSArray* arrayOfViews);

NSString * RangeToString(NSRange aRange);

// MENU
+ (void) removeAllItemsFromMenu: (NSMenu*) menu;

// MODIFIER KEY STATES
BOOL ShiftKey();
BOOL OptionKey();
BOOL CommandKey();
BOOL ControlKey();

// NOTIFICATIONS
+ (void) enqueueNotificationWithName:(NSString*)name object:(id) object;


@end
