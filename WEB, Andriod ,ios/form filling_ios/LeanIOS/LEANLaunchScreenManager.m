//
//  LEANLaunchScreenManager.m
//  Median
//
//  Created by bld on 8/11/23.
//  Copyright © 2023 Median. All rights reserved.
//

#import "LEANLaunchScreenManager.h"
#import "LEANAppDelegate.h"
#import "GonativeIO-Swift.h"
@import GoNativeCore;

@interface LEANLaunchScreenManager()
@property id<GNController> controller;
@property UIImageView *launchScreen;
@property BOOL isShown;
@end

@implementation LEANLaunchScreenManager

+ (LEANLaunchScreenManager *)sharedManager {
    static LEANLaunchScreenManager *shared;
    @synchronized(self) {
        if (!shared) {
            shared = [[LEANLaunchScreenManager alloc] init];
        }
        return shared;
    }
}

- (void)showWithParentViewController:(UIViewController *)vc {
    if (self.isShown) {
        return;
    }
    
    self.isShown = YES;
    
    self.controller = [((LEANAppDelegate *)[UIApplication sharedApplication].delegate).bridge getControllerForKey:@"splashScreen" runner:(id)vc];
    
    if (self.controller) {
        [self.controller triggerEvent:@"showSplashScreen"];
        return;
    }
    
    self.launchScreen = [[UIImageView alloc] init];
    self.launchScreen.image = [UIImage imageNamed:@"LaunchBackground"];
    self.launchScreen.clipsToBounds = YES;
    self.launchScreen.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView *centerImageView = [[UIImageView alloc] init];
    centerImageView.image = [UIImage imageNamed:@"LaunchCenter"];
    centerImageView.contentMode = UIViewContentModeScaleAspectFit;
    centerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.launchScreen addSubview:centerImageView];
    UIWindow *currentWindow = [UIApplication sharedApplication].currentKeyWindow;
    [currentWindow addSubview:self.launchScreen];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.launchScreen.topAnchor constraintEqualToAnchor:currentWindow.topAnchor],
        [self.launchScreen.bottomAnchor constraintEqualToAnchor:currentWindow.bottomAnchor],
        [self.launchScreen.leadingAnchor constraintEqualToAnchor:currentWindow.leadingAnchor],
        [self.launchScreen.trailingAnchor constraintEqualToAnchor:currentWindow.trailingAnchor]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [centerImageView.widthAnchor constraintEqualToConstant:200],
        [centerImageView.heightAnchor constraintEqualToConstant:400],
        [centerImageView.centerXAnchor constraintEqualToAnchor:self.launchScreen.centerXAnchor],
        [centerImageView.centerYAnchor constraintEqualToAnchor:self.launchScreen.centerYAnchor]
    ]];
}

- (void)hide {
    if (self.controller) {
        [self.controller triggerEvent:@"hideSplashScreen"];
        return;
    }
    
    if (self.launchScreen) {
        [self.launchScreen removeFromSuperview];
        self.launchScreen = nil;
    }
}

- (void)hideAfterDelay:(double)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hide];
    });
}

@end
