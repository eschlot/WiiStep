//
//  DirPromptWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "DirPromptWindow.h"

@interface DirPromptWindow () {
    @private
    WINDOW* screen;
    WINDOW* window;
    WINDOW* shadow;
    NSString* promptString;
    NSString* dirString;
}
@end

@implementation DirPromptWindow

+ (id)dirPromptInScreenWindow:(WINDOW*)screen prompt:(NSString*)prompt withDefaultDir:(NSString*)defaultDir {
    DirPromptWindow* me = [DirPromptWindow new];
    me->screen = screen;
    me->window = nil;
    me->shadow = nil;
    me->promptString = prompt;
    me->dirString = defaultDir;
    return me;
}

#define WIN_LINES 4
#define WIN_COLS 50
#define PREPARING "[Directory Prompt]"
#define PREPARING_LEN sizeof(PREPARING)
- (void)doDrawLines:(int)lines Cols:(int)cols {
    int win_lines = (lines-2 < WIN_LINES)?lines-2:WIN_LINES;
    int win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    int win_y = center_justify_off(win_lines, lines);
    int win_x = center_justify_off(win_cols, cols);
    delwin(shadow);
    shadow = subwin(screen, win_lines, win_cols, win_y+1, win_x+1);
    wbkgd(shadow, COLOR_PAIR(2));
    delwin(window);
    window = subwin(screen, win_lines, win_cols, win_y, win_x);
    wbkgd(window, COLOR_PAIR(1));
    box(window, 0, 0);
    
    // Prepare header text
    wmove(window, 0, center_justify_off(PREPARING_LEN, win_cols));
    wattron(window, A_BOLD);
    waddstr(window, PREPARING);
    wattroff(window, A_BOLD);
    
    // Status text line1
    char line1buf[256];
    truncate_string([promptString UTF8String], win_cols-2, line1buf);
    wmove(window, 1, 1);
    wattrset(window, COLOR_PAIR(3));
    waddstr(window, line1buf);
    
    // Entry field

}

- (void)activateForm {
    
}

- (NSString*)dir {
    return dirString;
}

- (void)setDir:(NSString *)dir {
    dirString = dir;
}

@end
