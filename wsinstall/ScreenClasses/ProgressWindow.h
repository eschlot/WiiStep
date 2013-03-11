//
//  ProgressWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import "SFDownloader.h"
#import "ScreenDrawable.h"
@class MainScreen;

@interface ProgressWindowBar : NSObject
@end

@interface ProgressWindow : NSObject <ScreenDrawable, SFDownloaderProgressDelegate>

+ (id)progressWindowInMainScreen:(MainScreen*)ms;

- (void)addInstallBar;
- (void)installBarComplete;

@end
