//
//  OneLineInputWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "OneLineInputWindow.h"
#import "MainScreen_Private.h"
#import <curses.h>

@interface OneLineInputWindow () {
    @private
    WINDOW* window;
    WINDOW* shadow;
    MainScreen* mainScreen;
    NSString* title;
    int titleAttr;
    NSString* prompt;
    int promptAttr;
    NSString* value;
    id <InputWindowDelegate> delegate;
}
@end

@implementation OneLineInputWindow

/* Insert into main screen */
+ (id)oneLineInputInMainScreen:(MainScreen*)ms title:(NSString*)title titleAttr:(int)titleAttr prompt:(NSString*)prompt promptAttr:(int)promptAttr defaultValue:(NSString*)defaultValue delegate:(id <InputWindowDelegate>)delegate {
    OneLineInputWindow* me = [OneLineInputWindow new];
    me->window = nil;
    me->shadow = nil;
    me->mainScreen = ms;
    me->title = title;
    me->titleAttr = titleAttr;
    me->prompt = prompt;
    me->promptAttr = promptAttr;
    me->value = defaultValue;
    me->delegate = delegate;
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
    int win_cols = (cols-2 < WIN_COLS)?cols-2:WIN_COLS;
    
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
    
    // Draw prompt text
    wattrset(window, promptAttr);
    wmove(window, 1, 1);
    waddstr(window, [prompt UTF8String]);
    
    // Draw field
    wattrset(window, COLOR_PAIR(1));
    wattron(window, A_STANDOUT);
    wmove(window, 2, 1);
    int i;
    for(i=1;i<win_cols-1;++i)
        waddch(window, ' ');
    wmove(window, 2, 1);
    waddstr(window, [value UTF8String]);
    wattroff(window, A_STANDOUT);
    
    // Draw usage text
    wmove(window, 3, 1);
    wattrset(window, COLOR_PAIR(1));
    waddstr(window, USAGE_1);
    wattrset(window, COLOR_PAIR(3));
    waddstr(window, USAGE_2);
    wattrset(window, COLOR_PAIR(1));
    waddstr(window, USAGE_3);
    wattrset(window, COLOR_PAIR(3));
    waddstr(window, USAGE_4);
    wattrset(window, COLOR_PAIR(1));
    waddstr(window, USAGE_5);
    
}

/* Input handler */
- (void)receiveInputCharacter:(char)aChar {
    //[akh receiver:self sentCapturableKeyPress:aChar];
}


@end
