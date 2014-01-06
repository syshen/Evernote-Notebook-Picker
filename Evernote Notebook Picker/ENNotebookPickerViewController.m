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

@interface ENNotebookPickerViewController () <ExpandableTableViewDataSource, ExpandableTableViewDelegate, UISearchDisplayDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet ExpandableTableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *entries;
@property (nonatomic, strong) NSMutableArray *searchResults;

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

+ (id) controller {
  ENNotebookPickerViewController *picker = [[ENNotebookPickerViewController alloc] initWithNibName:@"ENNotebookPickerViewController" bundle:[ENNotebookPickerViewController bundle]];
  
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
  
  UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];

  UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped)];
  
  self.navigationItem.rightBarButtonItem = done;
  self.navigationItem.leftBarButtonItem = cancel;
  
  [self.tableView registerNib:[UINib nibWithNibName:@"ENStackCell" bundle:[[self class] bundle]] forCellReuseIdentifier:@"StackCell"];
//  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"StackCell"];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"InStackCell"];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NotebookCell"];
  
  self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
  self.tableView.tableHeaderView = self.searchBar;
  
  _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
//  _searchDisplayController.searchBar = self.searchBar;
  _searchDisplayController.delegate = self;
  _searchDisplayController.searchResultsDataSource = self;
//  _searchDisplayController.searchResultsDelegate = self;
  
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
 
  } failure:^(NSError *error) {
    NSLog(@"Fail to load : %@", error);
  }];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) doneButtonTapped {
  
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  
}

- (void) cancelButtonTapped {
  
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  
}

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
  
  self.searchResults = [NSMutableArray array];
  for (ENPEntry *entry in self.entries) {
    if (entry.type == ENPEntryTypeNotebook) {
      if ([entry.name hasPrefix:searchString]) {
        [self.searchResults addObject:entry.notebook];
      }
    } else {
      for (EDAMNotebook *notebook in entry.stackedNotebooks) {
        if ([notebook.name hasPrefix:searchString]) {
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
    cell.separatorInset = UIEdgeInsetsZero;

    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"down" bundle:[[self class] bundle]]];
    return cell;

  } else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotebookCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    cell.accessoryView = nil;
    cell.separatorInset = UIEdgeInsetsZero;

    cell.textLabel.text = entry.name;
    return cell;

  }

}


- (void) tableView:(ExpandableTableView *)tableView willExpandSection:(NSUInteger)section {
  ENPEntry *entry = self.entries[section];
  if (entry.type == ENPEntryTypeStack) {
    ENStackCell *cell = (ENStackCell*)[tableView cellForSection:section];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"up" bundle:[[self class] bundle]]];
  }
}

- (void) tableView:(ExpandableTableView *)tableView willContractSection:(NSUInteger)section {
  ENPEntry *entry = self.entries[section];
  if (entry.type == ENPEntryTypeStack) {
    ENStackCell *cell = (ENStackCell*)[tableView cellForSection:section];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:@"down" bundle:[[self class] bundle]]];
  }
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView != self.searchDisplayController.searchResultsTableView) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InStackCell" forIndexPath:indexPath];
    
    EDAMNotebook *notebook = [self.entries[indexPath.section] stackedNotebooks][indexPath.row];
    cell.textLabel.text = notebook.name;
    return cell;
  } else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ResultCell"];
    }
    
    cell.textLabel.text = [self.searchResults[indexPath.row] name];
    
    return cell;

  }
  
}


@end
