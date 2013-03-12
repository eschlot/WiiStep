//
//  SFDownloader.h
//  WiiStep
//
//  Created by Jack Andersen on 3/2/13.
//
//

/* Lightweight sourceforge.net RSS API parser for downloading latest
 * and greatest project files */

#import <Foundation/Foundation.h>
@class ProgressWindowBar;
@class SFHash;

/* Protocol for getting download and bunzip progress */
@protocol SFDownloaderProgressDelegate <NSObject>
@optional

/* Downloader began successfully */
- (void)downloadBegan:(SFHash*)entryTitle;

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(SFHash*)entry reason:(NSString*)reason;

/* Downloader progress update */
- (void)download:(SFHash*)entry progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes;

/* Download completed */
- (void)downloadCompleted:(SFHash*)entry;

/* Decompress began */
- (void)downloadBeganDecompress:(SFHash*)entry;

/* Decompress failed */
- (void)downloadFailedToDecompress:(SFHash*)entry failCode:(int)failCode;

/* Decompress completed */
- (void)downloadCompletedDecompress:(SFHash*)entry;

/* Unarchive began */
- (void)downloadBeganUnarchive:(SFHash*)entry;

/* Unarchive failed */
- (void)downloadFailedToUnarchive:(SFHash*)entry failCode:(int)failCode;

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(SFHash*)entry;

@end

#pragma mark -

@interface SFHash : NSObject <NSCopying> {
    @public
    NSString* algo;
    NSString* hash;
    NSString* name;
    ProgressWindowBar* dl_bar;
    ProgressWindowBar* decomp_bar;
    ProgressWindowBar* unarc_bar;
}
+ (SFHash*)hashFromPath:(NSString*)path;
- (void)hashToPath:(NSString*)path;
@end

#pragma mark -

@interface SFDownloader : NSObject

/* Use Sourceforge's RSS API to obtain a 20-item (or less) file-listing from a project
 * Items will be sorted by decending recency */
+ (id)sfDownloaderWithProjectID:(NSString*)projId subPath:(NSString*)subPath progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate;

/* Array containing file download titles indexed by decending recency */
@property (nonatomic, readonly) NSArray* files;

/* Download file by entry name and place at specified local directory URL 
 * Local File URL is returned when complete. The option to perform a bunzip is also
 * available. The progress delegate is used to get instant notifications of 
 * download progress */
- (NSString*)downloadFileEntry:(SFHash*)entry toDirectory:(NSString*)directory unarchive:(BOOL)unarchive progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate;

@end
