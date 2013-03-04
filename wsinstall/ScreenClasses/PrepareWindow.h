//
//  PrepareWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <curses.h>
#import "ScreenDrawable.h"

@interface PrepareWindow : NSObject <ScreenDrawable>

+ (id)prepareWindowInScreenWindow:(WINDOW*)screen;

/* Set text lines */
- (void)setLine1:(NSString*)str;
- (void)setLine2:(NSString*)str;

@end
