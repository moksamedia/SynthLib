//
//  AGlobalDump.h
//  SynthLib
//
//  Created by Andrew Hughes on 1/29/09.
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

#import <Foundation/Foundation.h>
#import "ACollectionItem.h"

/*
	Global dump:
	- may not have to be sublcassed.
	- name initialized to current date and time
	- name NOT stored in dump itself, so no packing or unpacking of data
	- prog. num. and bank num. are meaningless, so they show up as "n/a"
 */
@interface AGlobalDump : ACollectionItem 
{

}

@end
