//
//  InitialCheckWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "InitialCheckWindow.h"
#import "MainScreen_Private.h"
#import "MultiLineWrapper.h"
#import <curses.h>

@interface InitialCheckWindow () {
    @private
    MainScreen* mainScreen;
    NSArray* missingItems;
    WINDOW* window;
    WINDOW* shadow;
    MultiLineWrapper* testWrapper;
}
@end

@implementation InitialCheckWindow

/* Insert into main screen */
+ (id)initialCheckWindowInMainScreen:(MainScreen*)ms withMissingItems:(NSArray*)items {
    InitialCheckWindow* me = [InitialCheckWindow new];
    me->mainScreen = ms;
    me->missingItems = items;
    me->window = nil;
    me->shadow = nil;
    me->testWrapper = [MultiLineWrapper multiLineWrapperWithInputString:@"Loremlonglonglonglonglong ipsum dolor sit amet, consectetur adipiscing elit. Aliquam et nisi eros, adipiscing pellentesque urna. Curabitur ullamcorper, augue hendrerit placerat interdum, mi enim lacinia lorem, at convallis dolor lectus in turpis. Nunc bibendum faucibus urna nec suscipit. Vivamus lacinia viverra facilisis. Mauris adipiscing bibendum est ut ullamcorper."];
    return me;
}

/* Draw Routine */
#define WIN_LINES 4
#define WIN_COLS 70
#define WINDOW_HEADER "[Missing Dependencies]"
#define WINDOW_HEADER_LEN sizeof(WINDOW_HEADER)
- (void)doDrawLines:(int)lines Cols:(int)cols {
    // Cols calculated first
    int win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    
    // Window multi-line body line count
    int body_line_count = [testWrapper dryRunForLineCountWithLeftMarginCol:1 rightMarginCol:win_cols-1];
    int low_capped_lines = (body_line_count+2<WIN_LINES)?WIN_LINES:body_line_count+2;
    
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
    
    // Draw window header text
    wmove(window, 0, center_justify_off(WINDOW_HEADER_LEN, win_cols));
    wattron(window, A_BOLD);
    wattrset(window, COLOR_PAIR(4));
    waddstr(window, WINDOW_HEADER);
    //wprintw(window, "%d", body_line_count);
    wattroff(window, A_BOLD);
    
    // Draw body text
    wattrset(window, COLOR_PAIR(1));
    [testWrapper drawIntoWindow:window topMarginLine:1 leftMarginCol:1 bottomMarginLine:win_lines rightMarginCol:win_cols-1];
    
}

/* Input handler */
- (void)receiveInputCharacter:(char)aChar {
    
}

@end
