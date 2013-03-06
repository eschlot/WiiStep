//
//  MainScreen.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <curses.h>
#import "TaskSelection.h"
#import "ProgressWindow.h"
#import "ScreenDrawable.h"
#import "ScreenInput.h"

@interface MainScreen : NSObject <ScreenDrawable>

/* Set current input window */
@property (nonatomic) id <ScreenDrawable> inputWindow;

/* Redraw (if content changes) */
- (void)redraw;

/* Redraw only one drawable (if that content changes) */
- (void)redrawDrawable:(id <ScreenDrawable>)drawable;

/* Main activate method (waits for user to do something in current mode) */
- (void)activate;

/* Deactivate method (breaks out of user input loop) */
- (void)deactivate;

@end
