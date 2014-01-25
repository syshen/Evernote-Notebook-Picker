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
@property (nonatomic, strong) EDAMNotebook *selectedNotebook;
@end

@implementation ENPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void) viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  if([[EvernoteSession sharedSession] isAuthenticated] && !self.selectedNotebook) {
    NSArray *existingNotebooks = @[@"3a6fc705-e291-4866-a6e2-689453e3e51d", @"421249cd-4b3e-422a-bbb1-8865480daf71", @"ae216f3b-1f48-4c54-81f7-cd3ff9c04565"];
    UIViewController *vc = [ENNotebookPickerViewController
                            controllerWithDisabledNotebooks:existingNotebooks
                            completion:^(NSError *error, EDAMNotebook *notebook) {
                              self.selectedNotebook = notebook;
    }];
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
