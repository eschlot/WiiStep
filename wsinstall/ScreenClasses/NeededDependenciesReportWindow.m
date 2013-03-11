//
//  NeededDependenciesReportWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "NeededDependenciesReportWindow.h"
#import "MainScreen_Private.h"
#import "MultiLineWrapper.h"
#import <curses.h>

@interface NeededDependenciesReportWindow () {
@private
    MainScreen* mainScreen;
    WINDOW* window;
    WINDOW* shadow;
    NSString* title;
    int titleAttr;
    MultiLineWrapper* message;
    int messageAttr;
    NSArray* dependencies;
    int itemAttr;
    id <InputWindowDelegate> delegate;
}
@end

@implementation NeededDependenciesReportWindow

/* Insert into main screen */
+ (id)ndrWindowInMainScreen:(MainScreen*)ms windowTitle:(NSString*)title windowTitleAttr:(int)titleAttr message:(NSString*)msg messageAttr:(int)msgAttr dependencies:(NSArray*)deps itemAttr:(int)itemAttr inputDelegate:(id <InputWindowDelegate>)inputDelegate {
    NeededDependenciesReportWindow* me = [NeededDependenciesReportWindow new];
    me->mainScreen = ms;
    me->window = nil;
    me->shadow = nil;
    me->title = title;
    me->titleAttr = titleAttr;
    me->message = [MultiLineWrapper multiLineWrapperWithInputString:msg];
    me->messageAttr = msgAttr;
    me->dependencies = deps;
    me->itemAttr = itemAttr;
    me->delegate = inputDelegate;
    return me;
}

- (void)dealloc {
    delwin(window);
    delwin(shadow);
}

/* Draw Routine */
#define WIN_LINES 4
#define WIN_COLS 70
#define USAGE_1 "Press "
#define USAGE_2 "[RETURN]"
#define USAGE_3 " to confirm, or "
#define USAGE_4 "[ESC]"
#define USAGE_5 " to cancel"
- (void)doDrawLines:(int)lines Cols:(int)cols {
    // Cols calculated first
    int win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    
    // Window multi-line body line count
    int body_line_count = [message dryRunForLineCountWithLeftMarginCol:1 rightMarginCol:win_cols-1];
    int low_capped_lines = (body_line_count+(int)[dependencies count]+3<WIN_LINES)?WIN_LINES:body_line_count+(int)[dependencies count]+3;
    
    // Lines calcuated based on body + dependency count
    int win_lines = (lines-2 < low_capped_lines)?lines-2:low_capped_lines;
    
    // Draw window
    int win_y = center_justify_off(win_lines, lines);
    int win_x = center_justify_off(win_cols, cols);
    delwin(shadow);
    shadow = subwin(mainScreen->screen, win_lines, win_cols, win_y+1, win_x+1);
    wbkgd(shadow, COLOR_PAIR(COLOR_SHADOW));
    delwin(window);
    window = subwin(mainScreen->screen, win_lines, win_cols, win_y, win_x);
    wbkgd(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    box(window, 0, 0);
    
    // Draw window title text
    wmove(window, 0, center_justify_off((int)[title length], win_cols)-1);
    wattron(window, A_BOLD);
    wattrset(window, titleAttr);
    waddch(window, '[');
    waddstr(window, [title UTF8String]);
    waddch(window, ']');
    wattroff(window, A_BOLD);
    
    // Draw message text
    wattrset(window, messageAttr);
    [message drawIntoWindow:window topMarginLine:1 leftMarginCol:1 bottomMarginLine:win_lines-(int)[dependencies count] rightMarginCol:win_cols-1];
    
    // Draw dependency list
    int cur_line = win_lines-(int)[dependencies count]-2;
    for (NSString* dep in dependencies) {
        wmove(window, cur_line, 1);
        wattroff(window, A_UNDERLINE);
        waddch(window, ACS_DIAMOND | COLOR_PAIR(COLOR_POPPING_TEXT) | A_BOLD);
        waddch(window, ' ');
        wattrset(window, itemAttr);
        waddstr(window, [dep UTF8String]);
        ++cur_line;
    }
    
    // Draw usage text
    wmove(window, win_lines-2, 1);
    wattrset(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    waddstr(window, USAGE_1);
    wattrset(window, COLOR_PAIR(COLOR_POPPING_TEXT));
    waddstr(window, USAGE_2);
    wattrset(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    waddstr(window, USAGE_3);
    wattrset(window, COLOR_PAIR(COLOR_POPPING_TEXT));
    waddstr(window, USAGE_4);
    wattrset(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    waddstr(window, USAGE_5);
    
}
- (void)doRefresh {curs_set(0); wrefresh(window);}


/* Input handler */
- (void)receiveInputCharacter:(int)aChar {
    switch (aChar) {
        case '\n': // Return
            [delegate inputWindowOK:self];
            return;
        case 27: // Escape
            [delegate inputWindowCancel:self];
            return;
    }
}

@end
