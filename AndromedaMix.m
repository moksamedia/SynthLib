//
//  AndromedaMix.m
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


#import "AndromedaMix.h"


@implementation AndromedaMix


- (id) initWithSynth: (ASynth*) _synth data: (NSMutableData *) _data
{
	if ((self = [super initWithSynth:_synth data:_data type:PROGRAM]))
	{
		numberOfPrograms = 128; // set to invalid numbers, must be overridden
		numberOfBanks = 2;
		type = PROGRAM;
	}
	return self;
}


@end
