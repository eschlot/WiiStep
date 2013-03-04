//
//  HeaderWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "HeaderWindow.h"

@interface HeaderWindow () {
    @private
    WINDOW* window;
}
@end

@implementation HeaderWindow

+ (id)headerWindowInScreenWindow:(WINDOW*)screen {
    HeaderWindow* me = [HeaderWindow new];
    me->window = subwin(screen, 1, 0, 0, 0);
    return me;
}

/* This is the actual draw routine */
#define WS_INSTALLER "WiiStep Installer"
#define WS_INSTALLER_LEN sizeof(WS_INSTALLER)+1
- (void)doDrawLines:(int)lines Cols:(int)cols {
    wmove(window, 0, center_justify_off(WS_INSTALLER_LEN, cols));
    wbkgd(window, COLOR_PAIR(1));
    wattrset(window, COLOR_PAIR(3));
    wattron(window, A_BOLD);
    waddstr(window, WS_INSTALLER);
}

@end
