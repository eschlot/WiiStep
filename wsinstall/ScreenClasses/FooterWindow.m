//
//  FooterWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "FooterWindow.h"
#import "MainScreen_Private.h"

@interface FooterWindow () {
@private
    WINDOW* screen;
    WINDOW* window;
}
@end

@implementation FooterWindow

+ (id)footerWindowInScreenWindow:(WINDOW*)screen {
    FooterWindow* me = [FooterWindow new];
    me->screen = screen;
    me->window = subwin(screen, 1, 0, LINES-1, 0);
    return me;
}

/* This is the actual draw routine */
#define COPY "(C)2013 Jack Andersen"
#define COPY_LEN sizeof(COPY)+1
- (void)doDrawLines:(int)lines Cols:(int)cols {
    delwin(window);
    window = subwin(screen, 1, 0, lines-1, 0);
    wbkgd(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    waddstr(window, "github.com/jackoalan/WiiStep");
    wmove(window, 0, cols-COPY_LEN);
    waddstr(window, COPY);
}
- (void)doRefresh {curs_set(0); wrefresh(window);}

@end
