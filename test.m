//
//  test.c
//  WiiStep
//
//  Created by Jack Andersen on 2/27/13.
//
//

#include <stdio.h>
#import "WiiStepSDK.h"

int main(int argc, const char** argv) {
    
    // First, the basics
    printf("Hello world!!\n");
    
    // And now for something completely different: (a block on stack)
    void(^testBlock)() = ^{
        printf("Hello from a block!!\n");
    };
    testBlock();
    
    // And now for some Objective-C fancy ARC footwork
    @autoreleasepool {
        // TODO: Get GnuStep integrated and perform NSString test
    }
    
    return 0;
}