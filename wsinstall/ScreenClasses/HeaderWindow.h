//
//  HeaderWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <curses.h>
#import "ScreenDrawable.h"

@interface HeaderWindow : NSObject <ScreenDrawable>

+ (id)headerWindowInScreenWindow:(WINDOW*)screen;

@end
