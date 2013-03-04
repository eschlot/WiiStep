//
//  SFDownloaderProgressStdout.m
//  WiiStep
//
//  Created by Jack Andersen on 3/2/13.
//
//

#import "SFDownloaderProgressStdout.h"
#import <ncurses.h>

@interface SFDownloaderProgressStdout () {
    @private
    BOOL last_line_progress;
    dispatch_queue_t stdout_queue;
}
@end

@implementation SFDownloaderProgressStdout

- (id)init {self = [super init]; last_line_progress = NO; stdout_queue = dispatch_queue_create("org.resinbros.wsinstall.stdoutqueue", 0); return self;}

/* Downloader began successfully */
- (void)downloadBegan:(NSString*)entryTitle {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Download of '%s' began\n", [entryTitle UTF8String]);
        last_line_progress = NO;
    //});
}

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(NSString*)entryTitle reason:(NSString*)reason {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Download of '%s' failed due to: %s\n", [entryTitle UTF8String], [reason UTF8String]);
        last_line_progress = NO;
    //});
}

/* Downloader progress update */
- (void)download:(NSString*)entryTitle progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes {
    //dispatch_async(stdout_queue, ^{
        curs_set(0); // Hide cursor
        if (last_line_progress)
            printf("\r"); // Clear last line
        if ([outOfBytes floatValue])
            printf("Progress: [%d%c]", (int)([currentBytes floatValue] / [outOfBytes floatValue] * 100), '%');
        else
            printf("Progress: [%uK]", [currentBytes unsignedIntValue] / 1024);
        last_line_progress = YES;
    //});
}

/* Download completed */
- (void)downloadCompleted:(NSString*)entryTitle {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Download of '%s' completed successfully\n", [entryTitle UTF8String]);
        last_line_progress = NO;
    //});
}

/* Unarchive began */
- (void)downloadBeganUnarchive:(NSString*)entryTitle {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Unarchive of '%s' began\n", [entryTitle UTF8String]);
        last_line_progress = NO;
    //});
}

/* Unarchive failed */
- (void)downloadFailedToUnarchive:(NSString*)entryTitle failCode:(int)failCode {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Unarchive of '%s' failed with error %d\n", [entryTitle UTF8String], failCode);
        last_line_progress = NO;
    //});
}

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(NSString*)entryTitle {
    //dispatch_async(stdout_queue, ^{
        curs_set(1);
        //system("tput cnorm"); // Show cursor
        if (last_line_progress)
            printf("\n"); // New line from progress
        printf("Unarchive of '%s' completed successfully\n", [entryTitle UTF8String]);
        last_line_progress = NO;
    //});
}

@end
