//
//  NeededDependenciesReportWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "MainScreen.h"
#import "ScreenInput.h"
#import "ScreenDrawable.h"
#import "DirPromptWindow.h"

@interface NeededDependenciesReportWindow : NSObject <ScreenInput, ScreenDrawable>

/* Insert into main screen */
+ (id)ndrWindowInMainScreen:(MainScreen*)ms windowTitle:(NSString*)title windowTitleAttr:(int)titleAttr message:(NSString*)msg messageAttr:(int)msgAttr dependencies:(NSArray*)deps itemAttr:(int)itemAttr inputDelegate:(id <InputWindowDelegate>)inputDelegate;

@end
