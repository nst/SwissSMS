//
//  ABPerson_SwissSMS.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 08.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "NSString_SwissSMS.h"

#import <AddressBook/AddressBook.h>
#import "AbstractSender.h"

@implementation ABPerson (SwissSMS)

+ (NSArray *)personsWithMobilePhone {
	ABAddressBook *AB = [ABAddressBook sharedAddressBook];
	
	ABSearchElement *haveMobilePhone = [ABPerson searchElementForProperty:kABPhoneProperty
																label:kABPhoneMobileLabel
																  key:nil
																value:nil
														   comparison:kABNotEqual];
														   
	NSArray *persons = [AB recordsMatchingSearchElement:haveMobilePhone];
	
	NSSortDescriptor *sd1 = [[[NSSortDescriptor alloc] initWithKey:@"First" ascending:YES] autorelease];
	NSSortDescriptor *sd2 = [[[NSSortDescriptor alloc] initWithKey:@"Last" ascending:YES] autorelease];
	
	return [persons sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sd1, sd2, nil]];
}

- (void)dealloc {
    [super dealloc];
}

// TODO remove this and use -name
- (NSString *)fullname {
	NSString *first = [self valueForKey:@"First"];
	NSString *last = [self valueForKey:@"Last"];
	
	NSMutableArray *components = [[NSMutableArray alloc] init];
	
	if(first) {
		[components addObject:first];
	}
	
	if(last) {
		[components addObject:last];
	}

	NSString *result = [components componentsJoinedByString:@" "];
	[components release];
	return result;
}

- (NSString *)name {
	return [self fullname];
}

- (NSString *)mobilePhoneNumber {
	NSDictionary *d = [self valueForKey:@"Phone"];
	NSArray *labels = [d valueForKey:@"labels"];
	int mobilePhoneIndex = [labels indexOfObject:kABPhoneMobileLabel];
	if(mobilePhoneIndex == NSNotFound) {
        return nil;
    }
	NSArray *values = [d valueForKey:@"values"];
	return [values objectAtIndex:mobilePhoneIndex];
}

- (NSString *) phone {
	AbstractSender *smsSender = [[NSApp delegate] valueForKey:@"smsSender"];
    NSAssert(smsSender != nil, @"sender is nil :-(");
	NSString *mobilePhoneNumber = [self mobilePhoneNumber];
	return [smsSender normalizePhoneNumber:mobilePhoneNumber];
}

- (NSString *) phoneWithSender:(AbstractSender *)sender {
	NSString *mobilePhoneNumber = [self mobilePhoneNumber];
	return [sender normalizePhoneNumber:mobilePhoneNumber];
}

+ (ABPerson *)personFromFullname:(NSString *)fullName mobilePhone:(NSString *)phone sender:(AbstractSender *)sender {
    NSAssert(sender != nil, @"sender is nil :-(");
	NSEnumerator *e = [[[ABAddressBook sharedAddressBook] people] objectEnumerator];
    ABPerson *p;
	
	while((p = [e nextObject])) {
        if([[p phoneWithSender:sender] isEqualToString:[sender normalizePhoneNumber:phone]] ||
           [[[p fullname] lowercaseString] isEqualToString:[fullName lowercaseString]]) {
            return p;
        }
    }
    return nil;
}

+ (ABPerson *)personFromFullname:(NSString *)fullName mobilePhone:(NSString *)phone {
	AbstractSender *sender = [[NSApp delegate] valueForKey:@"smsSender"];
	return [ABPerson personFromFullname:fullName mobilePhone:phone sender:sender];
}

+ (ABPerson *)personFromUniqueId:(NSString *)uid {
	ABSearchElement* search = [ABPerson searchElementForProperty:kABUIDProperty label:nil key:nil value:uid comparison:kABEqualCaseInsensitive];
	NSArray* matches = [[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:search];
	return [matches count] > 0 ? [matches lastObject] : nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"ABPerson %@", [self fullname]];
}

@end
















