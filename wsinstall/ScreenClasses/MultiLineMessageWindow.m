//
//  MultiLineMessageWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "MultiLineMessageWindow.h"
#import "MainScreen_Private.h"
#import "MultiLineWrapper.h"
#import <curses.h>

@interface MultiLineMessageWindow () {
@private
    MainScreen* mainScreen;
    WINDOW* window;
    WINDOW* shadow;
    NSString* title;
    int titleAttr;
    MultiLineWrapper* message;
    int messageAttr;
    id <EventCapturer> akh;
}
@end

@implementation MultiLineMessageWindow

/* Insert into main screen */
+ (id)messageWindowInMainScreen:(MainScreen*)ms windowTitle:(NSString*)title windowTitleAttr:(int)titleAttr message:(NSString*)msg messageAttr:(int)msgAttr anyKeyHandler:(id <EventCapturer>)anyKeyHandler {
    MultiLineMessageWindow* me = [MultiLineMessageWindow new];
    me->mainScreen = ms;
    me->window = nil;
    me->shadow = nil;
    me->title = title;
    me->titleAttr = titleAttr;
    me->message = [MultiLineWrapper multiLineWrapperWithInputString:msg];
    me->messageAttr = msgAttr;
    me->akh = anyKeyHandler;
    return me;
}

/* Draw Routine */
#define WIN_LINES 4
#define WIN_COLS 70
#define ANY_KEY "Press any key to continue..."
#define ANY_KEY_LEN sizeof(ANY_KEY)
- (void)doDrawLines:(int)lines Cols:(int)cols {
    // Cols calculated first
    int win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    
    // Window multi-line body line count
    int body_line_count = [message dryRunForLineCountWithLeftMarginCol:1 rightMarginCol:win_cols-1];
    int low_capped_lines = (body_line_count+3<WIN_LINES)?WIN_LINES:body_line_count+3;
    
    // Lines calcuated based on body
    int win_lines = (lines-2 < low_capped_lines)?lines-2:low_capped_lines;
    
    // Draw window
    int win_y = center_justify_off(win_lines, lines);
    int win_x = center_justify_off(win_cols, cols);
    delwin(shadow);
    shadow = subwin(mainScreen->screen, win_lines, win_cols, win_y+1, win_x+1);
    wbkgd(shadow, COLOR_PAIR(2));
    delwin(window);
    window = subwin(mainScreen->screen, win_lines, win_cols, win_y, win_x);
    wbkgd(window, COLOR_PAIR(1));
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
    [message drawIntoWindow:window topMarginLine:1 leftMarginCol:1 bottomMarginLine:win_lines rightMarginCol:win_cols-1];
    
    // Draw "any key" text
    wmove(window, win_lines-2, 1);
    wattron(window, A_BOLD);
    wattrset(window, titleAttr);
    waddstr(window, ANY_KEY);
    wattroff(window, A_BOLD);
    
}

/* Input handler */
- (void)receiveInputCharacter:(char)aChar {
    if (aChar != 410) // "Any key" except term resize
        [akh receiver:self sentCapturableKeyPress:aChar];
}

@end
