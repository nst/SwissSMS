//
//  SSRecipient.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 12.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSRecipient.h"
#import "ABPerson_SwissSMS.h"
#import "NSString_SwissSMS.h"
#import "AbstractSender.h"

@implementation SSRecipient

+(id <SSRecipientProtocol>) findRecipientFromObject:(id)o sender:(AbstractSender *)sender {
	NSObject <SSRecipientProtocol> *p;
	
	if([o isKindOfClass:[ABPerson class]]) {
		return o;
	} else if ([o isKindOfClass:[NSString class]]) {
		p = [ABPerson personFromUniqueId:o];                             if(p) { return p; }
		p = [ABPerson personFromFullname:o mobilePhone:o sender:sender]; if(p) { return p; }
		p = [sender normalizePhoneNumber:o];                             if(p) { return p; }
	}
	
	return nil;
}

+(id <SSRecipientProtocol>) findRecipientFromObject:(id)o {
	AbstractSender *sender = [[NSApp delegate] valueForKey:@"smsSender"];
	return [SSRecipient findRecipientFromObject:o sender:sender];
}


@end
