//
//  SFDownloaderProgressStdout.m
//  WiiStep
//
//  Created by Jack Andersen on 3/2/13.
//
//

#import "SFDownloaderProgressStdout.h"

@interface SFDownloaderProgressStdout () {
    @private
    BOOL last_line_progress;
}
@end

@implementation SFDownloaderProgressStdout

- (id)init {self = [super init]; last_line_progress = NO; return self;}

/* Downloader began successfully */
- (void)downloadBegan:(NSString*)entryTitle {
    if (last_line_progress)
        printf("\n"); // New line from progress
    printf("Download of '%s' began\n", [entryTitle UTF8String]);
    last_line_progress = NO;
}

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(NSString*)entryTitle reason:(NSString*)reason {
    if (last_line_progress)
        printf("\n"); // New line from progress
    printf("Download of '%s' failed due to: %s\n", [entryTitle UTF8String], [reason UTF8String]);
    last_line_progress = NO;
}

/* Downloader progress update */
- (void)download:(NSString*)entryTitle progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes {
    if (last_line_progress)
        printf("\r                                   \r"); // Clear last line
    if ([outOfBytes floatValue])
        printf("Progress: [%f%c]", [currentBytes floatValue] / [outOfBytes floatValue] * 100, '%');
    else
        printf("Progress: [%uK]", [currentBytes unsignedIntValue] / 1024);
    last_line_progress = YES;
}

/* Download completed */
- (void)downloadCompleted:(NSString*)entryTitle {
    if (last_line_progress)
        printf("\n"); // New line from progress
    printf("Download of '%s' completed successfully\n", [entryTitle UTF8String]);
    last_line_progress = NO;
}

/* Unarchive began */
- (void)downloadBeganUnarchive:(NSString*)entryTitle {
    if (last_line_progress)
        printf("\n"); // New line from progress
    printf("Unarchive of '%s' began\n", [entryTitle UTF8String]);
    last_line_progress = NO;
}

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(NSString*)entryTitle {
    if (last_line_progress)
        printf("\n"); // New line from progress
    printf("Unarchive of '%s' completed successfully\n", [entryTitle UTF8String]);
    last_line_progress = NO;
}

@end
