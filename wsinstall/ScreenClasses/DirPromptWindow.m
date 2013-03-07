//
//  DirPromptWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "DirPromptWindow.h"
#import "MainScreen_Private.h"
#import <curses.h>
#import <readline/readline.h>

@interface DirPromptWindow () {
    @private
    WINDOW* window;
    WINDOW* shadow;
    MainScreen* mainScreen;
    NSString* title;
    int titleAttr;
    NSString* prompt;
    int promptAttr;
    NSMutableString* value;
    id <InputWindowDelegate> delegate;
    
    // Cursor input stuff
    int win_cols;
    size_t h_scroll;
    size_t c_pos;
}
@end

@implementation DirPromptWindow

/* Insert into main screen */
+ (id)dirPromptInMainScreen:(MainScreen*)ms title:(NSString*)title titleAttr:(int)titleAttr prompt:(NSString*)prompt promptAttr:(int)promptAttr defaultValue:(NSString*)defaultValue delegate:(id <InputWindowDelegate>)delegate {
    DirPromptWindow* me = [DirPromptWindow new];
    me->window = nil;
    me->shadow = nil;
    me->mainScreen = ms;
    me->title = title;
    me->titleAttr = titleAttr;
    me->prompt = prompt;
    me->promptAttr = promptAttr;
    me->value = (defaultValue)?[NSMutableString stringWithString:defaultValue]:@"";
    me->delegate = delegate;
    me->h_scroll = 0;
    me->c_pos = [me->value length];
    return me;
}

- (void)dealloc {
    delwin(window);
    delwin(shadow);
}

/* Draw Routine */
#define WIN_LINES 5
#define WIN_COLS 70
#define USAGE_1 "Press "
#define USAGE_2 "[RETURN]"
#define USAGE_3 " to confirm, or "
#define USAGE_4 "[ESC]"
#define USAGE_5 " to cancel"
#define USAGE_LEN sizeof(USAGE_1)+sizeof(USAGE_2)+sizeof(USAGE_3)+sizeof(USAGE_4)+sizeof(USAGE_5)
- (void)doDrawLines:(int)lines Cols:(int)cols {
    
    // Calculate actual window column and line count
    int win_lines = (lines-2 < WIN_LINES)?lines-2:WIN_LINES;
    win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    
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
    
    // Draw prompt text
    wattrset(window, promptAttr);
    wmove(window, 1, 1);
    waddstr(window, [prompt UTF8String]);
    
    // Draw usage text
    wmove(window, 3, 1);
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
- (void)doRefresh {
    // Draw field (heeding current horizontal scroll)
    wattrset(window, COLOR_PAIR(COLOR_NORMAL_TEXT));
    wattron(window, A_STANDOUT);
    wmove(window, 2, 1);
    int i;
    for(i=1;i<win_cols-1;++i)
        waddch(window, ' ');
    wmove(window, 2, 1);
    //wprintw(window, "%.s", win_cols-2, [value UTF8String]+h_scroll);
    waddstr(window, [value UTF8String]+h_scroll);
    wattroff(window, A_STANDOUT);
    // Position cursor on text at stored position and show it
    wmove(window, 2, (int)c_pos+1);
    curs_set(1);
    wrefresh(window);
}

/* Input handler */
- (void)receiveInputCharacter:(int)aChar {
    char* completed_path = NULL;
    char str_cast[2];
    switch (aChar) {
        case 260: // Left Arrow Key
            if (c_pos)
                --c_pos;
            else
                printf("\a");
            break;
        case 261: // Right Arrow Key
            ++c_pos;
            if (c_pos > [value length]) {
                c_pos = [value length];
                printf("\a");
            }
            break;
        case '\n': // Return
            [delegate inputWindowOK:self];
            return;
        case '\x7f': // Backspace
            if (c_pos) {
                [value deleteCharactersInRange:NSMakeRange(c_pos-1, 1)];
                [delegate inputWindow:self valueChangedTo:value];
                --c_pos;
            } else
                printf("\a");
            break;
        case 330: // Forward Delete
            if (c_pos < [value length]) {
                [value deleteCharactersInRange:NSMakeRange(c_pos, 1)];
                [delegate inputWindow:self valueChangedTo:value];
            } else
                printf("\a");
            break;
        case 27: // Escape
            [delegate inputWindowCancel:self];
            return;
        case 9: // Tab (autocomplete courtesy of libedit)
            completed_path = filename_completion_function([value UTF8String], 0);
            if (completed_path) {
                [value setString:@(completed_path)];
                [delegate inputWindow:self valueChangedTo:value];
                free(completed_path);
                c_pos = [value length];
            } else
                printf("\a");
            break;
        default: // Insert the character
            if (aChar < 0x20 || aChar > 0x7e) // Sanitise to legal characters
                break;
            str_cast[0] = aChar;
            str_cast[1] = '\0';
            [value insertString:@(str_cast) atIndex:c_pos];
            [delegate inputWindow:self valueChangedTo:value];
            ++c_pos;
            break;
    }
    [self doRefresh];
}

@synthesize value;

@end
