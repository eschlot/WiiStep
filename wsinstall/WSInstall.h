//
//  WSInstall.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "EventCapturer.h"

@interface WSInstall : NSObject <EventCapturer>

+ (id)startWSInstall;

@end
