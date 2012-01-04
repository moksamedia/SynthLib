//
//  AndromedaProgram.h
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
#import "AProgram.h"
#import "SynthLib.h"


@interface AndromedaProgram : AProgram 
{

}


// translate to and from 'packed' data format for A6
- (Byte) getByteFromData: (int) index;
- (void) writeByteToData: (Byte) byte atIndex: (int) index;
- (void) extractNameFromDataAndSetToName;
- (void) setNameToData;


@end
