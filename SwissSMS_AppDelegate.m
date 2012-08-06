//
//  SwissSMS_AppDelegate.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 07.04.07.
//  Copyright Nicolas Seriot 2007 . All rights reserved.
//

#import "SwissSMS_AppDelegate.h"

#import "ABPerson_SwissSMS.h"
#import "ABPerson_SwissSMS_AIM.h"
#import "NSString_SwissSMS.h"
#import "NSWorkspace_SwissSMS.h"
#import "NSFileManager_SwissSMS.h"
#import "NSManagedObjectContext+Metadata.h"

#import "MyPerson.h"

//#import "Sparkle/SUUtilities.h"

#import "FlagImageTransformer.h"

#import <AddressBook/AddressBook.h>
#import <InstantMessage/IMService.h>

#import "KeychainAccess.h"

#import "PreferencesController.h"
#import "SSRecipient.h"

#import "AbstractSender.h"
#import "HTMLForm.h"

@implementation SwissSMS_AppDelegate

/**
 Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "SwissSMS" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"SwissSMS"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle and all of the 
 framework bundles.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error = nil;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"SwissSMS.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}


/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
    
    NSError *error = nil;
    if (![[self managedObjectContext] saveWithMetadata:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSArray *)allMessages {
	NSFetchRequest *fetchRequest = [[self managedObjectModel] fetchRequestTemplateForName:@"allMessages"];
	return [[self managedObjectContext] executeFetchRequest:fetchRequest error:nil];
}

- (void)restoreMessage:(NSString *)aMessage recipients:(NSArray *)someRecipients {
    [self setValue:someRecipients forKey:@"recipients"];
    [self setValue:aMessage forKey:@"messageFieldString"];	
}

- (IBAction)newMessage:(id)sender {
	[[[[self managedObjectContext] undoManager] prepareWithInvocationTarget:self] restoreMessage:messageFieldString recipients:recipients];
	
    [self setValue:nil forKey:@"recipients"];
    [self setValue:@"" forKey:@"currentStatus"];
    [self setValue:@"" forKey:@"messageInfo"];
    [self setValue:@"" forKey:@"messageFieldString"];
	[self setValue:[NSNumber numberWithInt:0] forKey:@"indicatorValue"];
	
	[tokenField becomeFirstResponder];
}

// TODO improve filtering (name, version, ...)
- (void)addClassFromBundlePathIfRelevant:(NSString*)path {
    NSBundle* pluginBundle = [NSBundle bundleWithPath:path];
    if (pluginBundle) {
        NSDictionary* pluginDict = [pluginBundle infoDictionary];
        NSString* pluginName = [pluginDict objectForKey:@"NSPrincipalClass"];
        if (pluginName) {
            Class pluginClass = NSClassFromString(pluginName);
			//NSLog(@"-- %@", [pluginBundle principalClass]);
            if (!pluginClass) {
				[self willChangeValueForKey:@"plugins"];
				[plugins addObject:[[[[pluginBundle principalClass] alloc] init] autorelease]];
				[self didChangeValueForKey:@"plugins"];
            }
        }
    }
	
	//NSLog(@"plugins %@", plugins);
	
	if([plugins count] == 0) {
		// TODO show alert and quit, or at least prevent crash
	}	
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    NSError *error = nil;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
						
            if ([managedObjectContext hasChanges] && ![managedObjectContext saveWithMetadata:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.
                
                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
                
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 
                
                else {
					
                    int alertReturn = NSRunAlertPanel(nil,
                                                      NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", nil) ,
                                                      NSLocalizedString(@"Quit anyway", nil),
                                                      NSLocalizedString(@"Cancel", nil),
                                                      nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}

+ (void)initialize {
//	[[MyPerson class] poseAsClass:[ABPerson class]]; // http://www.cocoabuilder.com/archive/message/cocoa/2007/5/6/182892
    NSArray *keys = [NSArray arrayWithObjects:@"recipients", @"messageFieldString", @"isSending", nil];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"canSendMessage"];
	
    NSArray *keys2 = [NSArray arrayWithObjects:@"bpeIsRunning", nil];
    [self setKeys:keys2 triggerChangeNotificationsForDependentKey:@"exportStatusTop"];
    
	NSArray *keys3 = [NSArray arrayWithObjects:@"SMSService", @"smsSender", @"messageFieldString", nil];
    [self setKeys:keys3 triggerChangeNotificationsForDependentKey:@"messageInfo"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *appDefaultsPath = [[NSBundle mainBundle] pathForResource:@"appDefaults" ofType:@"plist"];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:appDefaultsPath];
    [defaults registerDefaults:appDefaults];
	
	// Migrate versionCheckRunAtStartup to SUCheckAtStartup (Sparkle)
	if ([[defaults dictionaryRepresentation] valueForKey:@"versionCheckRunAtStartup"] != nil) {
		[defaults setBool:[defaults boolForKey:@"versionCheckRunAtStartup"] forKey:@"SUCheckAtStartup"];
		[defaults removeObjectForKey:@"versionCheckRunAtStartup"];
	}
		
	[HTMLForm setUserAgent:[@"SwissSMS/" stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
}

- (void)addPersonWithId:(NSDictionary *)personId {
	ABPerson *p = [ABPerson personFromUniqueId:[personId valueForKey:@"object"]];
	if(!p) {
		NSLog(@"Error: no person found for id %@", personId);
		return;
	}
	
	NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:recipients];
	[temp addObject:p];
	[self willChangeValueForKey:@"recipients"];
	recipients = [[NSArray arrayWithArray:temp] retain];
	[self didChangeValueForKey:@"recipients"];
	[temp release];
	
	[window makeFirstResponder:messageField];
	
	[NSApp activateIgnoringOtherApps:YES];
}

- (id)init {
	self = [super init];
	
	isWaking = YES;
	
    plugins = [[NSMutableArray alloc] init];
	
    sharedAddressBook = [ABAddressBook sharedAddressBook];
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"fullname" ascending:YES];
    addressBookSortDescriptors = [NSArray arrayWithObject:sd];
	[sd release];
	
    FlagImageTransformer *ft;
    
    // create an autoreleased instance of our value transformer
    ft = [[[FlagImageTransformer alloc] init] autorelease];
    
    // register it with the name that we refer to it with
    [NSValueTransformer setValueTransformer:ft forName:@"FlagImageTransformer"];
	
	NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	[nc addObserver:self
           selector:@selector(addPersonWithId:)
               name:@"ch.seriot.SwissSMS.addPersonWithId"
             object:nil];
	
    return self;
}

- (void) dealloc {
    [[IMService notificationCenter] removeObserver:self name:nil object:nil];     
    
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
	
	[plugins release];
	
    [super dealloc];
}

- (void)searchForPlugins {	
	NSString *appPluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
	NSString *userPluginPath = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SwissSMS"] stringByAppendingPathComponent:@"PlugIns"];
	
	NSArray *pluginDirsWithGrowingPriority = [NSArray arrayWithObjects:appPluginPath, userPluginPath, nil];
	NSEnumerator *de = [pluginDirsWithGrowingPriority objectEnumerator];
	NSString *dir;
	while((dir = [de nextObject])) {
		NSEnumerator *pe = [[NSBundle pathsForResourcesOfType:@"bundle" inDirectory:dir] objectEnumerator];
		NSString *pluginPath;
		while ((pluginPath = [pe nextObject])) {
			//NSLog(@"pluginPath %@", pluginPath);
			[self addClassFromBundlePathIfRelevant:pluginPath];
		}
	}	
}

- (NSArray *)availableServicesNames {
	return [plugins valueForKeyPath:@"className"];
}

- (void)playSendingSoundIfEnabledInDefaults {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"playSounds"]) {
		NSString *soundSend = [[NSUserDefaults standardUserDefaults] stringForKey:@"soundSend"];
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundSend byReference:YES];
		[sound play];
		[sound release];
	}
}

- (void)playErrorSoundIfEnabledInDefaults {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"playSounds"]) {
		NSString *soundError = [[NSUserDefaults standardUserDefaults] stringForKey:@"soundError"];
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundError byReference:YES];
		[sound play];
		[sound release];
	}
}

// TODO factorize...
- (void)statusDidChange:(NSString *)status {
    if ([status isEqualToString:@"login"]) {
        [self setValue:[NSNumber numberWithInt:3] forKey:@"indicatorCriticalValue"];
        [self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorValue"];
        [self setValue:NSLocalizedString(@"Login...", nil) forKey:@"currentStatus"];
    } else if ([status isEqualToString:@"keychainError"]) {
        [self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorCriticalValue"];
        [self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorValue"];
        [self setValue:NSLocalizedString(@"Keychain error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else if ([status isEqualToString:@"serviceUnavailableError"]) {
		[self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorCriticalValue"];
        [self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"Service unavailable error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
	} else if ([status isEqualToString:@"loginError"]) {
		[self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorCriticalValue"];
        [self setValue:[NSNumber numberWithInt:1] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"Login error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else if ([status isEqualToString:@"sending"]) {
        [self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorValue"];
        [self setValue:NSLocalizedString(@"Sending...", nil) forKey:@"currentStatus"];
    } else if ([status isEqualToString:@"sendingError"]) {
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorCriticalValue"];
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"Sending error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else if ([status isEqualToString:@"networkError"]) {
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorCriticalValue"];
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"Network error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else if ([status isEqualToString:@"noMoreCreditsError"]) {
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorCriticalValue"];
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"No more credits :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
	} else if ([status isEqualToString:@"pluginInternalError"]) {
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorCriticalValue"];
		[self setValue:[NSNumber numberWithInt:2] forKey:@"indicatorValue"];
		[self setValue:NSLocalizedString(@"Internal plugin error :-(", nil) forKey:@"currentStatus"];
        [self playErrorSoundIfEnabledInDefaults];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else if ([status isEqualToString:@"sent"]) {
        [self setValue:NSLocalizedString(@"Message sent!", nil) forKey:@"currentStatus"];
        [self setValue:[NSNumber numberWithInt:3] forKey:@"indicatorValue"];
        [self playSendingSoundIfEnabledInDefaults];
    } else if ([status isEqualToString:@"cleanupUI"]) {
        [self newMessage:nil];
    } else {
        NSAssert1(nil, @"status did change into a bad status: %@", status);
    }
	if (!window && ![currentStatus isEqualToString:@""]) printf("%s\n", [[self valueForKey:@"currentStatus"] UTF8String]);
}

- (void)recipientDidChange:(id <SSRecipientProtocol>)recipient {
	[self setValue:recipient forKey:@"firstRecipient"];
}

- (void)recipientsDidChange:(id <SSRecipientProtocol>)theRecipients {
	//NSLog(@"recipientsDidChange %@", theRecipients);
	[self setValue:theRecipients forKey:@"recipients"];
}

- (void)bpeDidLaunchOrTerminanteOnMainThread:(NSNumber *)value {
    [self setValue:value forKey:@"bpeIsRunning"];
}

- (void)workspaceDidLaunchApplication:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqual:@"com.reel.BluePhoneElite"]) {
        [self performSelectorOnMainThread:@selector(bpeDidLaunchOrTerminanteOnMainThread:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
    }
}

- (void)workspaceDidTerminateApplication:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqual:@"com.reel.BluePhoneElite"]) {
        [self performSelectorOnMainThread:@selector(bpeDidLaunchOrTerminanteOnMainThread:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
    }
}

- (void)registerAsObserver {
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"SMSService"
                                               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                               context:NULL];
	
    [self addObserver:self
           forKeyPath:@"recipients"
              options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
              context:NULL];
	
    [self addObserver:self
           forKeyPath:@"smsSender"
              options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
              context:NULL];
	
	if (!window)
		return;
	
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(workspaceDidLaunchApplication:) 
                                                               name:NSWorkspaceDidLaunchApplicationNotification
                                                             object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(workspaceDidTerminateApplication:) 
                                                               name:NSWorkspaceDidTerminateApplicationNotification
                                                             object:nil];
}

- (void)unregisterForChangeNotification {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"SMSService"];
    
    [self removeObserver:self forKeyPath:@"recipients"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
                                                                  name:NSWorkspaceDidLaunchApplicationNotification
                                                                object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
                                                                  name:NSWorkspaceDidTerminateApplicationNotification
                                                                object:nil];
}

- (NSString *)messageInfo {
    unsigned messageLength = [messageFieldString length];
    NSString *message;
    
    if(messageLength) {
        unsigned numberOfMessages = [smsSender numberOfMessagesForString:messageFieldString];
        NSString *message_s = numberOfMessages > 1 ? NSLocalizedString(@"sendings", nil) : NSLocalizedString(@"sending", nil);
        NSString *character_s = messageLength > 1 ? NSLocalizedString(@"characters", nil) : NSLocalizedString(@"character", nil);
        message = [NSString stringWithFormat:@"%d %@, %d %@", numberOfMessages, message_s, messageLength, character_s];
    } else {
        message = @"";
    }
	
	return message;
}

- (void)setKeyExportToBPEIsAllowed:(NSNumber *)value {
    [self setValue:value forKey:@"exportToBPEIsAllowed"];
}

- (void)manageBPEExportStatus {
    [self setValue:@"" forKey:@"exportStatusBottom"];
    
	if(![[NSFileManager defaultManager] fileExistsAtPath:[NSString bluePhoneEliteExportFilePath]]) {
        [self setValue:[NSNumber numberWithBool:NO] forKey:@"exportToBPEIsAllowed"];
        //[self setValue:NSLocalizedString(@"BluePhoneElite SMS files not found", nil) forKey:@"exportStatusTop"];
		return;
	} else {
        [self setValue:[NSNumber numberWithBool:YES] forKey:@"exportToBPEIsAllowed"];
        //[self setValue:NSLocalizedString(@"Backup your data!", @"") forKey:@"exportStatusTop"];    
    }
}

- (void)personDidChangeStatusOnService:(NSNotification *)notification {
    // TODO refactor this ugly method
    //NSLog(@"personDidChangeStatusOnService %@", [notification object]);
    
    Message *m = [[messagesController selectedObjects] count] == 1 ? [[messagesController selectedObjects] lastObject] : nil;
    
    if(firstRecipient == nil && m == nil) {
        return;
    }
    
    IMService *currentService = [notification object];
    
    NSString *screenName = [[notification userInfo] valueForKey:@"IMPersonScreenName"];
    
    BOOL screenNameBelongsToCurrentRecipient = [[currentService screenNamesForPerson:firstRecipient] containsObject:screenName];
    
    ABPerson *guessedPerson = [ABPerson personFromFullname:[m valueForKey:@"name"] mobilePhone:[m valueForKey:@"phone"]];
    BOOL screenNameBelongsToGuessedPerson = [[currentService screenNamesForPerson:guessedPerson] containsObject:screenName];
    
	// TODO
    if(screenNameBelongsToCurrentRecipient) {
        [firstRecipient willChangeValueForKey:@"imageDataForCurrentIMStatus"];
        [firstRecipient didChangeValueForKey:@"imageDataForCurrentIMStatus"];
    }
    
    if(screenNameBelongsToGuessedPerson) {
        [guessedPerson willChangeValueForKey:@"imageDataForCurrentIMStatus"];
        [guessedPerson didChangeValueForKey:@"imageDataForCurrentIMStatus"];
    }
}

- (void)setupToolbar {
    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"mainToolbar"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [window setToolbar:toolbar];
}

- (AbstractSender *)senderWithClassName:(NSString *)name {
	if(!name) return nil;
	// TODO use predicate
	NSEnumerator *e = [plugins objectEnumerator];
	AbstractSender *s;
	while((s = [e nextObject])) {
		if([[s className] isEqualToString:name]) {
			return s;
		}
	}
	return nil;
}

- (void)setServiceOrDefaultServiceIfEmpty {
    NSString *currentService = [[NSUserDefaults standardUserDefaults] valueForKey:@"SMSService"];
	AbstractSender *sender = [self senderWithClassName:currentService];
	
    if(!sender) {
		sender = [self senderWithClassName:@"RomandieCH"];
		NSLog(@"sender not found, using %@", [sender className]);
        [[NSUserDefaults standardUserDefaults] setValue:@"RomandieCH" forKeyPath:@"SMSService"];
    }
    
	[self setValue:sender forKey:@"smsSender"];
}

- (void)awakeFromNib {
	//NSLog(@"-- awakeFromNib");

	[window makeKeyAndOrderFront:self];
	
	[self setupToolbar];
    
    [self registerAsObserver];
	
    [self manageBPEExportStatus];
    
    [self setValue:[NSNumber numberWithInt:3] forKey:@"indicatorCriticalValue"];
    
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"messageInspectorNameIsBold"];
    
    NSNumber *bpeState = [NSNumber numberWithBool:[[NSWorkspace sharedWorkspace] appIsRunning:@"BluePhoneElite"]];
    [self setValue:bpeState forKey:@"bpeIsRunning"];
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [self setValue:[NSArray arrayWithObject:sd] forKey:@"messagesSortDescriptors"];
    [sd release];
    
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isSending"];
    
	NSTableColumn *flagColumn = [tableView tableColumnWithIdentifier:@"flag"];
	NSImage *flagHeaderImage = [NSImage imageNamed:@"FlaggedHeader.png"];
	NSImageCell *flagHeaderImageCell = [flagColumn headerCell];
	[flagHeaderImageCell setImage:flagHeaderImage];
	[flagColumn setHeaderCell:flagHeaderImageCell];
	
	[[IMService notificationCenter] addObserver:self
                                       selector:@selector(personDidChangeStatusOnService:)
                                           name:IMPersonStatusChangedNotification
                                         object:[IMService serviceWithName:@"AIM"]];
	
	[self searchForPlugins];
    [self setServiceOrDefaultServiceIfEmpty];
	
	[self setValue:[NSPredicate predicateWithFormat:@"phone != nil"] forKey:@"mobileFilterPredicate"];
	
	messageSendingLevelIndicatorEnabled = NO; //disables user interaction, enabled by default
	
	isWaking = NO;	
}

- (void)installOrUpdateTools {
	// delete old unused key
	// TODO remove in version SwissSMS 2.0
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"toolsLastUpdateVersion"];
	
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	
	NSDictionary *automator = [NSDictionary dictionaryWithObjectsAndKeys:@"Send SMS.action", @"name",
							   @"~/Library/Automator/", @"path", nil];
	
	NSDictionary *addressBook = [NSDictionary dictionaryWithObjectsAndKeys:@"Send SMS with SwissSMS.bundle", @"name",
								 @"~/Library/Address Book Plug-Ins/", @"path", nil];
	
	NSArray *tools = [NSArray arrayWithObjects:automator, addressBook, nil];
	NSString *toolName;
	NSString *toolPath;
	NSBundle *installedBundle;
	NSString *installedPath;
	NSString *installedVersion;
	NSDictionary *tool;
	int i;
	for(i = 0; i < [tools count]; i++) {
		tool = [tools objectAtIndex:i];
		toolName = [tool valueForKey:@"name"];
		toolPath = [[NSBundle mainBundle] pathForResource:[toolName stringByDeletingPathExtension] ofType:[toolName pathExtension]];
		installedPath = [[tool valueForKey:@"path"] stringByAppendingPathComponent:toolName];
		installedBundle = [NSBundle bundleWithPath:installedPath];
		installedVersion = [[installedBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"];
		if(!installedBundle/* || (SUStandardVersionComparison(currentVersion, installedVersion) == NSOrderedAscending)*/) {
			[[NSFileManager defaultManager] copyResource:toolPath toChosenDestination:[[tool valueForKey:@"path"] stringByExpandingTildeInPath]];
		}
	}
}

- (void)synchronizeMetadataFiles {
	unsigned messagesCount = [Message messagesCountInContext:[self managedObjectContext]];
	
	NSArray *allMDFiles = [[NSFileManager defaultManager] directoryContentsAtPath:[self metadataDirectoryPath]];
	NSPredicate *mdFilesExtPredicate = [NSPredicate predicateWithFormat:@"SELF endswith %@", [self metadataFileExtension]];
    NSArray *filteredMDFiles = [allMDFiles filteredArrayUsingPredicate:mdFilesExtPredicate];
	unsigned filesCount = [filteredMDFiles count];
	
	if(messagesCount != filesCount) {
		NSLog(@"synchronizing metadata cache files...");
		[[self managedObjectContext] saveWithMetadata:nil allItems:YES];
	} else {
		//NSLog(@"metadata cache is up to date");
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//NSLog(@"-- applicationDidFinishLaunching");
	[self installOrUpdateTools];
	[self synchronizeMetadataFiles];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	
	if (object == self && [keyPath isEqualToString:@"smsSender"]) {
		
		
		[[NSUserDefaults standardUserDefaults] setValue:[smsSender className] forKey:@"SMSService"];
		
		[self willChangeValueForKey:@"messageInfo"];
		[self didChangeValueForKey:@"messageInfo"];
		
		[abPersonController rearrangeObjects];
		
		// TODO remove recipients with non conform mobile phones
		
		//NSString *serviceName = [[NSUserDefaults standardUserDefaults] valueForKey:@"SMSService"];
		//NSLog(@"SMSService serviceName: %@, %d people", serviceName, [[abPersonController arrangedObjects] count]);
    }
	
	if(object == self && [keyPath isEqualToString:@"recipients"]) {
		if([recipients count] > 0) {
			NSObject<SSRecipientProtocol> *r = [recipients objectAtIndex:0];
			if(![r isKindOfClass:[NSString class]]) {
				[self setValue:r forKey:@"firstRecipient"]; // 1
			}
			
		} else if(recipients == nil || [recipients count] == 0) {
			[self setValue:nil forKey:@"firstRecipient"];
		}
	}
}

- (NSDictionary *)keychainLoginAndPasswordForSender:(AbstractSender *)sender {
	
	if(sender == nil) { return nil; }
	
	if([sender needsLoginAndPassword] == NO) {
		return [NSDictionary dictionaryWithObjectsAndKeys:@"", @"login", @"", @"password", nil]; // TODO check what value we have to return
	}
	
	SecKeychainItemRef keychainItem;
	BOOL notFound;
	
    NSString *login = @"";
	NSString *password = @"";
	
	password = [KeychainAccess internetHTMLFormPasswordForServer:[sender serviceServerName] protocol:[sender serviceProtocol] keychainItem:&keychainItem notFound:&notFound];
	
	if(!password && !notFound) {
		return nil;
	}
	
	NSString *serverName = [sender serviceServerName];
	
	if(notFound) {
		// No keychain item was found for this service, prompt for login/password
		if (!window) {
			// We do not prompt for login/password when run from automator, we just fail with a keychain error
			return nil;
		}
		
		[instructionField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Please enter your user name and password for \"%@\" (%@)", nil), [sender name], serverName]];
		[loginField setStringValue:@""];
		[passwordField setStringValue:@""];
		
		MPCreateSemaphore(1, 0, &loginSemaphore);
		[NSApp beginSheet:loginPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(loginSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		[loginPanel makeKeyAndOrderFront:self];
		// I can't believe we have to use a semaphore because [NSApp runModalForWindow:loginPanel relativeToWindow:window] is deprecated!
		MPWaitOnSemaphore(loginSemaphore, kDurationForever);
		MPDeleteSemaphore(loginSemaphore);
		
		if (userCancelledLogin) {
			// What kind of error is a cancellation ? login error or keychain error ?
			// [NSDictionary dictionaryWithObjectsAndKeys:login, @"login", password, @"password", nil] -> login error
			// nil -> keychain error
			
			return [NSDictionary dictionaryWithObjectsAndKeys:login, @"login", password, @"password", nil];
		}
		
		login = [loginField stringValue];
		password = [passwordField stringValue];
		
		if ([rememberCheckbox state] == NSOnState) {
			[KeychainAccess addInternetHTMLFormPasswordForServer:serverName login:login password:password protocol:[sender serviceProtocol]];
		}
	} else {
		login = [KeychainAccess loginForItem:keychainItem];
	}
	
    return [NSDictionary dictionaryWithObjectsAndKeys:login, @"login", password, @"password", nil];
}

- (IBAction)endLoginSheet:(id)sender {
	[loginPanel orderOut:sender];
	[NSApp endSheet:loginPanel returnCode:[[sender alternateTitle] isEqualToString:@"ok"] ? NSOKButton : NSCancelButton];
}

- (void)loginSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	userCancelledLogin = (returnCode != NSOKButton);
	MPSignalSemaphore(loginSemaphore);
}

- (void)isSendingChanged:(NSNumber *)number {
    [self setValue:number forKey:@"isSending"];
}

- (void)updateTokenField:(NSArray *)remaingRecipients {
	if(recipients && [recipients count] > 0) {
		[self setValue:remaingRecipients forKey:@"recipients"];
		[tokenField setObjectValue:remaingRecipients]; // bindings aren't enough: http://developer.apple.com/releasenotes/Cocoa/AppKit.html
	}	
}

- (void)createAndAddMessageAndSaveWithDictionary:(NSDictionary *)d {
    
	Message *message = [Message messageWithText:[d valueForKey:@"text"]
	                                       name:[d valueForKey:@"name"]
										  phone:[smsSender normalizePhoneNumber:[d valueForKey:@"phone"]]
				                        context:[self managedObjectContext]];
    
    [messagesController addObject:message];
    [messagesController rearrangeObjects];
    [[self managedObjectContext] saveWithMetadata:nil];
}

- (SwissSMSSendingStatus)sendMessage:(NSString *)message toIndividualRecipient:(id <SSRecipientProtocol>)theRecipient {
	NSAssert(theRecipient != nil, @"theRecipient is nil");
	NSAssert(message != nil, @"message is nil");
	
	//NSLog(@"%@ - %@", theRecipient, message);
	
	NSString *name = [theRecipient name];
	NSString *phone = [theRecipient phone];
	
	// this dictionary ensures we don't store another message or recipient if they change while sending
	NSDictionary *messageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:message, @"text",
									   name, @"name",
									   phone, @"phone", nil];
	
	[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"login" waitUntilDone:YES];
	
	NSDictionary *d = [self keychainLoginAndPasswordForSender:smsSender];
	//NSLog(@"keychain -> %@", d);
	if (!d) {
		[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"keychainError" waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		return SS_KEYCHAIN_ERROR;
	}
	
	SwissSMSSendingStatus loginStatus = [smsSender login:[d valueForKey:@"login"]
												password:[d valueForKey:@"password"]];
	
	if(loginStatus == SS_SERVICE_UNAVAILABLE_ERROR) {
		[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"serviceUnavailableError" waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		return loginStatus;
	}
	
	if(loginStatus != SS_LOGIN_OK) {
		[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"loginError" waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		return loginStatus;
	}
	
	[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"sending" waitUntilDone:YES];
	
	SwissSMSSendingStatus sendingStatus = [smsSender sendMessage:[messageDictionary valueForKey:@"text"]
														toNumber:[messageDictionary valueForKey:@"phone"]];
	
	if(sendingStatus != SS_SENDING_OK) {
		if (sendingStatus == SS_PLUGIN_INTERNAL_ERROR) {
			[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"pluginInternalError" waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		} else if (sendingStatus == SS_NO_INTERNET_ERROR) {
			[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"networkError" waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		} else if (sendingStatus == SS_QUOTA_EXCEEDED) {
			[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"noMoreCreditsError" waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		} else {
			[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"sendingError" waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		}
		return sendingStatus;
	}
	
	[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"sent" waitUntilDone:YES];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	[self performSelectorOnMainThread:@selector(createAndAddMessageAndSaveWithDictionary:) withObject:messageDictionary waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(isSendingChanged:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
	return SS_SENDING_OK;
}

- (SwissSMSSendingStatus)sendMessageInNewThread:(id)sender {
    // TODO manage more errors
	
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
	NSString *messageText = [messageFieldString copy];
	id <SSRecipientProtocol> theRecipient;
	
	NSMutableArray *remainingRecipients = [[recipients mutableCopy] autorelease];
	
	while([recipients count] > 0) {
		NSAssert(messageText != nil, @"messageText is nil");
		
		theRecipient = [recipients objectAtIndex:0];
		
		//NSLog(@"%@ - %@", theRecipient, messageText);
		SwissSMSSendingStatus status = [self sendMessage:messageText toIndividualRecipient:theRecipient];
		if(status != SS_SENDING_OK) {
			[autoreleasepool release];
			return status;
		}
		
		[remainingRecipients removeObjectAtIndex:0];
		[self performSelectorOnMainThread:@selector(updateTokenField:) withObject:remainingRecipients waitUntilDone:YES];
		
		// TODO use a plugin specific delay?
		//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
	}
	
	[self performSelectorOnMainThread:@selector(statusDidChange:) withObject:@"cleanupUI" waitUntilDone:YES];
	[messageText release];
	[autoreleasepool release];
	return SS_SENDING_OK;
}

- (IBAction)openCurrentRecipientInAB:sender {
    if(firstRecipient == nil) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"addressbook://%@", [firstRecipient valueForKey:kABUIDProperty]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (BOOL)canSendMessage {
    return (recipients != nil) && ([recipients count] > 0) && !isSending && messageFieldString != nil && ![messageFieldString isEqualToString:@""];
}

- (IBAction)sendMessage:sender {
    NSAssert([[self valueForKey:@"canSendMessage"] boolValue] == YES, @"canSendMessage == NO");
    
    [NSThread detachNewThreadSelector:@selector(sendMessageInNewThread:) toTarget:self withObject:nil];	
}

- (IBAction)openPreferences:(id)sender {
	[[PreferencesController sharedPreferencesController] showWindow:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

- (NSString *)metadataDirectoryPath {
	
//	NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0]; // FIXME: content not found by Spotlight..
	NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *mdDirectory = [[documents stringByAppendingPathComponent:@"SwissSMS"] stringByAppendingPathComponent:@"Metadata"];
	return mdDirectory;
}

- (NSString *)metadataFileExtension {
	return @"swisssms";
}

// TODO implement removedSelectionAndSave in a subclass of NSArrayController
// TODO investigate; it shouldn't be necessary
- (IBAction)removeSelectedMessages:sender {
    NSArray *selectedObjects = [messagesController selectedObjects];
    NSEnumerator *e = [selectedObjects objectEnumerator];
    Message *m;
    while((m = [e nextObject])) {
        [messagesController removeObject:m];
    }
		
    [[self managedObjectContext] saveWithMetadata:nil];
}

- (IBAction)saveAndClosePrefsWindow:sender {
    [defaultsController save:nil];
    [prefsWindow close];
}

- (void)openMessageInspector {
	// hack to avoid unexplained call from bindings during awakeFromNib
	// TODO: check if problem still present
	if(isWaking) {
		return;
	}
    [messageInspector makeKeyAndOrderFront:self];
}

- (void)closeMessageInspector {
    [messageInspector orderOut:self];
}

- (IBAction)openImForSelectedMessageGuessedPerson:(id)sender {
    if([[messagesController selectedObjects] count] != 1) {
        return;
    }
    
    ABPerson *p = [[[messagesController selectedObjects] lastObject] guessedPerson];
	
	if(p == nil || [[p aimStatus] intValue] == 1) {
        return;
    }
	
    [[NSWorkspace sharedWorkspace] openIMClientForScreenName:[p aimScreenName] message:nil];
}

- (IBAction)toggleFlagOnSelectedMessages:(id)sender {
	[[messagesController selectedObjects] makeObjectsPerformSelector:@selector(toggleFlag)];
}

- (IBAction)customize:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (IBAction)showhide:(id)sender {
    [toolbar setVisible:![toolbar isVisible]];
}

- (IBAction)openImForCurrentRecipient:(id)sender {
    if(firstRecipient == nil || [[firstRecipient aimStatus] intValue] == 1) {
        return;
    }
    [[NSWorkspace sharedWorkspace] openIMClientForScreenName:[firstRecipient aimScreenName] message:messageFieldString];
}

- (IBAction)sendFeedback:(id)sender {
    NSString *email = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"FeedbackEmail"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", email]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
	if ((aTextView == messageField) && ([[NSApp currentEvent] keyCode] == 76)) {
		// The numeric keypad enter key (⌅) was pressed, send the sms
		[sendButton performClick:self];
		return YES;
	}
	return NO;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	//NSLog(@"application opens file %@", filename);
	
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:filename];
	if(!d) return NO;
	
	NSString *objectIDString = [d objectForKey:@"objectID"];
	if(!objectIDString) return NO;
	
	NSURL *url = [NSURL URLWithString:objectIDString];
	if(!url) return NO;
	
	NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
	if(!objectID) return NO;
	
	Message *m = (Message *)[[self managedObjectContext] objectWithID:objectID];	
	if(!m) return NO;
		
	[messagesController setSelectedObjects:[NSArray arrayWithObject:m]];
	[messageInspector makeKeyAndOrderFront:self];
		
	return YES;
}

@end

