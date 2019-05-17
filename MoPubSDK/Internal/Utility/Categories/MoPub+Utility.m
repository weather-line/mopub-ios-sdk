//
//  MoPub+Utility.m
//
//  Copyright 2018-2019 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MoPub+Utility.h"

@implementation MoPub (Utility)

+ (void)openURL:(NSURL*)url {
    [self openURL:url options:@{} completion:nil];
}

+ (void)openURL:(NSURL*)url
        options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
     completion:(void (^ __nullable)(BOOL success))completion {
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:url options:options completionHandler:completion];
    } else {
        completion([[UIApplication sharedApplication] openURL:url]);
    }
}

@end
