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

@interface MainScreen () {
    @private
    HeaderWindow* header;
    FooterWindow* footer;
    
    id <ScreenInput, ScreenDrawable> currentInputWindow;
}
@end

@implementation MainScreen

/* Establish main screen in window */
- (id)init {
    self = [super init];
    screen = initscr();
    start_color();
    init_pair(1, COLOR_WHITE, COLOR_BLUE);
    init_pair(2, COLOR_BLACK+8, COLOR_BLACK+8);
    init_pair(3, COLOR_WHITE+8, COLOR_BLUE);
    init_pair(4, COLOR_RED+8, COLOR_BLUE);
    curs_set(0);
    noecho();
    header = [HeaderWindow headerWindowInScreenWindow:screen];
    footer = [FooterWindow footerWindowInScreenWindow:screen];
    currentInputWindow = [MultiLineMessageWindow messageWindowInMainScreen:self windowTitle:@"Test Title" windowTitleAttr:COLOR_PAIR(3) message:@"Loremlonglonglonglonglong ipsum dolor sit amet, consectetur adipiscing elit. Aliquam et nisi eros, adipiscing pellentesque urna. Curabitur ullamcorper, augue hendrerit placerat interdum, mi enim lacinia lorem, at convallis dolor lectus in turpis. Nunc bibendum faucibus urna nec suscipit. Vivamus lacinia viverra facilisis. Mauris adipiscing bibendum est ut ullamcorper." messageAttr:COLOR_PAIR(1) anyKeyHandler:nil];
    
    [self redraw];
    return self;
}

/* Set current input window */
- (void)setInputWindow:(id <ScreenDrawable, ScreenInput>)drawable {
    currentInputWindow = drawable;
}

/* Redraw (if content changes) */
- (void)redraw {
    [self redrawDrawable:self];
}

/* Redraw only one drawable (if that content changes) */
- (void)redrawDrawable:(id <ScreenDrawable>)drawable {
    int lines, cols;
    getmaxyx(screen, lines, cols);
    [drawable doDrawLines:lines Cols:cols];
}

/* Main activate method (waits for user to do something in current mode) */
- (void)activate {
    while (TRUE) {
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

- (void)doDrawLines:(int)lines Cols:(int)cols {
    clear();
    wbkgd(screen, COLOR_PAIR(0));
    [header doDrawLines:lines Cols:cols];
    [footer doDrawLines:lines Cols:cols];
    [currentInputWindow doDrawLines:lines Cols:cols];
    wrefresh(screen);
}

@end
