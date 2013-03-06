//
//  MainScreen_Private.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "MainScreen.h"

/* Ncurses color pair enumerations */
#define COLOR_NORMAL_TEXT 1
#define COLOR_POPPING_TEXT 2
#define COLOR_ERROR_TEXT 3
#define COLOR_SHADOW 4

@interface MainScreen () {
    @package
    WINDOW* screen;
}
@end
