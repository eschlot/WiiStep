//
//  WSInstall.m
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import "WSInstall.h"
#import "MainScreen_Private.h"
#import "InitialCheckWindow.h"
#import "MultiLineMessageWindow.h"

@interface WSInstall () {
    @private
    MainScreen* mainScreen;
    NSInteger curPhase;
    NSString* dir;
}
@end

@implementation WSInstall

- (id)init {return nil;}
- (id)_init {return [super init];}


#pragma mark Phase Zero: Confirm install location with user

- (void)phaseZero {
    curPhase = 0;
    mainScreen.inputWindow = [DirPromptWindow dirPromptInMainScreen:mainScreen title:@"WiiStep Directory" titleAttr:COLOR_PAIR(COLOR_POPPING_TEXT) prompt:@"Please confirm WiiStep install directory:" promptAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) defaultValue:(dir)?dir:@"/opt/wiistep" delegate:self];
    [mainScreen redraw];
}


#pragma mark Phase One: Check currently installed dependencies

- (void)phaseOne {
    InitialCheckWindow* initialWindow = [InitialCheckWindow initialCheckWindowInMainScreen:mainScreen withMissingItems:nil];
    [mainScreen setInputWindow:initialWindow];
    [mainScreen redraw];
}


#pragma mark Phase Two: Check to see if dependencies can be externally obtained

- (void)phaseTwo {
    
}


#pragma mark Phase Three: Deliver dependency report to user and receive confirmation

- (void)phaseThree {
    
}


#pragma mark Phase Four: Download any external dependencies and install everything

- (void)phaseFour {
    
}


#pragma mark Installer Entry Point

+ (id)startWSInstall:(NSString *)dir {
    WSInstall* install = [[WSInstall alloc] _init];
    install->dir = dir;
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
    //[install->mainScreen setInputWindow:[MultiLineMessageWindow messageWindowInMainScreen:install->mainScreen windowTitle:@"Test Title" windowTitleAttr:COLOR_PAIR(COLOR_POPPING_TEXT) message:@"Loremlonglonglonglonglong ipsum dolor sit amet, consectetur adipiscing elit. Aliquam et nisi eros, adipiscing pellentesque urna. Curabitur ullamcorper, augue hendrerit placerat interdum, mi enim lacinia lorem, at convallis dolor lectus in turpis. Nunc bibendum faucibus urna nec suscipit. Vivamus lacinia viverra facilisis. Mauris adipiscing bibendum est ut ullamcorper." messageAttr:COLOR_PAIR(COLOR_NORMAL_TEXT) anyKeyHandler:install]];
    [install phaseZero];
    [install->mainScreen activate];
    
    return install;
}


#pragma mark "Candy Cane" Responder Capturer

- (void)receiver:(id)receiver sentCapturableKeyPress:(int)key {
    
}

- (void)inputWindow:(DirPromptWindow *)window valueChangedTo:(NSString *)value {
    
}

- (void)inputWindowOK:(DirPromptWindow *)window {
    
}

- (void)inputWindowCancel:(DirPromptWindow *)window {
    if (curPhase == 0) // Directory screen
        [mainScreen deactivate];
}

@end
