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
    SFHash* index_hash = [SFHash new];
    index_hash->algo = nil;
    index_hash->hash = nil;
    index_hash->name = [NSString stringWithFormat:@"SF Project File Index: %@/%@", projId, subPath];
    __block BOOL header_received = NO;
    curl_set_write_header_block(curl_h, ^size_t(char *ptr, size_t size, size_t nmemb) {
        if (!header_received) {
            if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadBegan:)])
                [progressDelegate downloadBegan:index_hash];
        }
        header_received = YES;
        return size*nmemb;
    });
    curl_set_progress_block(curl_h, ^int(double dltotal, double dlnow, double ultotal, double ulnow) {
        if (report_progress && progressDelegate && [progressDelegate respondsToSelector:@selector(download:progressBytes:outOfBytes:)])
            [progressDelegate download:index_hash progressBytes:@(dlnow) outOfBytes:@(dltotal)];
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
            [progressDelegate downloadFailedToBegin:index_hash reason:@(err_buf)];
        return nil;
    }
    if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadCompleted:)])
        [progressDelegate downloadCompleted:index_hash];
    
    // Good at this point; parse index_buf
    NSData* index_doc_data = [NSData dataWithBytesNoCopy:index_buf length:index_buf_cur freeWhenDone:YES];
    NSXMLDocument* index_doc = [[NSXMLDocument alloc] initWithData:index_doc_data options:0 error:nil];
    NSXMLElement* index_rss = [index_doc rootElement];
    NSXMLElement* index_channel = [index_rss elementsForName:@"channel"][0];
    
    // Enumerate Channel
    [[index_channel elementsForName:@"item"] enumerateObjectsUsingBlock:^(NSXMLElement* item, NSUInteger idx, BOOL *stop) {
        NSXMLElement* media = [item elementsForName:@"media:content"][0];
        NSXMLElement* media_hash = [media elementsForName:@"media:hash"][0];
        SFHash* hash = [SFHash new];
        hash->algo = [[media_hash attributeForName:@"algo"] stringValue];
        hash->hash = [media_hash stringValue];
        hash->name = [[item elementsForName:@"title"][0] stringValue];
        dl->_files[idx] = hash;
        NSURL* link = [NSURL URLWithString:[[item elementsForName:@"link"][0] stringValue]];
        dl->_fileURLs[hash] = link;
    }];
    
    return dl;
}

/* Array containing file download titles indexed by decending recency */
@synthesize files = _files;

/* Download file by entry name and place at specified local directory URL
 * Local File URL is returned when complete. The option to perform a bunzip is also
 * available. The progress delegate is used to get instant notifications of
 * download progress */
- (NSString*)downloadFileEntry:(SFHash*)entry toDirectory:(NSString*)directory unarchive:(BOOL)unarchive progressDelegate:(id <SFDownloaderProgressDelegate>)progressDelegate {
    NSURL* requested_url = _fileURLs[entry];
    if (!requested_url)
        return nil;
    
    // Target local URL (and a FILE handle)
    NSString* target_url = [directory stringByAppendingPathComponent:[entry->name lastPathComponent]];
    FILE* target_file = fopen([target_url UTF8String], "w");
    if (!target_file)
        return nil;
    
    // Configure cURL for direct-to-disk download
    CURL* curl_h = curl_easy_init();
    __block BOOL report_progress = NO;
    curl_set_write_body_block(curl_h, ^size_t(char *ptr, size_t size, size_t nmemb) {
        report_progress = YES;
        return fwrite(ptr, size, nmemb, target_file);
    });
    __block BOOL header_received = NO;
    curl_set_write_header_block(curl_h, ^size_t(char *ptr, size_t size, size_t nmemb) {
        if (!header_received) {
            if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadBegan:)])
                [progressDelegate downloadBegan:entry];
        }
        header_received = YES;
        return size*nmemb;
    });
    curl_set_progress_block(curl_h, ^int(double dltotal, double dlnow, double ultotal, double ulnow) {
        if (report_progress && progressDelegate && [progressDelegate respondsToSelector:@selector(download:progressBytes:outOfBytes:)])
            [progressDelegate download:entry progressBytes:@(dlnow) outOfBytes:@(dltotal)];
        return 0;
    });
    char err_buf[CURL_ERROR_SIZE];
    curl_easy_setopt(curl_h, CURLOPT_ERRORBUFFER, err_buf);
    curl_easy_setopt(curl_h, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curl_h, CURLOPT_URL, [[requested_url absoluteString] UTF8String]);
    
    // Begin download
    CURLcode res_code = curl_easy_perform(curl_h);
    curl_easy_cleanup(curl_h);
    fclose(target_file);
    if (res_code) {
        if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadFailedToBegin:reason:)])
            [progressDelegate downloadFailedToBegin:entry reason:@(err_buf)];
        return nil;
    }
    if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadCompleted:)])
        [progressDelegate downloadCompleted:entry];
    
    // Good at this point; unarchive if extension is for supported archive format
    if (!unarchive)
        return target_url;
    
    NSString* ext_string = [[[target_url lastPathComponent] pathExtension] lowercaseString];
    if ([ext_string isEqualToString:@"bz2"]) {
        NSTask* bunzip_task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/bunzip2" arguments:@[target_url]];
        if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadBeganDecompress:)])
            [progressDelegate downloadBeganDecompress:entry];
        [bunzip_task waitUntilExit];
        int term_code = [bunzip_task terminationStatus];
        if (term_code && progressDelegate && [progressDelegate respondsToSelector:@selector(downloadFailedToDecompress:failCode:)])
            [progressDelegate downloadFailedToDecompress:entry failCode:term_code];
        else if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadCompletedDecompress:)])
            [progressDelegate downloadCompletedDecompress:entry];
        
        target_url = [target_url stringByDeletingPathExtension];
    }
    
    // Check to see if we have a tar
    ext_string = [[[target_url lastPathComponent] pathExtension] lowercaseString];
    if ([ext_string isEqualToString:@"tar"]) {
        NSTask* tar_task = [NSTask new];
        [tar_task setCurrentDirectoryPath:[target_url stringByDeletingLastPathComponent]];
        [tar_task setLaunchPath:@"/usr/bin/tar"];
        [tar_task setArguments:@[@"-xf", target_url]];
        [tar_task launch];
        if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadBeganUnarchive:)])
            [progressDelegate downloadBeganUnarchive:entry];
        [tar_task waitUntilExit];
        int term_code = [tar_task terminationStatus];
        if (term_code && progressDelegate && [progressDelegate respondsToSelector:@selector(downloadFailedToUnarchive:failCode:)])
            [progressDelegate downloadFailedToUnarchive:entry failCode:term_code];
        else if (progressDelegate && [progressDelegate respondsToSelector:@selector(downloadCompletedUnarchive:)]) {
            [progressDelegate downloadCompletedUnarchive:entry];
        }
        [[NSFileManager defaultManager] removeItemAtPath:target_url error:nil];

    }
    
    
    return target_url;

}

@end

@implementation SFHash
- (NSUInteger)hash {return *(NSUInteger*)[hash UTF8String];}
- (BOOL)isEqual:(SFHash*)object {
    if (!object || ![object isKindOfClass:[SFHash class]])
        return NO;
    if ([object->algo isEqualToString:algo] && [object->hash isEqualToString:hash])
        return YES;
    return NO;
}
- (id)copyWithZone:(NSZone *)zone {
    SFHash* hashCopy = [SFHash allocWithZone:zone];
    hashCopy->algo = algo;
    hashCopy->hash = hash;
    hashCopy->name = name;
    return hashCopy;
}
- (NSString*)description {return name;}

+ (SFHash*)hashFromPath:(NSString*)path {
    NSDictionary* hashInfo = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!hashInfo)
        return nil;
    SFHash* hash = [SFHash new];
    hash->algo = hashInfo[@"algo"];
    hash->hash = hashInfo[@"hash"];
    hash->name = hashInfo[@"name"];
    return hash;
}
- (void)hashToPath:(NSString*)path {
    NSDictionary* hashInfo = @{@"algo":algo,@"hash":hash,@"name":name};
    [hashInfo writeToFile:path atomically:YES];
}
@end
