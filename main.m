//
//  main.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 07.04.07.
//  Copyright Nicolas Seriot 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SwissSMS_AppDelegate.h"
#import "ABPerson_SwissSMS.h"
#import "NSString_SwissSMS.h"

//#import "fixXQuery.h"

int main(int argc, char *argv[])
{
	//fixXQuery(NULL);
	
//    NSLog(@"------ %d", argc);
//    NSLog(@"------ %s", argv[1]);
//    NSLog(@"------ %s", argv[2]);
//    NSLog(@"------ %s", argv[3]);
    
    BOOL isLaunchedFromCommandLine = argc >= 4 && (strncmp(argv[1], "-psn", 4)); // FIXME: find the right condition
    
	if (isLaunchedFromCommandLine) {
		SwissSMSSendingStatus status;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
		SwissSMS_AppDelegate *delegate = [[SwissSMS_AppDelegate alloc] init];
		
		NSString *recipient = [d valueForKey:@"firstRecipient"];
		NSString *service   = [d valueForKey:@"service"];
		NSString *login     = [d valueForKey:@"login"];
		NSString *password  = [d valueForKey:@"password"];
		
		if(!recipient) { recipient = [d valueForKey:@"r"]; }
		if(!service)   { service   = [d valueForKey:@"s"]; }
		if(!login)     { login     = [d valueForKey:@"l"]; }
		if(!password)  { password  = [d valueForKey:@"p"]; }
		
		[delegate searchForPlugins];
		[delegate setServiceOrDefaultServiceIfEmpty];
		
		if(!recipient && !service && !login && !password) {
			printf("usage: ./SwissSMS -s serviceName -r 0791234567 -l myLogin -p myPassword < message.txt\n");
			printf("available services: %s\n", [[[delegate availableServicesNames] componentsJoinedByString:@", "] UTF8String]);
			[delegate release];
			[pool release];
			return SS_CLI_ERROR;
		}
		
		if(!recipient) {
			printf("*** error: no recipient\n");
			[delegate release];
			[pool release];
			return SS_CLI_ERROR;
		}
				
		AbstractSender *sender = [delegate senderWithClassName:service];
		if(!sender) {
			sender = [delegate valueForKey:@"smsSender"];
		}
		
		if(!sender) {
			printf("*** error: service unknown\n");
			[delegate release];
			[pool release];
			return SS_SERVICE_UNAVAILABLE_ERROR;
		}
		
		id <SSRecipientProtocol> ssRecipient = [SSRecipient findRecipientFromObject:recipient sender:sender];
		
		NSString *phone = nil;
		if([(NSObject *)ssRecipient isKindOfClass:[ABPerson class]]) {
			phone = [sender normalizePhoneNumber:[(ABPerson *)ssRecipient mobilePhoneNumber]];
		} else {
			phone = [sender normalizePhoneNumber:[ssRecipient phone]];
		}
		
		if(!phone) {
			NSLog(@"*** error: invalid recipient %@", recipient);
			[delegate release];
			[pool release];
			return SS_ADDRESS_BOOK_ERROR;
		}
		
		if(!login || !password) {
			NSDictionary *lp = [delegate keychainLoginAndPasswordForSender:sender];
			if (!lp) {
				printf("*** error: cannot access keychain parameters\n");
				[delegate release];
				[pool release];
				return SS_KEYCHAIN_ERROR;
			}
			
			login    = [lp valueForKey:@"login"];
			password = [lp valueForKey:@"password"];
		}

		printf("reading message on stdin... (end with ^D)\n");
		NSString *message = [[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		if (!message) {
			printf("%s\n", [NSLocalizedString(@"Error: the message must be valid UTF-8", @"CLI invalid message") UTF8String]);
			[delegate release];
			[pool release];
			return SS_MESSAGE_ENCODING_ERROR;
		}
		
		printf("login...\n");
		SwissSMSSendingStatus loginStatus = [sender login:login password:password];
		
		if(loginStatus != SS_LOGIN_OK) {
			printf("Error, connot login\n");
			[message release];
			[delegate release];
			[pool release];	
			return loginStatus;
		}

		printf("sending...\n");
		status = [sender sendMessage:message toNumber:phone];

		if(status != SS_SENDING_OK && status != SS_QUOTA_EXCEEDED) {
			printf("*** error: sending failed\n");
			[delegate release];
			[message release];
			[pool release];
			return status;
		}

		printf("message sent successfully!\n");

		[message release];
		[delegate release];
		[pool release];
		
		return status == SS_QUOTA_EXCEEDED ? SS_SENDING_OK : status;
	} else {
		return NSApplicationMain(argc, (const char **) argv);
	}
}
