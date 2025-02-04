//
//  GNLogManager.m
//  GonativeIO
//
//  Created by bld on 11/29/22.
//  Copyright © 2022 GoNative.io LLC. All rights reserved.
//

#import "GNLogManager.h"

@interface GNLogManager()
@property WKWebView *webview;
@end

@implementation GNLogManager

- (instancetype)initWithWebview:(WKWebView *)webview enabled:(BOOL)enabled {
    self = [super init];
    if (self) {
        self.webview = webview;
        
        if (enabled) {
            [self enableLogging];
        }
    }
    return self;
}

- (void)enableLogging {
    NSString *js = @" "
    " function medianInterceptConsoleLogs(type, ...data) { "
    "    data = data.map(item => { "
    "       if (typeof item === 'object') { "
    "          return JSON.stringify(item, undefined, 2); "
    "       } else { "
    "          return item.toString(); "
    "       } "
    "    }).join(' '); "
    "    var message = { data: { data, type }, medianCommand: 'median://webconsolelogs/print' }; "
    "    window.webkit?.messageHandlers?.JSBridge?.postMessage(message); "
    " } "
    " var console = { "
    "    log: function(...data) { "
    "       medianInterceptConsoleLogs('console.log', ...data); "
    "    }, "
    "    error: function(...data) { "
    "       medianInterceptConsoleLogs('console.error', ...data); "
    "    }, "
    "    warn: function(...data) { "
    "       medianInterceptConsoleLogs('console.warn', ...data); "
    "    }, "
    "    debug: function(...data) { "
    "       medianInterceptConsoleLogs('console.debug', ...data); "
    "    }, "
    " }; "
    " ";
    
    [self.webview evaluateJavaScript:js completionHandler:nil];
    NSLog(@"Web console logs enabled");
}

- (void)handleUrl:(NSURL *)url query:(NSDictionary *)query {
    if (![url.host isEqualToString:@"webconsolelogs"] || ![url.path isEqualToString:@"/print"]) {
        return;
    }
    
    @try {
        NSLog(@"[%@] %@", query[@"type"], query[@"data"]);
    } @catch(id exception) {
        // Do nothing
    }
}

@end
