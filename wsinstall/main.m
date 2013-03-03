//
//  main.m
//  wsinstall
//
//  Created by Jack Andersen on 3/2/13.
//
//

#import <Foundation/Foundation.h>
#import <curl/curl.h>
#import "SFDownloader.h"
#import "SFDownloaderProgressStdout.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // We're going to be using libcurl (get it ready)
        curl_global_init(CURL_GLOBAL_ALL);
        
        // Download devkitPPC index
        SFDownloaderProgressStdout* progress = [SFDownloaderProgressStdout new];
        SFDownloader* sfd = [SFDownloader sfDownloaderWithProjectID:@"114505" subPath:@"devkitPPC" progressDelegate:progress];
        
        // Test print
        for (NSString* name in sfd.files) {
            NSLog(@"%@", name);
            if ([name rangeOfString:@"osx"].location != NSNotFound)
                NSLog(@"Found OSX!!");
        }
        
        // Done with libcurl
        curl_global_cleanup();
        
    }
    return 0;
}

