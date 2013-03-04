//
//  MultiLineMessageWindow.h
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

@interface MultiLineMessageWindow : NSObject <ScreenInput, ScreenDrawable>

/* Insert into main screen */
+ (id)messageWindowInMainScreen:(MainScreen*)ms windowTitle:(NSString*)title windowTitleAttr:(int)titleAttr message:(NSString*)msg messageAttr:(int)msgAttr anyKeyHandler:(id <EventCapturer>)anyKeyHandler;

@end
