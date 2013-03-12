//
//  main.m
//  wsinstall
//
//  Created by Jack Andersen on 3/2/13.
//
//

#import <Foundation/Foundation.h>
#import <curl/curl.h>
#import <ncurses.h>
#import "SFDownloader.h"
#import "SFDownloaderProgressStdout.h"
#import "MainScreen.h"
#import "WSInstall.h"

static void interrupt_handler(int sig) {
    endwin();
    exit(0);
}

int main(int argc, const char * argv[])
{
    
    // Sudden-terminate on interrupt (but kindly return to terminal mode)
    signal(SIGINT, interrupt_handler);
    
    // Term code
    int termCode = -1;
    
    @autoreleasepool {
        
        // We're going to be using libcurl (get it ready)
        curl_global_init(CURL_GLOBAL_ALL);

        // Start install
        NSString* dir = nil;
        if (argc > 1)
            dir = @(argv[1]);
        NSString* rvlLoc = nil;
        if (argc > 2)
            rvlLoc = @(argv[2]);
        
        NSString* fail_stub_path = [dir stringByAppendingPathComponent:@"wsinstall-fail"];
        [[NSData data] writeToFile:fail_stub_path options:NSDataWritingAtomic error:nil];
        termCode = [WSInstall startWSInstall:dir optionalRVLSDK:rvlLoc].termCode;
        if (!termCode)
            [[NSFileManager defaultManager] removeItemAtPath:fail_stub_path error:nil];

        
        // Ensure terminal returns to term mode
        endwin();
        
        // Done with libcurl
        curl_global_cleanup();
        
    }
    
    
    return termCode;
}

