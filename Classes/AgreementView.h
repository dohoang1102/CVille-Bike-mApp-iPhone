//
//  AgreementView.h
//  CycleTracks
//
//  Created by Harsha Chenji on 4/10/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol AgreementViewControllerDelegate<NSObject>
- (void)didDismissModalViewWithProceed;
- (void)didDismissModalViewWithQuit;
@end

@interface AgreementView : UIViewController<AgreementViewControllerDelegate>
@property (nonatomic,strong) IBOutlet UITextView *tview;
@property (nonatomic,strong) IBOutlet UIWebView *webview;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
