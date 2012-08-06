//
//  SMSPostMailSender.m
//  SwissSMS
//
//  Created by CŽdric Luthi on 27.09.07.
//  Copyright 2007 CŽdric Luthi. All rights reserved.
//

#import "PostMailCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation PostMailCH

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password
{
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    [postDictionary setValue:login forKey:@"userName"];
	[postDictionary setValue:password forKey:@"password"];
	[postDictionary setValue:@"postmail" forKey:@"oemName"];

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://login.postmail.ch/postbox/login.do"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSWindowsCP1252StringEncoding]];
    
    [postDictionary release];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	
	NSLog(@"login response: %@", [(NSHTTPURLResponse*)response allHeaderFields]);
    
    [urlContent writeToFile:@"/Users/cluthi/Desktop/PostMailLogin.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];
	[urlContent release];

	return SS_LOGIN_OK;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)phoneNumber
{
	if(phoneNumber == nil || message == nil || ([phoneNumber length] != 10)) {
		return SS_SENDING_ERROR;
	}
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://postmail.daybyday.de/mail/sms_versch_content.html"]];

	NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];

	NSLog(@"sms response: %@", [(NSHTTPURLResponse*)response allHeaderFields]);
	
    [urlContent writeToFile:@"/Users/cluthi/Desktop/PostMailSMS.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];
	[urlContent release];
	
	return SS_SENDING_ERROR;
}

- (void) dealloc {
	[super dealloc];
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

@end
