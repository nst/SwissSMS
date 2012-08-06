//
//  SwissSMS_AppDelegate.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 07.04.07.
//  Copyright Nicolas Seriot 2007 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import "AbstractSender.h"
#import "Message.h"

@interface SwissSMS_AppDelegate : NSObject <NSToolbarDelegate> {
    IBOutlet NSTokenField *tokenField;
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *prefsWindow;
	IBOutlet NSTextView *messageField;
	IBOutlet NSArrayController *messagesController;
	IBOutlet NSUserDefaultsController *defaultsController;
	IBOutlet NSLevelIndicator *messageSendingLevelIndicator;
    IBOutlet NSPanel *messageInspector;
    IBOutlet NSView *searchItemView;
    IBOutlet NSView *senderItemView;
	IBOutlet NSTableView *tableView;
	IBOutlet NSButton *sendButton;
    
	IBOutlet NSPanel *loginPanel;
	IBOutlet NSTextField *instructionField;
	IBOutlet NSTextField *loginField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *rememberCheckbox;
	MPSemaphoreID loginSemaphore;
	BOOL userCancelledLogin;
	BOOL messageSendingLevelIndicatorEnabled;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	AbstractSender *smsSender;
	ABPerson *firstRecipient;
	NSArray *recipients;
	
	NSMutableArray *plugins;
    
    NSToolbar *toolbar;
    NSArray *messagesSortDescriptors;    
	NSNumber *indicatorValue;
    double indicatorCriticalValue;
	NSString *currentStatus;
    NSString *exportStatusBottom;
    NSString *messageInfo;
    NSString *messageFieldString;

    IBOutlet NSArrayController *abPersonController;
    ABAddressBook *sharedAddressBook;
    NSPredicate *mobileFilterPredicate;
    NSArray *addressBookSortDescriptors;
    NSString *comboString;
	
    BOOL bpeIsRunning;
    BOOL exportToBPEIsAllowed;
    BOOL isSending;
    BOOL messageInspectorNameIsBold;
	BOOL isWaking;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)sendMessage:sender;
- (IBAction)removeSelectedMessages:sender;
- (IBAction)saveAndClosePrefsWindow:sender;
- (IBAction)newMessage:sender;
- (IBAction)openImForCurrentRecipient:sender;
- (IBAction)openImForSelectedMessageGuessedPerson:sender;
- (IBAction)openPreferences:sender;
- (IBAction)toggleFlagOnSelectedMessages:sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)openCurrentRecipientInAB:sender;
- (IBAction)endLoginSheet:(id)sender;
- (void)openMessageInspector;
- (AbstractSender *)senderWithClassName:(NSString *)name;

- (NSString *)metadataDirectoryPath;
- (NSString *)metadataFileExtension;

- (void)registerAsObserver;
- (SwissSMSSendingStatus)sendMessageInNewThread:(id)sender;

- (NSDictionary *)keychainLoginAndPasswordForSender:(AbstractSender *)sender;

- (NSArray *)allMessages;

- (void)searchForPlugins;
- (void)setServiceOrDefaultServiceIfEmpty;
- (NSArray *)availableServicesNames;

// toolbar menu actions
- (IBAction)customize:(id)sender;
- (IBAction)showhide:(id)sender;

@end
