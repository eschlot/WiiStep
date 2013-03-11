//
//  WSInstall.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "WSInstall.h"
#import "MainScreen_Private.h"
#import "MultiLineMessageWindow.h"
#import "SFDownloader.h"
#import "NeededDependenciesReportWindow.h"

@interface WSInstall () {
    @private
    MainScreen* mainScreen;
    NSInteger curPhase;
    NSString* dir; // Install dir
    
    // Timestamp versioning for installed binary dependencies
    // (source dependencies all handled by git and cmake)
    // `nil` if not found or not needed
    SFHash* dkPPCHash;
    SFHash* libogcHash;
    
    // Downloaders
    SFDownloader* dkPPCDownloader;
    SFDownloader* libogcDownloader;
    
    // RVL_SDK support (`nil` if not using)
    NSString* rvlSDKLocation;
    
    
    // Phase neg1 message
    NSString* neg1message;
}
@end

@implementation WSInstall

- (id)init {return nil;}
- (id)_init {return [super init];}


#pragma mark Phase Zero: Confirm install location with user

- (void)phaseZero {
    curPhase = 0;
    
    // Confirm directory
    mainScreen.inputWindow = [DirPromptWindow dirPromptInMainScreen:mainScreen title:@"WiiStep Directory" titleAttr:COLOR_PAIR(COLOR_POPPING_TEXT) prompt:@"Please confirm WiiStep install directory:" promptAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) defaultValue:(dir)?dir:@"/opt/wiistep" editEnabled:NO delegate:self];
    [mainScreen redraw];
}


#pragma mark Phase One: Check currently installed dependencies

- (void)phaseOne {
    curPhase = 1;

    // Put up spinners
    mainScreen.inputWindow = nil;
    mainScreen.progIndicator = YES;
    [mainScreen redraw];
        
    // DKPPC hash?
    NSString* dkppcPath = [dir stringByAppendingPathComponent:@"devkitPPC"];
    dkPPCHash = [SFHash hashFromPath:[dkppcPath stringByAppendingString:@"-info.plist"]];
    
    // libogc hash?
    NSString* libogcPath = [dir stringByAppendingPathComponent:@"libogc"];
    libogcHash = [SFHash hashFromPath:[libogcPath stringByAppendingString:@"-info.plist"]];

    
    [self phaseTwo];
}


#pragma mark Phase Two: Check to see if (newer) dependencies can be externally obtained

- (void)phaseTwo {
    curPhase = 2;
    
    // Put up spinners
    mainScreen.inputWindow = nil;
    mainScreen.progIndicator = YES;
    [mainScreen redraw];
    
    // Download dkppc index
    dkPPCDownloader = [SFDownloader sfDownloaderWithProjectID:@"114505" subPath:@"devkitPPC" progressDelegate:self];
    if (!dkPPCDownloader) {
        neg1message = @"There are no internets to download devkitPPC index from SourceForge.net";
        [self phaseNegOne];
        return;
    }
    // Find first (latest OSX build)
    SFHash* dl_dkppc_hash = nil;
    for (SFHash* entry in dkPPCDownloader.files) {
        if ([[entry->name lowercaseString] rangeOfString:@"osx"].location != NSNotFound) {
            dl_dkppc_hash = entry;
            break;
        }
    }
    if ([dl_dkppc_hash isEqualTo:dkPPCHash])
        dkPPCDownloader = nil;
    else
        dkPPCHash = dl_dkppc_hash;
    
    // Download libogc index
    libogcDownloader = [SFDownloader sfDownloaderWithProjectID:@"114505" subPath:@"libogc" progressDelegate:self];
    if (!libogcDownloader) {
        neg1message = @"There are no internets to download libogc index from SourceForge.net";
        [self phaseNegOne];
        return;
    }
    SFHash* dl_libogc_hash = libogcDownloader.files[0];
    if ([dl_libogc_hash isEqualTo:libogcHash])
        libogcDownloader = nil;
    else
        libogcHash = dl_libogc_hash;
    
    // Skip confirmation if no downloads
    if (dkPPCDownloader || libogcDownloader)
        [self phaseThree];
    else
        [self phaseFour];
}


#pragma mark Phase Three: Deliver dependency report to user and receive confirmation

- (void)phaseThree {
    curPhase = 3;
    mainScreen.progIndicator = NO;
    
    NSMutableArray* dep_arr = [NSMutableArray array];
    if (dkPPCDownloader)
        [dep_arr addObject:@"devkitPPC (Wii-toolchain and CXX-library) [SourceForge.net]"];
    if (libogcDownloader)
        [dep_arr addObject:@"libogc (open-source Wii OS and HW drivers) [SourceForge.net]"];
    
    mainScreen.inputWindow = [NeededDependenciesReportWindow ndrWindowInMainScreen:mainScreen windowTitle:@"Needed Dependencies" windowTitleAttr:COLOR_PAIR(COLOR_POPPING_TEXT) message:@"The following (binary) items will be downloaded from their primary hosting sources:" messageAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) dependencies:dep_arr itemAttr:COLOR_PAIR(COLOR_POPPING_TEXT) inputDelegate:self];
    [mainScreen redraw];
}


#pragma mark Phase Four: Download any external dependencies and install everything

- (void)phaseFour {
    curPhase = 4;
    mainScreen.inputWindow = nil;
    mainScreen.progWin = [ProgressWindow progressWindowInMainScreen:mainScreen];
    [mainScreen redraw];
    mainScreen.progIndicator = YES;
    
    // Group to simultaneously download files
    dispatch_group_t downloader_group = dispatch_group_create();
    dispatch_queue_t downloader_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    if (dkPPCDownloader) {
        dispatch_group_async(downloader_group, downloader_queue, ^{
            NSString* plPath = [dir stringByAppendingPathComponent:@"devkitPPC-info.plist"];
            [[NSFileManager defaultManager] removeItemAtPath:plPath error:nil];
            [dkPPCDownloader downloadFileEntry:dkPPCHash toDirectory:[NSURL URLWithString:dir] unarchive:YES progressDelegate:self];
            [dkPPCHash hashToPath:plPath];
        });
    }
    
    if (libogcDownloader) {
        dispatch_group_async(downloader_group, downloader_queue, ^{
            NSString* plPath = [dir stringByAppendingPathComponent:@"libogc-info.plist"];
            [[NSFileManager defaultManager] removeItemAtPath:plPath error:nil];
            [libogcDownloader downloadFileEntry:libogcHash toDirectory:[NSURL URLWithString:dir] unarchive:YES progressDelegate:self];
            [libogcHash hashToPath:plPath];
        });
    }
    
    // Wait
    dispatch_group_wait(downloader_group, DISPATCH_TIME_FOREVER);
    
    
    // Install everything
    [mainScreen.progWin addInstallBar];
    sleep(5);
    [mainScreen.progWin installBarComplete];
    
    mainScreen.progIndicator = NO;
    mainScreen.inputWindow = [MultiLineMessageWindow messageWindowInMainScreen:mainScreen windowTitle:@"Installation Complete" windowTitleAttr:COLOR_PAIR(COLOR_POPPING_TEXT) message:@"Installation of WiiStep dependency-binaries complete. Cmake will now continue." messageAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) anyKeyHandler:self];
    [mainScreen redraw];
    
    // Write wsinstall-ran stub for Cmake
    [[NSData data] writeToFile:[dir stringByAppendingPathComponent:@"wsinstall-ran"] options:NSDataWritingAtomic error:nil];
    
}


#pragma mark Phase Negative One: No Internets

- (void)phaseNegOne {
    curPhase = -1;
    
    mainScreen.progIndicator = NO;
    mainScreen.inputWindow = [MultiLineMessageWindow messageWindowInMainScreen:mainScreen windowTitle:@"OH NOES!!" windowTitleAttr:COLOR_PAIR(COLOR_ERROR_TEXT) message:(neg1message)?neg1message:@"There are no internets" messageAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) anyKeyHandler:self];
    [mainScreen redraw];
}


#pragma mark Installer Entry Point

+ (id)startWSInstall:(NSString *)dir optionalRVLSDK:(NSString*)sdk {
    WSInstall* install = [[WSInstall alloc] _init];
    install->dir = dir;
    install->rvlSDKLocation = sdk;
    install->neg1message = nil;
        
    // Init ncurses screen and global params
    install->mainScreen = [MainScreen new];
    [install phaseZero];
    [install->mainScreen activate];
    
    return install;
}


#pragma mark "Candy Cane" Responder Capturer

- (void)receiver:(id)receiver sentCapturableKeyPress:(int)key {
    if (curPhase == -1)
        [mainScreen deactivate];
    else if (curPhase == 4)
        [mainScreen deactivate];
}

- (void)inputWindow:(DirPromptWindow *)window valueChangedTo:(NSString *)value {
    
}

- (void)inputWindowOK:(DirPromptWindow *)window {
    if (curPhase == 0) // Directory screen
        [self phaseOne];
    else if (curPhase == 3) // Dep Report
        [self phaseFour];
}

- (void)inputWindowCancel:(DirPromptWindow *)window {
    if (curPhase == 0 || curPhase == 3) // Directory screen or dep report
        [mainScreen deactivate];
}


#pragma mark Downloader Delegate Implementations

/* Downloader began successfully */
- (void)downloadBegan:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadBegan:entry];
}

/* Downloader unable to start (due to HTTP error) */
- (void)downloadFailedToBegin:(SFHash*)entry reason:(NSString*)reason {
    if (curPhase == 4)
        [mainScreen.progWin downloadFailedToBegin:entry reason:reason];
}

/* Downloader progress update */
- (void)download:(SFHash*)entry progressBytes:(NSNumber*)currentBytes outOfBytes:(NSNumber*)outOfBytes {
    if (curPhase == 4)
        [mainScreen.progWin download:entry progressBytes:currentBytes outOfBytes:outOfBytes];
}

/* Download completed */
- (void)downloadCompleted:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadCompleted:entry];
}

/* Decompress began */
- (void)downloadBeganDecompress:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadBeganDecompress:entry];
}

/* Decompress failed */
- (void)downloadFailedToDecompress:(SFHash*)entry failCode:(int)failCode {
    if (curPhase == 4)
        [mainScreen.progWin downloadFailedToDecompress:entry failCode:failCode];
}

/* Decompress completed */
- (void)downloadCompletedDecompress:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadCompletedDecompress:entry];
}

/* Unarchive began */
- (void)downloadBeganUnarchive:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadBeganUnarchive:entry];
}

/* Unarchive failed */
- (void)downloadFailedToUnarchive:(SFHash*)entry failCode:(int)failCode {
    if (curPhase == 4)
        [mainScreen.progWin downloadFailedToUnarchive:entry failCode:failCode];
}

/* Unarchive completed */
- (void)downloadCompletedUnarchive:(SFHash*)entry {
    if (curPhase == 4)
        [mainScreen.progWin downloadCompletedUnarchive:entry];
}

@end
