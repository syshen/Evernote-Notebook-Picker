//
//  ENNotebookPickerViewController.m
//  Notebook Picker Sample
//
//  Created by syshen on 1/6/14.
//  Copyright (c) 2014 syshen. All rights reserved.
//

#import "ENNotebookPickerViewController.h"
#import "ExpandableTableView.h"
#import "ENStackCell.h"
#import "UIImage+ENPAdditions.h"
#import <EvernoteSDK.h>

NS_ENUM(NSInteger, ENPEntryType) {
  ENPEntryTypeStack = 0,
  ENPEntryTypeNotebook = 1
};

@interface ENPEntry: NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) enum ENPEntryType type;
@property (nonatomic, strong) EDAMNotebook *notebook;
@property (nonatomic, assign) NSInteger noteCount;
@property (nonatomic, strong) NSMutableArray *stackedNotebooks;
@end

@implementation ENPEntry
@end

@interface NSString (Additions)
- (BOOL) hasSubstring:(NSString*)aString;
@end
@implementation NSString (Additions)

- (BOOL) hasSubstring:(NSString *)aString {
  NSRange range = [self rangeOfString:aString options:NSCaseInsensitiveSearch];
  return range.location != NSNotFound;
}
@end

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define isIOS7 SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")

@interface ENNotebookPickerViewController () <ExpandableTableViewDataSource, ExpandableTableViewDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet ExpandableTableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *entries;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) UIActivityIndicatorView *loadingActivity;
@property (nonatomic, strong) NSArray *disabledNotebooks; // array of EDAMNotebook ID
@end

@implementation ENNotebookPickerViewController {
  UISearchDisplayController *_searchDisplayController;
}

+ (NSBundle*)bundle {
  static NSBundle *bundle = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"NotebookPicker" ofType:@"bundle"];
    bundle = [NSBundle bundleWithPath:bundlePath];
  });
  
  return bundle;
}

+ (id) controllerWithDisabledNotebooks:(NSArray*)disabledNotebooks
                            completion:(void (^)(NSError *error, EDAMNotebook* notebook))completionBlock {
  ENNotebookPickerViewController *picker = [[ENNotebookPickerViewController alloc] initWithNibName:@"ENNotebookPickerViewController" bundle:[ENNotebookPickerViewController bundle]];
  picker.completionBlock = completionBlock;
  picker.disabledNotebooks = disabledNotebooks;
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
  
  return nav;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped)];
  
  self.navigationItem.leftBarButtonItem = cancel;
  
  [self.tableView registerNib:[UINib nibWithNibName:@"ENStackCell" bundle:[[self class] bundle]] forCellReuseIdentifier:@"StackCell"];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"InStackCell"];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NotebookCell"];
  
  self.loadingActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.loadingActivity.frame = CGRectMake(self.tableView.frame.size.width/2 - self.loadingActivity.frame.size.width/2, 140, self.loadingActivity.frame.size.width, self.loadingActivity.frame.size.height);
  [self.loadingActivity setHidesWhenStopped:YES];

  [self.loadingActivity setColor:[UIColor blackColor]];
  [self.tableView addSubview:self.loadingActivity];
  [self.loadingActivity startAnimating];

  [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:45.0/255.0 green:190.0/255.0 blue:96.0/255.0 alpha:1.0]];
  [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
  self.title = @"Select one notebook";
  
  self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
  self.tableView.tableHeaderView = self.searchBar;
  
  _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
  _searchDisplayController.delegate = self;
  _searchDisplayController.searchResultsDataSource = self;
  _searchDisplayController.searchResultsDelegate = self;
  
  __weak ENNotebookPickerViewController *wSelf = self;
  [[EvernoteNoteStore noteStore] listNotebooksWithSuccess:^(NSArray *notebooks) {

    NSMutableArray *entries = [NSMutableArray array];

    ENPEntry *(^findEntryForName)(NSString *) = ^ENPEntry *(NSString *name) {
      for (ENPEntry *e in entries) {
        if ([e.name isEqualToString:name])
          return e;
      }
      return nil;
    };
    
    for (EDAMNotebook *notebook in notebooks) {
    
      if (notebook.stack) {
        ENPEntry *existingEntry = findEntryForName(notebook.stack);

        if (existingEntry && existingEntry.type == ENPEntryTypeStack) {
          [existingEntry.stackedNotebooks addObject:notebook];
        } else {
          ENPEntry *newEntry = [[ENPEntry alloc] init];
          newEntry.type = ENPEntryTypeStack;
          newEntry.name = notebook.stack;
          newEntry.stackedNotebooks = [NSMutableArray arrayWithObject:notebook];
          [entries addObject:newEntry];
        }
      } else {
        ENPEntry *newEntry = [[ENPEntry alloc] init];
        newEntry.type = ENPEntryTypeNotebook;
        newEntry.notebook = notebook;
        newEntry.name = notebook.name;
        [entries addObject:newEntry];
      }
      
    }

    [entries sortUsingComparator:^NSComparisonResult(ENPEntry *obj1, ENPEntry *obj2) {
      return [obj1.name compare:obj2.name];
    }];
    wSelf.entries = entries;
    
    [wSelf.tableView reloadData];
    [wSelf.loadingActivity stopAnimating];
 
  } failure:^(NSError *error) {
    NSLog(@"Fail to load : %@", error);
    [wSelf.loadingActivity stopAnimating];
    
    if (wSelf.completionBlock)
      wSelf.completionBlock(error, nil);
  }];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) cancelButtonTapped {
  
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  
}

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
  
  self.searchResults = [NSMutableArray array];
  for (ENPEntry *entry in self.entries) {
    if (entry.type == ENPEntryTypeNotebook) {
      if ([entry.name hasSubstring:searchString]) {
        [self.searchResults addObject:entry.notebook];
      }
    } else {
      for (EDAMNotebook *notebook in entry.stackedNotebooks) {
        if ([notebook.name hasSubstring:searchString]) {
          [self.searchResults addObject:notebook];
        }
      }
    }
  }
  return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return 1;
  } else {
    return self.entries.count;
  }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return self.searchResults.count;
  } else {
    ENPEntry *entry = self.entries[section];
    if (entry.type == ENPEntryTypeNotebook)
      return 0;
    else
      return entry.stackedNotebooks.count;
  }
}

- (UITableViewCell *)tableView:(ExpandableTableView *)tableView cellForGroupInSection:(NSUInteger)section {
  ENPEntry *entry = self.entries[section];

  if (entry.type == ENPEntryTypeStack) {
    ENStackCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StackCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
  
    cell.titleLabel.text = [entry name];
    if (isIOS7)
      cell.separatorInset = UIEdgeInsetsZero;

    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"expand" bundle:[[self class] bundle]]];
    return cell;

  } else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotebookCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:entry.notebook.guid]) {
      cell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"check" bundle:[[self class] bundle]]];
      cell.accessoryView.frame = CGRectMake(0, 0, 20, 20);
    } else {
      cell.accessoryView = nil;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if (isIOS7)
      cell.separatorInset = UIEdgeInsetsZero;

    cell.textLabel.text = entry.name;
    return cell;

  }

}

- (void) tableView:(ExpandableTableView *)tableView willExpandSection:(NSUInteger)section {
  ENPEntry *entry = self.entries[section];
  if (entry.type == ENPEntryTypeStack) {
    ENStackCell *cell = (ENStackCell*)[tableView cellForSection:section];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"collapse" bundle:[[self class] bundle]]];
  }
}

- (void) tableView:(ExpandableTableView *)tableView willContractSection:(NSUInteger)section {
  ENPEntry *entry = self.entries[section];
  if (entry.type == ENPEntryTypeStack) {
    ENStackCell *cell = (ENStackCell*)[tableView cellForSection:section];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"expand" bundle:[[self class] bundle]]];
  }
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView != self.searchDisplayController.searchResultsTableView) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InStackCell" forIndexPath:indexPath];
    
    EDAMNotebook *notebook = [self.entries[indexPath.section] stackedNotebooks][indexPath.row];
    cell.textLabel.text = notebook.name;
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:notebook.guid]) {
      cell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"check" bundle:[[self class] bundle]]];
      cell.accessoryView.frame = CGRectMake(0, 0, 20, 20);
    } else {
      cell.accessoryView = nil;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    return cell;
  } else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ResultCell"];
    }
    
    cell.textLabel.text = [self.searchResults[indexPath.row] name];
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:[self.searchResults[indexPath.row] guid]]) {
      cell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"check" bundle:[[self class] bundle]]];
      cell.accessoryView.frame = CGRectMake(0, 0, 20, 20);
    } else {
      cell.accessoryView = nil;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;

  }
  
}

- (void) tableView:(ExpandableTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    EDAMNotebook *notebook = self.searchResults[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:notebook.guid])
      return;
    
    if (self.completionBlock)
      self.completionBlock(nil, notebook);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  } else {
    ENPEntry *entry = self.entries[indexPath.section];
    EDAMNotebook *notebook = entry.stackedNotebooks[indexPath.row];
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:notebook.guid]) {
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
      return;
    }

    if (self.completionBlock)
      self.completionBlock(nil, notebook);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void) tableView:(ExpandableTableView *)tableView didExpandSection:(NSUInteger)section {
  
  ENPEntry *entry = self.entries[section];
  if (entry.type == ENPEntryTypeNotebook) {
    if (self.disabledNotebooks && [self.disabledNotebooks containsObject:entry.notebook.guid])
      return;

    if (self.completionBlock)
      self.completionBlock(nil, entry.notebook);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
  
}

@end
