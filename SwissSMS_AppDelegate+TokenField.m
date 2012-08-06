//
//  SwissSMS_AppDelegate+TokenField.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 08.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SwissSMS_AppDelegate+TokenField.h"
#import "ABPerson_SwissSMS.h"
#import "NSString_SwissSMS.h"
#import "SSRecipient.h"

@implementation SwissSMS_AppDelegate (TokenField)

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
	NSObject<SSRecipientProtocol> *r = [SSRecipient findRecipientFromObject:editingString];
	return r ? r : editingString;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
	return [representedObject name];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index {
    NSPredicate *validPhonesPredicate = [NSPredicate predicateWithFormat: @"phone != NULL"];
    return [tokens filteredArrayUsingPredicate:validPhonesPredicate];
}
/*
- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
	// TODO handle ABPerson instances with several mobile numbers?
	return NO;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
	// TODO handle ABPerson instances with several mobile numbers?
	return nil;
}
*/
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex {		
	BOOL showAllContacts = [substring hasPrefix:@"*"] || [substring hasPrefix:@"?"];
	if(showAllContacts) {
		NSPredicate *peopleWithValidNumber = [NSPredicate predicateWithFormat: @"fullname != NULL"];
		NSArray *validNumberPeople = [[abPersonController arrangedObjects] filteredArrayUsingPredicate:peopleWithValidNumber];
		return [validNumberPeople valueForKey:@"fullname"];
	}
	
    NSPredicate *peopleWithSameBeginningPredicate = [NSPredicate predicateWithFormat: @"fullname beginswith[c] %@", substring];
    NSArray *filteredPeople = [[abPersonController arrangedObjects] filteredArrayUsingPredicate:peopleWithSameBeginningPredicate];
	return [filteredPeople valueForKey:@"fullname"];
}
/*
- (void)controlTextDidChange:(NSNotification *)aNotification {
	NSObject *o = (recipients && [recipients count] > 0) ? [recipients lastObject] : nil;
	if(![o isKindOfClass:[NSString class]]) {
		NSObject<SSRecipientProtocol> *recipient = [SSRecipient findRecipientFromObject:(id)o];
		[self setValue:recipient forKey:@"firstRecipient"]; // 2 // 3
	}
}
*/
@end
