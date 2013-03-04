//
//  InitialCheckWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "MainScreen.h"
#import "ScreenDrawable.h"
#import "ScreenInput.h"

@interface InitialCheckWindow : NSObject <ScreenDrawable, ScreenInput>

/* Insert into main screen */
+ (id)initialCheckWindowInMainScreen:(MainScreen*)ms withMissingItems:(NSArray*)items;

@end
