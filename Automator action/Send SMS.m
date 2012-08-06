//
//  Send SMS.m
//  Send SMS
//
//  Created by Administrator on 19.09.07.
//  Copyright 2007 Cédric Luthi. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <OSAKit/OSAScript.h>
#import "Send SMS.h"


@implementation Send_SMS

- (void)sendSMS:(NSString *)uniqueId
{
	NSPipe *inputPipe = [NSPipe pipe];
	NSTask *swisssms = [[NSTask alloc] init];
	[swisssms setLaunchPath:swisssms_executable_path];
	
	[swisssms setArguments:[NSArray arrayWithObjects: @"-r", uniqueId, nil]];
	// We don't need the details, the exit code tells what happened
	[swisssms setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
	[swisssms setStandardInput:inputPipe];
	
	@try {
		[swisssms launch];
		[[inputPipe fileHandleForWriting] writeData:[[[self parameters] objectForKey:@"message"] dataUsingEncoding:NSUTF8StringEncoding]];
		[[inputPipe fileHandleForWriting] closeFile];
		[swisssms waitUntilExit];
		int exitCode = [swisssms terminationStatus];
		if (exitCode != 0) {
			@throw [NSException exceptionWithName:@"SwissSMSException" reason:@"SwissSMS failed to send the message"
			                                                         userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exitCode] forKey:@"exitCode"]];
		}

	} @catch (NSException *exception) {
		@throw exception;
	} @finally {
		[swisssms release];
	}
}

- (void)traverse:(NSString *)uniqueId
{
	ABRecord *record = [[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueId];
	if ([record class] == [ABPerson class]) {
		[self sendSMS:uniqueId];
	} else if ([record class] == [ABGroup class]) {
		NSArray *members = [(ABGroup*)record members];
		NSArray *subgroups = [(ABGroup*)record subgroups];
		
		int j,m = [members count];
		// First, iterate on all ABPerson (members)
		for (j = 0; j < m; j++) {
			[self sendSMS:[((ABRecord*)[members objectAtIndex:j]) uniqueId]];
		}
		
		m = [subgroups count];
		// Second, recursively traverse ABGroup (subgroups)
		for (j = 0; j < m; j++) {
			// Address Book.app enforces recursive group prevention, it is thereore safe to recurse
			[self traverse:[((ABRecord*)[subgroups objectAtIndex:j]) uniqueId]];
		}
	} else {
		// Ignore, a record is either ABPerson or ABGroup
	}
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	OSStatus status;
	CFURLRef swisssms_location;
	NSString *swisssms_path;
	
	// Locate SwissSMS
	if ((status = LSFindApplicationForInfo(kLSUnknownCreator, CFSTR("ch.seriot.SwissSMS"), NULL /*CFSTR("SwissSMS")*/, NULL, &swisssms_location))) {
		*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:status], OSAScriptErrorNumber, @"SwissSMS could not be located", OSAScriptErrorMessage, nil];
		return input;
	}
	
	swisssms_path = (NSString *)CFURLCopyFileSystemPath(swisssms_location, kCFURLPOSIXPathStyle);
	CFRelease(swisssms_location);
	
	// bundle path -> executable path
	swisssms_executable_path = [[NSBundle bundleWithPath:swisssms_path] executablePath];
	
	// TODO Read SwissSMS preferences to display (also choose?) the network
	
	if ([input class] == [NSAppleEventDescriptor class]) {
		int i,n = [input numberOfItems];
		for (i = 1; i <= n; i++) {
			NSString *uniqueId = [[[input descriptorAtIndex:i] paramDescriptorForKeyword:keyAEKeyData] stringValue];
			if (uniqueId) {
				@try {
					[self traverse:uniqueId];
				} @catch (NSException *exception) {
					*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:[[exception userInfo] objectForKey:@"exitCode"], OSAScriptErrorNumber, [exception reason], OSAScriptErrorMessage, nil];
					goto abort;
				}
			} else {
				// How could this branch be reached ?
			}
		}
	} else {
		*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:paramErr], OSAScriptErrorNumber, @"invalid input", OSAScriptErrorMessage, nil];
	}
	
	abort:
	// Return the address book items
	return input;
}

@end
