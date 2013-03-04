//
//  MultiLineWrapper.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "MultiLineWrapper.h"
#import "ScreenDrawable.h"

@interface MultiLineWrapper () {
    @private
    NSArray* myWords;
}
@end

@implementation MultiLineWrapper

+ (id)multiLineWrapperWithInputString:(NSString*)str {
    MultiLineWrapper* me = [MultiLineWrapper new];
    me->myWords = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return me;
}

- (int)dryRunForLineCountWithLeftMarginCol:(int)x_start rightMarginCol:(int)x_end {
    // Can't make antimatter
    if (x_start > x_end)
        return 0;
    
    // Enumerate words (and keep track of accumulated characters)
    int cur_line_col = x_start;
    int cur_line = 1;
    for (NSString* word in myWords) {
        // Available space remaining on line
        int avail_line_space = x_end-cur_line_col;
        
        // Actual word length (0 length is actually a space)
        NSUInteger word_length = [word length];
        if (!word_length)
            word_length = 1;
        
        // Spill onto next line if needed
        if (word_length >= avail_line_space) {
            cur_line_col = x_start;
            ++cur_line;
            avail_line_space = x_end-cur_line_col;
        }
        
        // Handle case where one word is longer than a line (maybe it's German)
        if (word_length >= avail_line_space) {
            cur_line_col = x_end;
        } else {
            cur_line_col += word_length+1;
        }
    }
    
    return cur_line;
}

- (void)drawIntoWindow:(WINDOW*)cWin topMarginLine:(int)y_start leftMarginCol:(int)x_start bottomMarginLine:(int)y_end rightMarginCol:(int)x_end {
    // Can't make antimatter
    if (y_start > y_end || x_start > x_end)
        return;
    
    // Set cursor to top-left margin
    wmove(cWin, y_start, x_start);
    
    // Enumerate words (and keep track of accumulated characters)
    int cur_line_col = x_start;
    int cur_line = y_start;
    for (NSString* word in myWords) {
        // Available space remaining on line
        int avail_line_space = x_end-cur_line_col;
        
        // Actual word length (0 length is actually a space)
        NSUInteger word_length = [word length];
        if (!word_length)
            word_length = 1;
        
        // Spill onto next line if needed
        if (word_length >= avail_line_space) {
            cur_line_col = x_start;
            ++cur_line;
            if (cur_line > y_end) // Stop if we run out of vertical space
                break;
            wmove(cWin, cur_line, cur_line_col);
            avail_line_space = x_end-cur_line_col;
        }
        
        // Handle case where one word is longer than a line (maybe it's German)
        if (word_length >= avail_line_space) {
            char truncated_word[512];
            truncate_string([word UTF8String], (avail_line_space>500)?500:avail_line_space, truncated_word);
            waddstr(cWin, truncated_word);
            cur_line_col = x_end;
        } else {
            waddstr(cWin, [word UTF8String]);
            waddch(cWin, ' ');
            cur_line_col += word_length+1;
        }
    }
}

@end
