//
//  FooterWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import "ScreenDrawable.h"
#import <curses.h>

@interface FooterWindow : NSObject <ScreenDrawable>

+ (id)footerWindowInScreenWindow:(WINDOW*)screen;

@end
