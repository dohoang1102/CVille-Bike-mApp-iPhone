//
//  PopupAgreementView.h
//  CycleTracks
//
//  Created by Harsha on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AgreementView.h"

@interface PopupAgreementView : UIViewController 
@property (nonatomic, strong) IBOutlet UITextView *tview;
@property (nonatomic, strong) id<AgreementViewControllerDelegate> vcdelegate;

- (IBAction)proceedButtonPressed:(id)sender;
- (IBAction)quitButtonPressed:(id)sender;
@end
