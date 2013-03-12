//
//  WSInstall.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "EventCapturer.h"
#import "DirPromptWindow.h"

@interface WSInstall : NSObject <EventCapturer, InputWindowDelegate, SFDownloaderProgressDelegate>

+ (WSInstall*)startWSInstall:(NSString*)dir optionalRVLSDK:(NSString*)sdk;

/* Termination code when finished */
@property (nonatomic, readonly) int termCode;

@end
