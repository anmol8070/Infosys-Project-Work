//
//  LEANLoadingSpinnerManager.h
//  MedianIOS
//
//  Created by Kevz on 8/30/24.
//  Copyright © 2024 GoNative.io LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEANWebViewController.h"

@interface LEANLoadingSpinnerManager : NSObject

@property UIActivityIndicatorView *activityIndicator;

- (instancetype)initWithVc:(UIViewController *)vc;
- (void)startAnimationWithWvc:(LEANWebViewController *)wvc;
- (void)stopAnimation;

@end
