//
//  ENPViewController.m
//  Notebook Picker Sample
//
//  Created by syshen on 1/6/14.
//  Copyright (c) 2014 syshen. All rights reserved.
//

#import "ENPViewController.h"
#import <Evernote-SDK-iOS/EvernoteSDK.h>
#import "ENNotebookPickerViewController.h"

@interface ENPViewController ()

@end

@implementation ENPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void) viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  if([[EvernoteSession sharedSession] isAuthenticated]) {
    UIViewController *vc = [ENNotebookPickerViewController controller];
    [self presentViewController:vc animated:YES completion:nil];
  }
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonTapped:(id)sender {
  [[EvernoteSession sharedSession] authenticateWithViewController:self
                                                completionHandler:^(NSError *error) {
  
                                                }];
  
}

@end
