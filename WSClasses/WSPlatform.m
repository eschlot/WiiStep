//
//  WSPlatform.m
//  WiiStep
//
//  Created by Jack Andersen on 4/14/13.
//
//

#import <WiiStep/WSPlatform.h>
#import <WiiStep/wiilight.h>

@implementation WSPlatform

+ (void)initialize {
    WIILIGHT_Init();
}

/* Disc slot blue LED control */
+ (void)setDiscLEDEnabled:(BOOL)enabled {
    if (enabled)
        WIILIGHT_TurnOn();
    else
        WIILIGHT_TurnOff();
}

/* Levels are expressed as normalised floats [0.0-1.0] */
+ (float)discLEDLevel {
    return WIILIGHT_GetLevel()/255.0f;
}
+ (void)setDiscLEDLevel:(float)level {
    WIILIGHT_SetLevel(level*255);
}

@end
