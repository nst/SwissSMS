//
//  HispeedCH.m
//  SwissSMS
//
//  Created by Cédric Luthi on 20.10.07.
//  Copyright 2007 Cédric Luthi. All rights reserved.
//

#import "HispeedCH.h"
#import "NSString+SMSSender.h"
#import "HTMLForm.h"

@implementation HispeedCH

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password
{
	NSError *err = nil;
	
	// We must first accept the "TornadoAuth=test" cookie so that we do not get http basic authentication
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSHTTPCookieAcceptPolicy userCookiePolicy = [cookieStorage cookieAcceptPolicy];
	[cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
	
	HTMLForm *loginForm = [HTMLForm formNamed:@"anmeldung" atURL:[NSURL URLWithString:@"https://your.hispeed.ch/fr/apps/messenger/"] error:&err];
	
	if (err) {
		[cookieStorage setCookieAcceptPolicy:userCookiePolicy];
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			// No "anmeldung" form, assume we are already logged thanks to cookies
			return SS_LOGIN_OK;
		}
	}
	
	[loginForm setValue:login forField:@"mail"];
	[loginForm setValue:password forField:@"password"];
	
	BOOL success = [loginForm submitExpectingSuccess:@"//iframe[@name='external_application']"
	                          failures:[NSArray arrayWithObject:@"//input[@class='login']"] error:&err];
	
	[cookieStorage setCookieAcceptPolicy:userCookiePolicy];
	
	if (success) {
		if (err == nil) {
			return SS_LOGIN_OK;
		} else {
			return SS_LOGIN_ERROR;
		}
	} else {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			return SS_PLUGIN_INTERNAL_ERROR;
		}
	}
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)phoneNumber
{
	NSError *err = nil;
	
	HTMLForm *smsForm = [HTMLForm formNamed:@"smsBean" atURL:[NSURL URLWithString:@"https://your.hispeed.ch/glue.cgi?http://messenger.hispeed.ch/walrus/app/login.do?language=fr"] error:&err];
	
	if (err) {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			return SS_PLUGIN_INTERNAL_ERROR;
		}
	}
	
	[smsForm setValue:message                                             forField:@"message"];
	[smsForm setValue:[NSString stringWithFormat:@"%d", [message length]] forField:@"numCount"];
	[smsForm setValue:@"originatorUser"                                   forField:@"originator"];
	[smsForm setValue:@"yes"                                              forField:@"recipientChecked"];
	[smsForm setValue:phoneNumber                                         forField:@"recipient"];
	[smsForm removeField:@"sendDate"];
	[smsForm removeField:@"sendTime"];
	
	BOOL success = [smsForm submitExpectingSuccess:[NSString stringWithUTF8String:"//text()[matches(.,'SMS-Messenger a accepté votre ordre d.envoi')]"]
	                        failures:[NSArray array] error:&err];
	
	if (success) {
		if (err == nil) {
			return SS_SENDING_OK;
		} else {
			return SS_SENDING_ERROR;
		}
	} else {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			return SS_PLUGIN_INTERNAL_ERROR;
		}
	}
}

- (NSString *)normalizePhoneNumber:(NSString *)rawString
{
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

@end
