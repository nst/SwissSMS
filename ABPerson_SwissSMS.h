//
//  ABPerson_SwissSMS.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 08.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import <SSRecipient.h>

@interface ABPerson (SwissSMS) <SSRecipientProtocol>

+ (NSArray *)personsWithMobilePhone;

- (NSString *)fullname;
- (NSString *)mobilePhoneNumber; // not normalized
- (NSString *)phone; // normalized

// TODO enable use of groups
+ (ABPerson *)personFromFullname:(NSString *)fullName mobilePhone:(NSString *)phone sender:(AbstractSender *)sender;
+ (ABPerson *)personFromFullname:(NSString *)fullName mobilePhone:(NSString *)phone;
+ (ABPerson *)personFromUniqueId:(NSString *)uid;

@end


