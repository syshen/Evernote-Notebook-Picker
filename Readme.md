#Evernote Notebook Picker
This is a simple UI wrapper for user to pick one of notebooks from his/her Evernote accounts. 
For a Evernote heavy user, he/she will have lots of notebook. A traditional notebook picker with a simple table view isn't efficient. But this notebook picker will stack the notebooks based on user's notebook and stack hierarchy, and also provide a search function to search by keywords. 

<img src="http://f.cl.ly/items/1K410V2e3f0J0C1k401D/Screen%20Shot%202014-03-06%20at%2010.06.12%20PM.png" width="500"/>

## How to install
The easiest installation is via cocoapods, simply include EvernoteNotebookPicker in your Podfile, and `pod install`.

If you want to include with source code directly, drag the entire "Evernote Notebook Picker" folder, and NotebookPicker.bundle into your project. 

## How to use

First, you need to let user login with his Evernote account, get the authentication session. 

Then:

    UIViewController *vc = [ENNotebookPickerViewController controllerWithCompletion:^(EDAMNotebook *notebook) {
        // notebook is the user selected notebook
    }];
    [self presentViewController:vc animated:YES completion:nil];


## Contact

@syshen

http://pineco.me

