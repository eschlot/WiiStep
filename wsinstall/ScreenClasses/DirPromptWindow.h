//
//  DirPromptWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "MainScreen.h"
#import "ScreenInput.h"
#import "ScreenDrawable.h"
#import "EventCapturer.h"
@class DirPromptWindow;

@protocol InputWindowDelegate <NSObject>
- (void)inputWindow:(DirPromptWindow*)window valueChangedTo:(NSString*)value;
- (void)inputWindowOK:(id)window;
- (void)inputWindowCancel:(id)window;
@end

#pragma mark -

@interface DirPromptWindow : NSObject <ScreenInput, ScreenDrawable>

/* Insert into main screen */
+ (id)dirPromptInMainScreen:(MainScreen*)ms title:(NSString*)title titleAttr:(int)titleAttr prompt:(NSString*)prompt promptAttr:(int)promptAttr defaultValue:(NSString*)defaultValue editEnabled:(BOOL)edit delegate:(id <InputWindowDelegate>)delegate;

/* Current value */
@property (nonatomic, readonly) NSString* value;

@end
