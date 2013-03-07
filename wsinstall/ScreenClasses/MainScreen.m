//
//  MainScreen.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "MainScreen_Private.h"
#import "HeaderWindow.h"
#import "FooterWindow.h"
#import "InitialCheckWindow.h"
#import "PrepareWindow.h"
#import "DirPromptWindow.h"
#import "MultiLineMessageWindow.h"
#import "DirPromptWindow.h"

@interface MainScreen () {
    @private
    HeaderWindow* header;
    FooterWindow* footer;
    
    id <ScreenInput, ScreenDrawable> currentInputWindow;
    
    BOOL deactivate;
}
@end

@implementation MainScreen

/* Establish main screen in window */
- (id)init {
    self = [super init];
    screen = initscr();
    start_color();
    init_pair(COLOR_NORMAL_TEXT, COLOR_WHITE, COLOR_BLUE);
    init_pair(COLOR_POPPING_TEXT, COLOR_WHITE+8, COLOR_BLUE);
    init_pair(COLOR_ERROR_TEXT, COLOR_RED+8, COLOR_BLUE);
    init_pair(COLOR_SHADOW, COLOR_BLACK+8, COLOR_BLACK+8);
    curs_set(0);
    noecho();
    keypad(screen, YES);
    header = [HeaderWindow headerWindowInScreenWindow:screen];
    footer = [FooterWindow footerWindowInScreenWindow:screen];
    currentInputWindow = nil;
    deactivate = NO;
    return self;
}

/* Set current input window */
@synthesize inputWindow=currentInputWindow;

/* Redraw (if content changes) */
- (void)redraw {
    [self redrawDrawable:self];
    if (currentInputWindow)
        [currentInputWindow doRefresh];
}

/* Redraw only one drawable (if that content changes) */
- (void)redrawDrawable:(id <ScreenDrawable>)drawable {
    int lines, cols;
    getmaxyx(screen, lines, cols);
    [drawable doDrawLines:lines Cols:cols];
    [drawable doRefresh];
}

/* Main activate method (waits for user to do something with current window) */
- (void)activate {
    while (TRUE) {
        if (deactivate)
            break;
        int c = wgetch(screen);
        // Handle xterm resize
        if (c == 410) {
            [self redraw];
        } else if (currentInputWindow) {
            [currentInputWindow receiveInputCharacter:c];
        } else if (c == 'q')
            break;
    }
}

/* Deactivate method (breaks out of user input loop) */
- (void)deactivate {
    deactivate = YES;
}

- (void)doDrawLines:(int)lines Cols:(int)cols {
    clear();
    wbkgd(screen, COLOR_PAIR(0));
    [header doDrawLines:lines Cols:cols];
    [footer doDrawLines:lines Cols:cols];
    [currentInputWindow doDrawLines:lines Cols:cols];
}
- (void)doRefresh {wrefresh(screen);}

@end
