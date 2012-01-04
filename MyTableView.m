//
//  MyTableView.m
//  SynthLib
//
//  Created by Andrew Hughes on 12/23/08.
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

#import "MyTableView.h"


@implementation MyTableView

+ (NSMenu *)defaultMenu 
{
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
    [theMenu insertItemWithTitle:@"Edit Multiple Selection" action:@selector(editMultipleSelection:) keyEquivalent:@"" atIndex:0];
    return theMenu;
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
      return [[self class] defaultMenu];
}


@end
