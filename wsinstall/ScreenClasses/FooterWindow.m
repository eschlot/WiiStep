//
//  FooterWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "FooterWindow.h"

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
#define Q_TO_QUIT "Press 'q' to quit"
#define Q_TO_QUIT_LEN sizeof(Q_TO_QUIT)+1
- (void)doDrawLines:(int)lines Cols:(int)cols {
    delwin(window);
    window = subwin(screen, 1, 0, lines-1, 0);
    wbkgd(window, COLOR_PAIR(1));
    waddstr(window, "github.com/jackoalan/WiiStep");
    wmove(window, 0, cols-Q_TO_QUIT_LEN);
    waddstr(window, Q_TO_QUIT);
}

@end
