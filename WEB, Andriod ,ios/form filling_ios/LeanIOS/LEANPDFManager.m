//
//  LEANPDFManager.m
//  Median
//
//  Created by kevz on 4/2/24.
//  Copyright © 2024 GoNative.io LLC. All rights reserved.
//

#import "LEANPDFManager.h"
#import "LEANUtilities.h"
#import "GonativeIO-Swift.h"

#define TAB_BAR_HEIGHT 49

@interface LEANPDFViewController : UIViewController <UISearchBarDelegate, PDFViewDelegate>
@property NSURL *pdfUrl;
@property PDFView *pdfView;
@property PDFDocument *pdfDocument;
@property UIStackView *bottomTabView;
@property UISearchBar *searchBar;
@property UILabel *pageLabel;
@property UIActivityIndicatorView *activityIndicator;
@end

@implementation LEANPDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavigationItems];
    [self setupNavigationBar];
    [self showActivityIndicator];
    
    NSString *filename = self.pdfUrl.lastPathComponent;
    NSURL *directory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    
    [LEANUtilities downloadUrl:self.pdfUrl filename:filename directory:directory completion:^(NSURL *fileUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (fileUrl) {
                self.pdfUrl = fileUrl;
            }
            
            [self hideActivityIndicator];
            [self setupPdfView];
            [self setupPdfPage];
            [self setupBottomBar];
        });
    }];
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.scrollEdgeAppearance = self.navigationController.navigationBar.standardAppearance;
    if ([[GoNativeAppConfig sharedAppConfig].iosTheme isEqualToString:@"dark"]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.view.backgroundColor = [UIColor blackColor];
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.view.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void)setupNavigationItems {
    self.navigationItem.titleView = nil;
    
    self.title = self.pdfUrl.lastPathComponent;
    NSDictionary *textAttributes = @{ NSForegroundColorAttributeName: [UIColor colorNamed:@"titleColor"] };
    [self.navigationController.navigationBar setTitleTextAttributes:textAttributes];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0] };
    [doneButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    doneButton.tintColor = [UIColor colorNamed:@"tintColor"];
    self.navigationItem.rightBarButtonItem = doneButton;
    [self.navigationItem setHidesBackButton:YES animated:NO];
}

- (void)showActivityIndicator {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.color = [UIColor colorNamed:@"activityIndicatorColor"];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicator];
    [NSLayoutConstraint activateConstraints:@[
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
    [self.activityIndicator startAnimating];
}

- (void)hideActivityIndicator {
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
    self.activityIndicator = nil;
}

- (void)setupBottomBar {
    UIEdgeInsets safeAreaInsets = UIApplication.sharedApplication.currentKeyWindow.safeAreaInsets;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:blurView];
    
    [NSLayoutConstraint activateConstraints:@[
        [blurView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [blurView.heightAnchor constraintEqualToConstant:safeAreaInsets.bottom + TAB_BAR_HEIGHT]
    ]];
    
    self.bottomTabView = [[UIStackView alloc] init];
    self.bottomTabView.axis = UILayoutConstraintAxisHorizontal;
    self.bottomTabView.distribution = UIStackViewDistributionFillEqually;
    self.bottomTabView.alignment = UIStackViewAlignmentTop;
    self.bottomTabView.translatesAutoresizingMaskIntoConstraints = NO;

    [blurView.contentView addSubview:self.bottomTabView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.bottomTabView.bottomAnchor constraintEqualToAnchor:blurView.bottomAnchor],
        [self.bottomTabView.leadingAnchor constraintEqualToAnchor:blurView.leadingAnchor],
        [self.bottomTabView.trailingAnchor constraintEqualToAnchor:blurView.trailingAnchor],
        [self.bottomTabView.topAnchor constraintEqualToAnchor:blurView.topAnchor]
    ]];
    
    blurView.layer.shadowColor = [UIColor blackColor].CGColor;
    blurView.layer.shadowOpacity = 0.1;
    blurView.layer.shadowOffset = CGSizeMake(0, -2);
    blurView.layer.shadowRadius = 4;
    
    [self createButtonWithIcon:@"square.and.arrow.up" action:@selector(share)];
    [self createButtonWithIcon:@"magnifyingglass" action:@selector(search)];
    [self createButtonWithIcon:@"printer" action:@selector(print)];
}

- (void)createButtonWithIcon:(NSString *)iconName action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20];
    UIImage *icon = [[UIImage systemImageNamed:iconName] imageByApplyingSymbolConfiguration:config];
    [button setImage:icon forState:UIControlStateNormal];
    [button.imageView setTintColor:[UIColor colorNamed:@"tintColor"]];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bottomTabView addArrangedSubview:button];
    [button setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [button setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    [NSLayoutConstraint activateConstraints:@[
        [button.heightAnchor constraintEqualToConstant:50],
        [button.topAnchor constraintEqualToAnchor:self.bottomTabView.topAnchor constant:5]
    ]];
}

- (void)setupPdfView {
    self.pdfView = [[PDFView alloc] init];
    self.pdfView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pdfView.insetsLayoutMarginsFromSafeArea = YES;
    
    UIView *firstSubview = self.pdfView.subviews.firstObject;
    if ([firstSubview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)firstSubview;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, TAB_BAR_HEIGHT, 0);
    }
    
    [self.view addSubview:self.pdfView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.pdfView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.pdfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pdfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pdfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    self.pdfDocument = [[PDFDocument alloc] initWithURL:self.pdfUrl];
    self.pdfView.document = self.pdfDocument;
    self.pdfView.autoScales = YES;
    self.pdfView.delegate = self;
}

- (void)setupPdfPage {
    self.pageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageLabel.textColor = [UIColor labelColor];
    self.pageLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.pageLabel sizeToFit];

    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.backgroundColor = [UIColor systemGray3Color];
    containerView.layer.cornerRadius = 5;
    containerView.layer.opacity = 0.8;
    [containerView addSubview:self.pageLabel];
    [self.pdfView addSubview:containerView];

    [NSLayoutConstraint activateConstraints:@[
        [self.pageLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10],
        [self.pageLabel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:6],
        [self.pageLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10],
        [self.pageLabel.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-6],
        [containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20]
    ]];
    
    [self pageDidChange:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pageDidChange:) name:PDFViewPageChangedNotification object:nil];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share {
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[self.pdfUrl] applicationActivities:nil];
    avc.popoverPresentationController.sourceView = self.view;
    [self presentViewController:avc animated:YES completion:nil];
}

- (void)print {
    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    if (!printController) {
        return;
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:self.pdfUrl completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (location) {
            NSData *pdfData = [NSData dataWithContentsOfURL:location];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (pdfData) {
                    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
                    printInfo.outputType = UIPrintInfoOutputGeneral;
                    printInfo.jobName = self.pdfUrl.lastPathComponent;
                    
                    printController.printingItem = pdfData;
                    printController.printInfo = printInfo;
                    
                    [printController presentAnimated:YES completionHandler:nil];
                }
            });
        }
    }];
    
    [downloadTask resume];
}

- (void)search {
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.delegate = self;
    
    self.navigationItem.titleView = self.searchBar;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"button-cancel", @"Button: Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(searchCanceled)];
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationItem setLeftBarButtonItems:nil animated:YES];
    [self.navigationItem setRightBarButtonItems:@[cancelButton] animated:YES];
    [self.searchBar becomeFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    [self removeAnnotations];
    
    NSArray<PDFSelection *> *selectionList = [self.pdfDocument findString:searchBar.text withOptions:NSCaseInsensitiveSearch];
    
    if (selectionList.firstObject) {
        [self.pdfView goToPage:selectionList.firstObject.pages.firstObject];
    }
    
    for (PDFSelection *selection in selectionList) {
        for (PDFPage *page in selection.pages) {
            CGRect selectionBounds = [selection boundsForPage:page];
            PDFAnnotation *highlight = [[PDFAnnotation alloc] initWithBounds:selectionBounds forType:PDFAnnotationSubtypeHighlight withProperties:nil];
            highlight.endLineStyle = kPDFLineStyleSquare;
            highlight.color = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            [page addAnnotation:highlight];
        }
    }
}

- (void)removeAnnotations {
    for (NSInteger i = 0; i < self.pdfDocument.pageCount; i++) {
        PDFPage *page = [self.pdfDocument pageAtIndex:i];
        NSArray<PDFAnnotation *> *annotations = [NSArray arrayWithArray:[page annotations]];
        for (PDFAnnotation *annotation in annotations) {
            [page removeAnnotation:annotation];
        }
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self searchCanceled];
}

- (void)searchCanceled {
    [self removeAnnotations];
    [self setupNavigationItems];
    self.bottomTabView.hidden = NO;
}

- (void)pageDidChange:(NSNotification *)notification {
    NSUInteger currentPageNumber = [self.pdfDocument indexForPage:self.pdfView.currentPage] + 1;
    self.pageLabel.text = [NSString stringWithFormat:@"%lu of %lu", (unsigned long)currentPageNumber, (unsigned long)self.pdfDocument.pageCount];
}

@end

@implementation LEANPDFManager

+ (LEANPDFManager *)shared {
    static LEANPDFManager *shared;
    @synchronized(self) {
        if (!shared){
            shared = [[LEANPDFManager alloc] init];
        }
        return shared;
    }
}

- (BOOL)shouldHandleType:(NSString *)type {
    return [type isEqualToString:@"application/pdf"] || [type isEqualToString:@"application/binary"];
}

- (BOOL)shouldHandleResponse:(NSURLResponse * _Nullable)response {
    return [self shouldHandleType:response.MIMEType];
}

- (void)openPDF:(NSURL * _Nullable)url wvc:(UIViewController * _Nonnull)wvc {
    if (!url) {
        return;
    }
    
    LEANPDFViewController *vc = [[LEANPDFViewController alloc] init];
    vc.pdfUrl = url;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [wvc presentViewController:navController animated:YES completion:nil];
}

@end
