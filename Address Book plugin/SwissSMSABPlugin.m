//
//  SwissSMSABPlugin.m
//  SwissSMSABPlugin
//
//  Created by Cédric Luthi on 18.11.07.
//  Copyright Cédric Luthi 2007. All rights reserved.
//

#import "SwissSMSABPlugin.h"
#import "ABPerson_SwissSMS.h"
#import "NSWorkspace_SwissSMS.h"

@implementation SwissSMSABPlugin

- (NSString *)actionProperty
{
	/* Unfortuantely, kABPhoneMobileLabel does not work as one would expect, i.e. enable
	   the contextual menu only on the mobile phone number */
	return kABPhoneProperty;
}

- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
	return NSLocalizedStringFromTableInBundle(@"Send SMS", nil, [NSBundle bundleForClass:[self class]], "Send SMS Address Book contextual menu");
}

- (void)addPerson:(ABPerson *)person
{
	NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
	
	[dnc postNotificationName:@"ch.seriot.SwissSMS.addPersonWithId"
					   object:[person uniqueId]
					 userInfo:nil
		   deliverImmediately:NO];	
}

- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
	if([[NSWorkspace sharedWorkspace] appIsRunning:@"SwissSMS"] == NO) {
		// See comment on applicationDidLaunch: below
		// [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:person];
		// For now we poll every half second
		[[NSWorkspace sharedWorkspace] launchApplication:@"SwissSMS"];
		while ([[NSWorkspace sharedWorkspace] appIsRunning:@"SwissSMS"] == NO) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
	}
	[self addPerson:person];
}

/* The right way is to use this callback, but unfortunately, applicationDidLaunch: is not called
   I have no idea why and I have no idea how to debug a notification that is not sent (or received)
- (void) applicationDidLaunch:(NSNotification *)notification
{
	NSLog(@"applicationDidLaunch: %@", notification);
	if ([[notification valueForKey:@"NSApplicationName"] isEqualToString:@"SwissSMS"]) {
		[self addPerson:[notification object]];
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	}
}
*/

- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
	return [person mobilePhoneNumber] != nil;
}

@end
