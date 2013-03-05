//
//  OneLineInputWindow.h
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
@class OneLineInputWindow;

@protocol InputWindowDelegate <NSObject>
- (void)inputWindow:(OneLineInputWindow*)window valueChangedTo:(NSString*)value;
- (void)inputWindowOK:(OneLineInputWindow*)window;
- (void)inputWindowCancel:(OneLineInputWindow*)window;
@end

#pragma mark -

@interface OneLineInputWindow : NSObject <ScreenInput, ScreenDrawable>

/* Insert into main screen */
+ (id)oneLineInputInMainScreen:(MainScreen*)ms title:(NSString*)title titleAttr:(int)titleAttr prompt:(NSString*)prompt promptAttr:(int)promptAttr defaultValue:(NSString*)defaultValue delegate:(id <InputWindowDelegate>)delegate;

@end
