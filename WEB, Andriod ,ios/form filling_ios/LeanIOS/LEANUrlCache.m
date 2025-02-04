//
//  LEANUrlCache.m
//  GoNativeIOS
//
//  Created by Weiyin He on 6/4/14.
//  Copyright (c) 2014 The Lean App. All rights reserved.
//

#import "LEANUrlCache.h"
#import <SSZipArchive.h>

@interface LEANUrlCache ()
@property id manifest;
@property NSMutableDictionary *urlsToManifest;
@property NSMutableDictionary *filesToData;
@end

@implementation LEANUrlCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"localCache" withExtension:@"zip"];
        [self initializeWithArchivePath:url.path];
    }
    
    return self;
}

- (void)initializeWithArchivePath:(NSString *)source {
    self.filesToData = [NSMutableDictionary dictionary];
    self.urlsToManifest = [NSMutableDictionary dictionary];
    
    NSString *destination = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([SSZipArchive unzipFileAtPath:source toDestination:destination]) {
        NSArray *files = [fileManager contentsOfDirectoryAtPath:destination error:nil];
        
        if ([files isKindOfClass:[NSArray class]]) {
            for (NSString *fileName in files) {
                NSString *filePath = [destination stringByAppendingPathComponent:fileName];
                BOOL isDirectory = NO;
                [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
                
                if (!isDirectory) {
                    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
                    if (!fileData) {
                        continue;
                    }
                    
                    if ([fileName isEqualToString:@"manifest.json"]) {
                        self.manifest = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
                    } else {
                        [self.filesToData setObject:fileData forKey:fileName];
                    }
                }
            }
            
            if ([self.manifest isKindOfClass:[NSDictionary class]]) {
                for (id file in self.manifest[@"files"]) {
                    NSString *key = [LEANUrlCache urlWithoutProtocol:file[@"url"]];
                    [self.urlsToManifest setObject:file forKey:key];
                }
            }
        }
    }
    
    [fileManager removeItemAtPath:destination error:nil];
}

- (BOOL)hasCacheForRequest:(NSURLRequest*)request
{
    if (!self.urlsToManifest) return NO;
    
    NSString *urlString = [LEANUrlCache urlWithoutProtocol:[[request URL] absoluteString]];
    id cached = self.urlsToManifest[urlString];
    if (cached) {
        return YES;
    } else {
        return NO;
    }
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    if (!self.urlsToManifest) return nil;
    
    NSString *urlString = [LEANUrlCache urlWithoutProtocol:[[request URL] absoluteString]];
    id cached = self.urlsToManifest[urlString];
    if (cached) {
        NSString *internalPath = cached[@"path"];
        NSData *data = self.filesToData[internalPath];
        if (data) {
            NSString *mimeType = cached[@"mimetype"];
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:NSURLResponseUnknownLength textEncodingName:nil];
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];

            return cachedResponse;
        }
    }
    
    return nil;
}

+ (NSString*)urlWithoutProtocol:(NSString*)url
{
    NSRange loc = [url rangeOfString:@":"];
    if (loc.location == NSNotFound) {
        return url;
    } else {
        return [url substringFromIndex:loc.location+1];
    }
    
}

@end
