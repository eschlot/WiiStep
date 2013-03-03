//
//  SFDownloader.m
//  WiiStep
//
//  Created by Jack Andersen on 3/2/13.
//
//

#import "SFDownloader.h"
#import <curl/curl.h>
#import <curl/easy.h>

/* The obvious */
static const char* SF_DOMAIN = "sourceforge.net";

@interface SFDownloader () {
    @private
    NSMutableArray* _files;
    NSMutableDictionary* _fileURLs;
}
@end


#pragma mark cURL Write Header Function

/* cURL write header block type */
typedef size_t(^CurlWriteHeaderBlock)(char *ptr, size_t size, size_t nmemb);

/* cURL write header function block adapter */
static size_t curlWriteHeader(char *ptr, size_t size, size_t nmemb, void *userdata) {
    return ((__bridge CurlWriteHeaderBlock)userdata)(ptr, size, nmemb);
}

/* cURL set write header block */
static inline CURLcode curl_set_write_header_block(CURL* curl, CurlWriteHeaderBlock block) {
    CURLcode ret = curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, curlWriteHeader);
    curl_easy_setopt(curl, CURLOPT_WRITEHEADER, (__bridge void*)block);
    return ret;
}


#pragma mark cURL Write Body Function

/* cURL write body block type */
typedef size_t(^CurlWriteBodyBlock)(char *ptr, size_t size, size_t nmemb);

/* cURL write body function block adapter */
static size_t curlWriteBody(char *ptr, size_t size, size_t nmemb, void *userdata) {
    return ((__bridge CurlWriteBodyBlock)userdata)(ptr, size, nmemb);
}

/* cURL set write body block */
static inline CURLcode curl_set_write_body_block(CURL* curl, CurlWriteBodyBlock block) {
    CURLcode ret = curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curlWriteBody);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (__bridge void*)block);
    return ret;
}


#pragma mark cURL Progress Function

/* cURL progress block type */
typedef int(^CurlProgressBlock)(double dltotal, double dlnow, double ultotal, double ulnow);

/* cURL progress function block adapter */
static int curlProgress(void* clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
    return ((__bridge CurlProgressBlock)clientp)(dltotal, dlnow, ultotal, ulnow);
}

/* cURL set progress block */
static inline CURLcode curl_set_progress_block(CURL* curl, CurlProgressBlock block) {
    CURLcode ret = curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, curlProgress);
    curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (__bridge void*)block);
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, FALSE);
    return ret;
}


@implementation SFDownloader

/* Use Sourceforge's RSS API to obtain a 20-item (or less) file-listing from a project
 * Items will be sorted by decending recency */
+ (id)sfDownloaderWithProjectID:(NSString*)projId subPath:(NSString*)subPath progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate {
    SFDownloader* dl = [SFDownloader new];
    dl->_files = [NSMutableArray arrayWithCapacity:20];
    dl->_fileURLs = [NSMutableDictionary dictionaryWithCapacity:20];
    
    // Assemble API request URL
    char req_url[512];
    snprintf(req_url, 512, "http://%s/api/file/index/project-id/%s/path/%s/mtime/desc/limit/20/rss", SF_DOMAIN, [projId UTF8String], [subPath UTF8String]);
    
    // Configure download of file index (512K capacity)
    CURL* curl_h = curl_easy_init();
    __block size_t available_size = 512*1024;
    void* index_buf = malloc(available_size);
    __block size_t index_buf_cur = 0;
    __block BOOL report_progress = NO;
    curl_set_write_body_block(curl_h, ^size_t(char *ptr, size_t size, size_t nmemb) {
        report_progress = YES;
        size_t this_size = size*nmemb;
        if (this_size > available_size)
            this_size = available_size;
        memcpy(index_buf+index_buf_cur, ptr, this_size);
        index_buf_cur += this_size;
        available_size -= this_size;
        return this_size;
    });
    NSString* progress_name_string = [NSString stringWithFormat:@"SF Project File Index: %@/%@", projId, subPath];
    __block BOOL header_received = NO;
    curl_set_write_header_block(curl_h, ^size_t(char *ptr, size_t size, size_t nmemb) {
        if (!header_received) {
            if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadBegan:)])
                [progressDelegate downloadBegan:progress_name_string];
        }
        header_received = YES;
        return size*nmemb;
    });
    curl_set_progress_block(curl_h, ^int(double dltotal, double dlnow, double ultotal, double ulnow) {
        if (report_progress && progressDelegate && [progressDelegate respondsToSelector:@selector(download:progressBytes:outOfBytes:)])
            [progressDelegate download:progress_name_string progressBytes:@(dlnow) outOfBytes:@(dltotal)];
        return 0;
    });
    char err_buf[CURL_ERROR_SIZE];
    curl_easy_setopt(curl_h, CURLOPT_ERRORBUFFER, err_buf);
    curl_easy_setopt(curl_h, CURLOPT_URL, req_url);
    
    // Begin download
    CURLcode res_code = curl_easy_perform(curl_h);
    curl_easy_cleanup(curl_h);
    if (res_code) {
        free(index_buf);
        if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadFailedToBegin:reason:)])
            [progressDelegate downloadFailedToBegin:progress_name_string reason:@(err_buf)];
        return nil;
    }
    if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadCompleted:)])
        [progressDelegate downloadCompleted:progress_name_string];
    
    // Good at this point; parse index_buf
    NSData* index_doc_data = [NSData dataWithBytesNoCopy:index_buf length:index_buf_cur freeWhenDone:YES];
    NSXMLDocument* index_doc = [[NSXMLDocument alloc] initWithData:index_doc_data options:0 error:nil];
    NSXMLElement* index_rss = [index_doc rootElement];
    NSXMLElement* index_channel = [index_rss elementsForName:@"channel"][0];
    
    // Enumerate Channel
    [[index_channel elementsForName:@"item"] enumerateObjectsUsingBlock:^(NSXMLElement* item, NSUInteger idx, BOOL *stop) {
        NSString* title = [[item elementsForName:@"title"][0] stringValue];
        NSURL* link = [NSURL URLWithString:[[item elementsForName:@"link"][0] stringValue]];
        dl->_files[idx] = title;
        dl->_fileURLs[title] = link;
    }];
    
    return dl;
}

/* Array containing file download titles indexed by decending recency */
@synthesize files = _files;

/* Download file by entry name and place at specified local directory URL
 * Local File URL is returned when complete. The option to perform a bunzip is also
 * available. The progress delegate is used to get instant notifications of
 * download progress */
- (NSURL*)downloadFileEntry:(NSString*)entryName toDirectory:(NSURL*)directory unarchive:(BOOL)unarchive progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate {
    
}

@end
