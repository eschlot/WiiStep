//
//  MultiLineWrapper.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import <curses.h>

/* An immutable multi-line string wrapping buffer for repeated drawing
 * into a curses subwindow */

@interface MultiLineWrapper : NSObject

+ (id)multiLineWrapperWithInputString:(NSString*)str;

- (int)dryRunForLineCountWithLeftMarginCol:(int)x_start rightMarginCol:(int)x_end;

- (void)drawIntoWindow:(WINDOW*)cWin topMarginLine:(int)y_start leftMarginCol:(int)x_start bottomMarginLine:(int)y_end rightMarginCol:(int)x_end;

@end
