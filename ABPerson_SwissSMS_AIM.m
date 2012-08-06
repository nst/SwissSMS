//
//  ABPerson_SwissSMS.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 02.10.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "ABPerson_SwissSMS_AIM.h"
#import "NSString_SwissSMS.h"
#import "IMService_TigerCompat.h"

#import <AddressBook/AddressBook.h>
#import <InstantMessage/IMService.h>

#ifndef NSAppKitVersionNumber10_4
   #define NSAppKitVersionNumber10_4 824
#endif

@implementation ABPerson (SwissSMS_AIM)

- (void)dealloc {
    [super dealloc];
}

- (NSString *)aimScreenName {
    IMService *aim = [IMService serviceWithName:@"AIM"];
    if(aim == nil) {
		return nil;
	}

    NSArray *screenNames = [aim screenNamesForPerson:self];
    NSNumber *status = [NSNumber numberWithInt:0];
    NSEnumerator *e = [screenNames objectEnumerator];
    NSString *sn;
    NSString *screenNameWithBestStatus = nil;
    NSNumber *tempStatus;
    while((sn = [e nextObject])) {
        tempStatus = [[aim infoForScreenName:sn] valueForKey:IMPersonStatusKey];
        if(tempStatus != nil && [tempStatus intValue] > [status intValue]) {
            status = tempStatus;
            screenNameWithBestStatus = sn;
        }
    }
    
    return screenNameWithBestStatus ? screenNameWithBestStatus : nil;
}

- (NSNumber *)aimStatus {
    IMService *aim = [IMService serviceWithName:@"AIM"];
	if(aim == nil) {
		return nil;
	}
    
    NSString *screenName = [self aimScreenName];
    
    if(screenName == nil) {
        return nil;
    }
    
    return [[aim infoForScreenName:screenName] valueForKey:IMPersonStatusKey];
}

- (NSImage *)imageDataForCurrentIMStatus {
    int aimStatus = [[self aimStatus] intValue];
	
	if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
		return [[[NSImage alloc] initWithContentsOfURL:[IMService imageURLForStatus:aimStatus]] autorelease]; // 10.4
	} else {
		return [NSImage imageNamed:[IMService imageNameForStatus:aimStatus]]; // 10.5
	}
}

@end
