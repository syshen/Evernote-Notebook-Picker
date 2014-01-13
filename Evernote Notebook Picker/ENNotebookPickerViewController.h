//
//  ENNotebookPickerViewController.h
//  Notebook Picker Sample
//
//  Created by syshen on 1/6/14.
//  Copyright (c) 2014 syshen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EvernoteSDK.h>

@interface ENNotebookPickerViewController : UIViewController

+ (id) controllerWithCompletion:(void (^)(NSError *error, EDAMNotebook* notebook))completionBlock;

@property (nonatomic, copy) void (^completionBlock)(NSError *error, EDAMNotebook *notebook);

@end
