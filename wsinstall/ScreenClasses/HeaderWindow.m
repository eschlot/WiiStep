//
//  HeaderWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "HeaderWindow.h"
#import "MainScreen_Private.h"

@interface HeaderWindow () {
    @private
    WINDOW* window;
    char progChar1;
    char progChar2;
}
@end

@implementation HeaderWindow

+ (id)headerWindowInScreenWindow:(WINDOW*)screen {
    HeaderWindow* me = [HeaderWindow new];
    me->window = subwin(screen, 1, 0, 0, 0);
    [me progIdx:0];
    return me;
}

/* If we need to draw a progress character, set here */
char PROG_CHARS[4] = {'-','\\','|','/'};
- (void)progIdx:(char)pc {
    pc %= 4;
    progChar1 = PROG_CHARS[pc];
    progChar2 = PROG_CHARS[(4-pc)%4];
}

/* This is the actual draw routine */
#define WS_INSTALLER "WiiStep Installer"
#define WS_INSTALLER_LEN sizeof(WS_INSTALLER)+1
- (void)doDrawLines:(int)lines Cols:(int)cols {
    int cjo = center_justify_off(WS_INSTALLER_LEN, cols);
    mvwaddch(window, 0, cjo-1, progChar1 | A_BOLD);
    wmove(window, 0, cjo);
    wbkgd(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    wattrset(window, COLOR_PAIR(COLOR_POPPING_TEXT));
    wattron(window, A_BOLD);
    waddstr(window, WS_INSTALLER);
    waddch(window, progChar2 | A_BOLD);
}
- (void)doRefresh {curs_set(0); wrefresh(window);}

@end
