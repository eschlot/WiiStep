//
//  DirPromptWindow.h
//  WiiStep
//
//  Created by Jack Andersen on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <curses.h>
#import "ScreenDrawable.h"

@interface DirPromptWindow : NSObject <ScreenDrawable>

+ (id)dirPromptInScreenWindow:(WINDOW*)screen prompt:(NSString*)prompt withDefaultDir:(NSString*)defaultDir;

@property (nonatomic) NSString* dir;

- (void)activateForm;

@end
