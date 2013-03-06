//
//  ScreenInput.h
//  WiiStep
//
//  Created by Jack Andersen on 3/4/13.
//
//

#import <Foundation/Foundation.h>

@protocol ScreenInput <NSObject>
- (void)receiveInputCharacter:(int)aChar;
@end
