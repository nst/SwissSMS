//
//  NSWorkspace_SwissSMS.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 03.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "NSWorkspace_SwissSMS.h"


@implementation NSWorkspace (SwissSMS)

// from http://www.cocoadev.com/index.pl?QuitApplicationUsingAppleEvent
- (OSStatus) quitApplicationWithBundleID:(NSString*)bundleID {
	OSStatus result = noErr;
	AEAddressDesc target = {};
    AEInitializeDesc(&target);
    
	const char *bundleIDString = [bundleID UTF8String];
    
	result = AECreateDesc( typeApplicationBundleID, bundleIDString, strlen(bundleIDString), &target );
	if ( result == noErr ) {
		AppleEvent	event = {};
		AEInitializeDesc(&event);
        
		result = AECreateAppleEvent( kCoreEventClass, kAEQuitApplication, &target, kAutoGenerateReturnID, kAnyTransactionID, &event );
        
		if ( result == noErr ) {
			AppleEvent	reply = {};
            AEInitializeDesc(&reply);
			result = AESendMessage( &event, &reply, kAENoReply, 60 );
			AEDisposeDesc( &event );
		}
		AEDisposeDesc( &target );
	}
	return( result );
}

- (BOOL)appIsRunning:(NSString *)appName {
   return [[[[NSWorkspace sharedWorkspace] runningApplications] valueForKey:@"localizedName"] containsObject:appName];
}

- (void)openIMClientForScreenName:(NSString *)screenName message:(NSString *)message {
	if(screenName == nil || [screenName isEqualToString:@""]) {
		return;
	}
	
    NSMutableString *aimFormattedMessage = message ? [[message mutableCopy] autorelease] : [NSMutableString stringWithString:@""];
    [aimFormattedMessage replaceOccurrencesOfString:@" "
                                         withString:@"+"
                                            options:(unsigned)NULL
                                              range:NSMakeRange(0, [aimFormattedMessage length])];

    //aim:goim?screenname=abcdef&message=Hi.+Are+you+there?
    NSString *urlString = [NSString stringWithFormat:@"aim:goim?screenname=%@&message=%@", screenName, aimFormattedMessage];
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
