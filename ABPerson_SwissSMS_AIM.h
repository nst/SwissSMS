//
//  ABPerson_SwissSMS.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 02.10.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@interface ABPerson (SwissSMS_AIM)

- (NSNumber *)aimStatus;
- (NSString *)aimScreenName;
- (NSImage *)imageDataForCurrentIMStatus;

@end


