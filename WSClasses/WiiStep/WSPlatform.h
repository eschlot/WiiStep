//
//  WSPlatform.h
//  WiiStep
//
//  Created by Jack Andersen on 4/14/13.
//
//

#import <Foundation/Foundation.h>

/* This class contains class methods to interface with
 * various aspects of the Wii's hardware and software
 * platform. These methods should be considered
 * NOT THREAD SAFE!! */

@interface WSPlatform : NSObject
+ (void)initialize; // Called automatically

#pragma mark Disc Slot LED

/* Disc slot blue LED control */
+ (void)setDiscLEDEnabled:(BOOL)enabled;

/* Levels are expressed as normalised floats [0.0-1.0] */
+ (float)discLEDLevel;
+ (void)setDiscLEDLevel:(float)level;

@end
