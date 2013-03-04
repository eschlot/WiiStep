//
//  EventCapturer.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>

@protocol EventCapturer <NSObject>
- (void)receiver:(id)receiver sentCapturableKeyPress:(char)key;
@end
