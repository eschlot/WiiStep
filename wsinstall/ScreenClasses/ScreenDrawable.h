//
//  ScreenDrawable.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>

#define center_justify_off(str_len, avail_len) ((avail_len)/2-(str_len)/2)
#define truncate_string(str, max_len, to_buf) strncpy(to_buf, str, (max_len)-3); strncpy(to_buf+(max_len)-3, "...", 4);

@protocol ScreenDrawable <NSObject>
- (void)doDrawLines:(int)lines Cols:(int)cols;
- (void)doRefresh;
@end
