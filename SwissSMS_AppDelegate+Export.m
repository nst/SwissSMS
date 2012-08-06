//
//  SwissSMS_AppDelegate+Export.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 15.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SwissSMS_AppDelegate+Export.h"
#import "Message.h"
#import "NSString_SwissSMS.h"
#import "NSWorkspace_SwissSMS.h"

@implementation SwissSMS_AppDelegate (Export)

- (IBAction)exportToCSV:sender {
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    
    NSEnumerator *e = [[self allMessages] objectEnumerator];
    Message *m;
    while((m = [e nextObject])) {
        [lines addObject:[m csvLine]];
    }
    
    NSString *fileContent = [lines componentsJoinedByString:@"\n"];
    
    NSString *userDesktop = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
    
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setRequiredFileType:@"csv"];
    int runResult = [sp runModalForDirectory:userDesktop file:NSLocalizedString(@"SwissSMS_Messages", nil)];
    
    if (runResult == NSOKButton) {
        NSError *error = nil;
        if (![fileContent writeToURL:[sp URL] atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"-- %@", error);
            NSBeep();
        }
    }
    
    [lines release];
}

- (NSString *)exportStatusTop {
    if(![[NSFileManager defaultManager] fileExistsAtPath:[NSString bluePhoneEliteExportFilePath]]) {
        return NSLocalizedString(@"BluePhoneElite SMS files not found", nil);
    }
    
    return bpeIsRunning ? NSLocalizedString(@"BluePhoneElite is running, export will stop it.", nil) : NSLocalizedString(@"Backup your data!", nil);
}

- (void)exportToBluePhoneEliteInNewThread:(id)object {

    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    [self performSelectorOnMainThread:@selector(setKeyExportToBPEIsAllowed:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
    
    [[NSWorkspace sharedWorkspace] quitApplicationWithBundleID:@"com.reel.BluePhoneElite"];
    
    while([[NSWorkspace sharedWorkspace] appIsRunning:@"BluePhoneElite"]) {
        // TODO use NSWorkspace notification rather than polling
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    }
    
    NSString *bpeDBPath = [NSString bluePhoneEliteExportFilePath];
        
    // load dict
    NSMutableArray *a = [[NSMutableDictionary dictionaryWithContentsOfFile:bpeDBPath] valueForKey:@"Contents"];
    BOOL couldWriteFile;

    NSMutableArray *bpeFormattedMessagesToExport = [[NSMutableArray alloc] init];

    // fill temp array with formatted messages to export	
    NSEnumerator *e = [[self allMessages] objectEnumerator];
    Message *m;
    BOOL removeObjectsAfterExport = [[[NSUserDefaults standardUserDefaults] valueForKey:@"removeMessagesAfterExport"] boolValue];
    while((m = [e nextObject])) {
        [bpeFormattedMessagesToExport addObject:[m bluePhoneEliteFormatAndRemove:removeObjectsAfterExport]];
    }
    
    // merge bpe formatted messages to export with bpe db
    [a addObjectsFromArray:bpeFormattedMessagesToExport];
    [bpeFormattedMessagesToExport release];
    
    // write file
    couldWriteFile = [[NSDictionary dictionaryWithObject:a forKey:@"Contents"] writeToFile:[NSString bluePhoneEliteExportFilePath] atomically:YES];
	
    if(couldWriteFile) {
		if(removeObjectsAfterExport) {
			[[self managedObjectContext] save:nil];
		}
		[self setValue:NSLocalizedString(@"Export done!", nil) forKey:@"exportStatusBottom"];
    } else {
		[[self managedObjectContext] rollback];
        [self setValue:NSLocalizedString(@"Export error :-(", nil) forKey:@"exportStatusBottom"];
    }

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"launchBPEAfterExport"]) {
        [[NSWorkspace sharedWorkspace] launchApplication:@"BluePhoneElite"];
    }
    
    [self performSelectorOnMainThread:@selector(setKeyExportToBPEIsAllowed:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
    
    [autoreleasepool release];
}

- (IBAction)exportToBluePhoneElite:(id)sender {
    [NSThread detachNewThreadSelector:@selector(exportToBluePhoneEliteInNewThread:) toTarget:self withObject:nil];
}

@end
