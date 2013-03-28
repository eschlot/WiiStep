//
//  ProgressWindow.m
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import "ProgressWindow.h"
#import "MainScreen_Private.h"
#import <curses.h>

@interface ProgressWindowBar () {
    @package
    BOOL fail;
    NSString* text;
    double percent_fac;
}
- (void)drawIntoWindow:(WINDOW*)win line:(int)line leftMargin:(int)x_start rightMargin:(int)x_end;
@end

@implementation ProgressWindowBar
- (void)drawIntoWindow:(WINDOW *)win line:(int)line leftMargin:(int)x_start rightMargin:(int)x_end {
    // Can't make antimatter
    if (x_start > x_end)
        return;
    
    // Attributes
    int barAttr = fail?COLOR_PAIR(COLOR_ERROR_TEXT)|A_STANDOUT:COLOR_PAIR(COLOR_POPPING_TEXT)|A_STANDOUT;
    int normAttr = COLOR_PAIR(COLOR_NORMAL_TEXT);
    
    int total_cols = x_end - x_start + 1;
    
    // Pad out string
    NSMutableString* padded_str = [NSMutableString stringWithString:text];
    if (!fail)
        [padded_str appendFormat:@" [%lu%c]",(unsigned long)(percent_fac*100),'%'];
    int rem_chars = total_cols - (int)[padded_str length];
    int i;
    if (rem_chars > 0)
        for (i=0;i<rem_chars;++i)
            [padded_str appendString:@" "];
    
    int filled_cols = total_cols * percent_fac;
    int rem_cols = total_cols - filled_cols;
    wmove(win, line, x_start);
    wattrset(win, barAttr);
    waddnstr(win, [padded_str UTF8String], filled_cols);
    wattrset(win, normAttr);
    waddnstr(win, [padded_str UTF8String]+filled_cols, rem_cols);
}
@end

#pragma mark -

@interface ProgressWindow () {
    @private
    MainScreen* mainScreen;
    WINDOW* window;
    
    // Bar stuff
    ProgressWindowBar* installBar;
    NSMutableArray* bars;
    
    // Update queue
    dispatch_queue_t upd_queue;
}
@end

@implementation ProgressWindow

+ (id)progressWindowInMainScreen:(MainScreen*)ms {
    ProgressWindow* me = [ProgressWindow new];
    me->mainScreen = ms;
    me->window = nil;
    me->bars = [NSMutableArray array];
    me->upd_queue = dispatch_queue_create("org.resinbros.wsinstall.progupdqueue", 0);
    me->installBar = [ProgressWindowBar new];
    me->installBar->fail = NO;
    me->installBar->percent_fac = 0.0;
    me->installBar->text = @"Installing...";
    return me;
}
- (void)dealloc {
    delwin(window);
}

/* Draw Routine */
- (void)doDrawLines:(int)lines Cols:(int)cols {
    dispatch_sync(upd_queue, ^{
        delwin(window);
        int avail_lines = lines-2;
        window = subwin(mainScreen->screen, avail_lines, cols, 1, 0);
        int total_lines = (int)[bars count];
        int cur_actual_line = 0;
        int cur_draw_line = 0;
        for (ProgressWindowBar* bar in bars) {
            if (total_lines > avail_lines && cur_actual_line < total_lines-avail_lines) {
                ++cur_actual_line;
                continue;
            }
            [bar drawIntoWindow:window line:cur_draw_line leftMargin:0 rightMargin:cols-1];
            ++cur_actual_line;
            ++cur_draw_line;
        }
    });
}
- (void)doRefresh {curs_set(0); wrefresh(window);}


#pragma mark Downloader Delegate Implementations

/* Downloader began successfully */
- (void)downloadBegan:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        ProgressWindowBar* bar = [ProgressWindowBar new];
        bar->fail = NO;
        bar->percent_fac = 0.0;
        bar->text = [NSString stringWithFormat:@"Download: %@", entry->name];
        [bars addObject:bar];
        entry->dl_bar = bar;
    });
}

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(SFHash*)entry reason:(NSString*)reason {
    dispatch_sync(upd_queue, ^{
        ProgressWindowBar* bar = [ProgressWindowBar new];
        bar->fail = YES;
        bar->percent_fac = 1.0;
        bar->text = [NSString stringWithFormat:@"Download: %@ [FAIL: %@]", entry->name, reason];
        [bars addObject:bar];
        entry->dl_bar = bar;
    });
}

/* Downloader progress update */
- (void)download:(SFHash*)entry progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes {
    dispatch_sync(upd_queue, ^{
        if ([outOfBytes integerValue])
            entry->dl_bar->percent_fac = [currentBytes doubleValue]/[outOfBytes doubleValue];
        else
            entry->dl_bar->percent_fac = 0.5;
    });
}

/* Download completed */
- (void)downloadCompleted:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        entry->dl_bar->percent_fac = 1.0;
    });
}

/* Decompress began */
- (void)downloadBeganDecompress:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        ProgressWindowBar* bar = [ProgressWindowBar new];
        bar->fail = NO;
        bar->percent_fac = 0.5;
        bar->text = [NSString stringWithFormat:@"Decompress: %@", entry->name];
        [bars addObject:bar];
        entry->decomp_bar = bar;
    });
}

/* Decompress failed */
- (void)downloadFailedToDecompress:(SFHash*)entry failCode:(int)failCode {
    dispatch_sync(upd_queue, ^{
        entry->decomp_bar->fail = YES;
        entry->decomp_bar->percent_fac = 1.0;
        entry->decomp_bar->text = [NSString stringWithFormat:@"Decompress: %@ [FAIL: %d]", entry->name, failCode];
    });
}

/* Decompress completed */
- (void)downloadCompletedDecompress:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        entry->decomp_bar->fail = NO;
        entry->decomp_bar->percent_fac = 1.0;
        entry->decomp_bar->text = [NSString stringWithFormat:@"Decompress: %@", entry->name];
    });
}

/* Unarchive began */
- (void)downloadBeganUnarchive:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        ProgressWindowBar* bar = [ProgressWindowBar new];
        bar->fail = NO;
        bar->percent_fac = 0.5;
        bar->text = [NSString stringWithFormat:@"Unarchive: %@", entry->name];
        [bars addObject:bar];
        entry->unarc_bar = bar;
    });
}

/* Unarchive failed */
- (void)downloadFailedToUnarchive:(SFHash*)entry failCode:(int)failCode {
    dispatch_sync(upd_queue, ^{
        entry->unarc_bar->fail = YES;
        entry->unarc_bar->percent_fac = 1.0;
        entry->unarc_bar->text = [NSString stringWithFormat:@"Unarchive: %@ [FAIL: %d]", entry->name, failCode];
    });
}

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(SFHash*)entry {
    dispatch_sync(upd_queue, ^{
        entry->unarc_bar->fail = NO;
        entry->unarc_bar->percent_fac = 1.0;
        entry->unarc_bar->text = [NSString stringWithFormat:@"Unarchive: %@", entry->name];
    });
}

- (void)addInstallBar {
    dispatch_sync(upd_queue, ^{
        [bars addObject:installBar];
        installBar->percent_fac = 0.5;
    });
}
- (void)installBarComplete {
    dispatch_sync(upd_queue, ^{
        installBar->percent_fac = 1.0;
    });
}

@end
