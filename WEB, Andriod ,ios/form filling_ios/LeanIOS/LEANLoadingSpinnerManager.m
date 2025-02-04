//
//  LEANLoadingSpinnerManager.m
//  Median
//
//  Created by Mahusai on 8/30/24.
//  Copyright © 2024 GoNative.io LLC. All rights reserved.
//

#import "LEANLoadingSpinnerManager.h"
#import "LEANAppDelegate.h"
@import GoNativeCore;

@interface LEANLoadingSpinnerManager()
@property id<GNController> controller;
@end

@implementation LEANLoadingSpinnerManager

- (instancetype)initWithVc:(UIViewController *)vc {
    self = [super init];
    if (self) {
        self.controller = [((LEANAppDelegate *)[UIApplication sharedApplication].delegate).bridge getControllerForKey:@"loadingSpinner" runner:(id)vc];
    }
    return self;
}

- (void)startAnimationWithWvc:(LEANWebViewController *)wvc {
    if (self.controller) {
        [self.controller triggerEvent:@"showLoadingSpinner"];
        return;
    }
    
    if (!self.activityIndicator) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.activityIndicator.color = [UIColor colorNamed:@"activityIndicatorColor"];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [wvc.view addSubview:self.activityIndicator];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.activityIndicator.centerXAnchor constraintEqualToAnchor:wvc.view.centerXAnchor],
            [self.activityIndicator.centerYAnchor constraintEqualToAnchor:wvc.view.centerYAnchor]
        ]];
    }
    
    self.activityIndicator.alpha = 1.0;
    [self.activityIndicator startAnimating];
}

- (void)stopAnimation {
    if (self.controller) {
        [self.controller triggerEvent:@"hideLoadingSpinner"];
        return;
    }
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
        self.activityIndicator.alpha = 0.0;
    } completion:^(BOOL finished){
        [self.activityIndicator stopAnimating];
    }];
}

@end
