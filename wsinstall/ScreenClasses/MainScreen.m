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
#import "DirPromptWindow.h"
#import "MultiLineMessageWindow.h"
#import "DirPromptWindow.h"

@interface MainScreen () {
    @private
    HeaderWindow* header;
    FooterWindow* footer;
    
    id <ScreenInput, ScreenDrawable> currentInputWindow;
    
    BOOL deactivate;
    
    BOOL progIndicator;
    int progIdx;
    dispatch_queue_t progDrawQueue;
    dispatch_source_t progDrawTimer;
    
    // Download progress window
    ProgressWindow* currentProgWin;
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
    init_pair(COLOR_ERROR_TEXT, COLOR_RED+8, COLOR_WHITE);
    init_pair(COLOR_SHADOW, COLOR_BLACK+8, COLOR_BLACK+8);
    curs_set(0);
    noecho();
    keypad(screen, YES);
    header = [HeaderWindow headerWindowInScreenWindow:screen];
    footer = [FooterWindow footerWindowInScreenWindow:screen];
    currentInputWindow = nil;
    deactivate = NO;
    
    // Indeterminate progress whirlygig
    progIndicator = NO;
    progIdx = 0;
    progDrawQueue = dispatch_queue_create("org.resinbros.wsinstall.progDrawQueue", 0);
    progDrawTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, progDrawQueue);
    dispatch_source_set_timer(progDrawTimer, DISPATCH_TIME_NOW, NSEC_PER_SEC/15, NSEC_PER_MSEC*20);
    dispatch_source_set_event_handler(progDrawTimer, ^{
        ++progIdx;
        progIdx %= 4;
        if (progIndicator) {
            [header progIdx:progIdx];
            [self redrawDrawable:header];
            if (currentProgWin)
                [self redrawDrawable:currentProgWin];
            if (currentInputWindow)
                [currentInputWindow doRefresh];
        }
    });
    
    currentProgWin = nil;
    
    return self;
}

/* Set current input window and progress window */
@synthesize inputWindow=currentInputWindow;
@synthesize progWin=currentProgWin;

/* Redraw (if content changes) */
- (void)redraw {
    dispatch_sync(progDrawQueue, ^{
        [self redrawDrawable:self];
        if (currentProgWin)
            [currentProgWin doRefresh];
        if (currentInputWindow)
            [currentInputWindow doRefresh];
    });
}

/* Redraw only one drawable (if that content changes) */
- (void)redrawDrawable:(id <ScreenDrawable>)drawable {
    dispatch_block_t drawBlock = ^{
        int lines, cols;
        getmaxyx(screen, lines, cols);
        [drawable doDrawLines:lines Cols:cols];
        [drawable doRefresh];
    };
    if (dispatch_get_current_queue() == progDrawQueue)
        drawBlock();
    else
        dispatch_sync(progDrawQueue, drawBlock);
}

/* Main activate method (waits for user to do something with current window) */
- (void)activate {
    // Now our input loop
    while (TRUE) {
        if (deactivate)
            break;
        int c = wgetch(screen);
        // Handle xterm resize
        if (c == 410 || c == -1) {
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
    if (progIndicator)
        [header progIdx:progIdx];
    [header doDrawLines:lines Cols:cols];
    [footer doDrawLines:lines Cols:cols];
    [currentProgWin doDrawLines:lines Cols:cols];
    [currentInputWindow doDrawLines:lines Cols:cols];
}
- (void)doRefresh {curs_set(0); wrefresh(screen);}

/* Indeterminate progress indicator (on/off) */
- (BOOL)progIndicator {
    __block BOOL ret = NO;
    dispatch_sync(progDrawQueue, ^{
        ret = progIndicator;
    });
    return ret;
}
- (void)setProgIndicator:(BOOL)aprogIndicator {
    if (progIndicator == aprogIndicator)
        return;
    dispatch_sync(progDrawQueue, ^{
        progIndicator = aprogIndicator;
        if (progIndicator)
            dispatch_resume(progDrawTimer);
        else {
            dispatch_suspend(progDrawTimer);
            [header progIdx:0];
        }
    });
}

@end
