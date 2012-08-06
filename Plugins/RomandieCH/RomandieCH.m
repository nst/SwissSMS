//
//  RomandieCH.m
//  SMSRomandie
//
//  Created by Nicolas Seriot on 08.11.06.
//  Copyright 2006 Nicolas Seriot. All rights reserved.
//

#import "RomandieCH.h"
#import "NSString+SMSSender.h"

@implementation RomandieCH

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	return SS_LOGIN_OK;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)phoneNumber {
	SwissSMSSendingStatus status = SS_SENDING_OK;
	NSError *err = nil;

	NSURL *baseURL = [NSURL URLWithString:@"http://www.romandie.com/Mobile/SMS%5Ftel/"];
	NSString *dateUrlComponent = [baseURL propertyForKey:@"Location"]; // ../SMS_tel150508/
	NSURL *controleURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.romandie.com/Mobile/SMS_tel150508/%@controle.asp", dateUrlComponent]];
	HTMLForm *form = [[HTMLForm alloc] initWithFormNamed:@"sms_input" atURL:controleURL error:&err];
	
	if (err) {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			status = SS_NO_INTERNET_ERROR;
			goto abort;
		} else {
			// No "sms_input" form, assume a redirect to http://www.romandie.com/Mobile/SMS%5Ftel/NotAllow.asp (quota is over)
			status = SS_QUOTA_EXCEEDED;
			goto abort;
		}
	}
	
	NSMutableString *formattedPhoneNumber = [NSMutableString stringWithString:phoneNumber];
	[formattedPhoneNumber replaceOccurrencesOfString:@"0" withString:@"+41" options:nil range:NSMakeRange(0, 4)];
	
	[form setValue:formattedPhoneNumber forField:@"MSISDN"]; // SIGTRAP here
	[form setValue:message forField:@"TXT"];
	
	BOOL success = [form submitExpectingSuccess:[NSString stringWithUTF8String:"//text()[matches(.,'Votre SMS est parti avec succès')]"]
	                     failures:[NSArray arrayWithObject:[NSString stringWithUTF8String:"//text()[matches(.,'Votre message n.a pu être envoyé correctement')]"]] error:&err];
	
	if (success) {
		if (err == nil) {
			status = SS_SENDING_OK;
		} else {
			status = SS_SENDING_ERROR; // Probably wrong phone number
		}
	} else {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			status = SS_NO_INTERNET_ERROR;
		} else {
			status = SS_PLUGIN_INTERNAL_ERROR;
		}
	}
	
	abort:
	[form release];
	return status;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

- (void)dealloc{
	[super dealloc];
}

@end
