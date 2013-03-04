//
//  WSInstall.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "WSInstall.h"
#import "MainScreen.h"
#import "InitialCheckWindow.h"

@interface WSInstall () {
    @private
    MainScreen* mainScreen;
}
@end

@implementation WSInstall

- (id)init {return nil;}


#pragma mark Phase One: Check currently installed dependencies

- (void)phaseOne {
    InitialCheckWindow* initialWindow = [InitialCheckWindow initialCheckWindowInMainScreen:mainScreen withMissingItems:nil];
    [mainScreen setInputWindow:initialWindow];
    [mainScreen redraw];
}


+ (id)startWSInstall {
    WSInstall* install = [WSInstall new];
    /*
     // Download devkitPPC index
     SFDownloaderProgressStdout* progress = [SFDownloaderProgressStdout new];
     SFDownloader* sfd = [SFDownloader sfDownloaderWithProjectID:@"114505" subPath:@"devkitPPC" progressDelegate:progress];
     
     // Find first (latest OSX build)
     NSString* latest_build = nil;
     for (NSString* name in sfd.files) {
     if ([[name lowercaseString] rangeOfString:@"osx"].location != NSNotFound) {
     latest_build = name;
     break;
     }
     }
     
     // Download and unarchive to /tmp
     [sfd downloadFileEntry:latest_build toDirectory:[NSURL URLWithString:@"/tmp"] unarchive:YES progressDelegate:progress];
     */
        
    // Init ncurses screen and global params
    install->mainScreen = [MainScreen new];
    [install->mainScreen activate];
    
    return install;
}

- (void)receiver:(id)receiver sentCapturableKeyPress:(char)key {
    
}

@end
