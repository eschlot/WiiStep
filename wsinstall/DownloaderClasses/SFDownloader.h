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

/* Protocol for getting download and bunzip progress */
@protocol SFDownloaderProgressDelegate <NSObject>
@optional

/* Downloader began successfully */
- (void)downloadBegan:(NSString*)entryTitle;

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(NSString*)entryTitle reason:(NSString*)reason;

/* Downloader progress update */
- (void)download:(NSString*)entryTitle progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes;

/* Download completed */
- (void)downloadCompleted:(NSString*)entryTitle;

/* Unarchive began */
- (void)downloadBeganUnarchive:(NSString*)entryTitle;

/* Unarchive failed */
- (void)downloadFailedToUnarchive:(NSString*)entryTitle failCode:(int)failCode;

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(NSString*)entryTitle;

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
- (NSURL*)downloadFileEntry:(NSString*)entryName toDirectory:(NSURL*)directory unarchive:(BOOL)unarchive progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate;

@end
