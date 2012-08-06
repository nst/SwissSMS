//
//  SMSCoopMobileSender.m
//  SwissSMS
//
//  Created by Cédric Luthi on 24.09.07.
//  Copyright 2007 Cédric Luthi. All rights reserved.
//

#import "CoopMobileCH.h"
#import "NSString+SMSSender.h"
#import "HTMLForm.h"

@implementation CoopMobileCH

- (SwissSMSSendingStatus)login:(NSString *)theLogin password:(NSString *)thePassword
{
	login = [theLogin retain];
	password = [thePassword retain];
	
	if ([login length] != 10)
		return SS_LOGIN_ERROR;
	else
		return SS_LOGIN_OK;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)phoneNumber
{
	NSError *err = nil;
	
	// TODO could one if these really happen ?
	if(phoneNumber == nil || message == nil || ([phoneNumber length] != 10)) {
		return SS_SENDING_ERROR;
	}
	
	HTMLForm *form = [HTMLForm formNamed:@"sms_form" atURL:[NSURL URLWithString:@"http://www2.coop.ch/coopmobile/sms.cfm?language=FR"] error:&err];
	
	if (err) {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			return SS_PLUGIN_INTERNAL_ERROR;
		}
	}
	
	// Characters '[' and ']' as inserted when segmenting messages don't work, so replace them with '(' and ')'
	NSMutableString *mutableMessage = [NSMutableString stringWithString:message];
	[mutableMessage replaceOccurrencesOfString:@"[" withString:@"(" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[message length])];
	[mutableMessage replaceOccurrencesOfString:@"]" withString:@")" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[message length])];
	
	[form setValue:password                                           forField:@"sms_myCode"];
	[form setValue:[login substringWithRange:NSMakeRange(0, 3)]       forField:@"sms_sender_prefix"];
	[form setValue:[login substringWithRange:NSMakeRange(3, 7)]       forField:@"sms_sender_number"];
	[form setValue:[phoneNumber substringWithRange:NSMakeRange(0, 3)] forField:@"sms_recipient_prefix"];
	[form setValue:[phoneNumber substringWithRange:NSMakeRange(3, 7)] forField:@"sms_recipient_number"];
	[form setValue:mutableMessage                                     forField:@"sms_text"];
	[form setValue:@"checkbox"                                        forField:@"accept_agb"];
	
	// What is better ? "//div[@style='color:green;']" or "//text()[matches(.,'Votre SMS a bien été transmis')]"
	BOOL success = [form submitExpectingSuccess:[NSString stringWithUTF8String:"//text()[matches(.,'Votre SMS a bien été transmis')]"]
	                     failures:[NSArray arrayWithObjects:[NSString stringWithUTF8String:"//text()[matches(.,'Veuillez entrer un code valable')]"],                  // 0: Triggered by entering a wrong code
	                                                        [NSString stringWithUTF8String:"//text()[matches(.,'Numéro erroné. Veuillez entrer un numéro valide')]"],  // 1: Trigerred by entering "123" as "sms_sender_number"
	                                                        [NSString stringWithUTF8String:"//text()[matches(.,'Vous avez déjà envoyé 5 SMS gratuits aujourd.hui')]"], // 2: Obvious: quota exceeded
															[NSString stringWithUTF8String:"//text()[matches(.,'Une erreur est survenue lors de l.envoi')]"],          // 3: How to trigger this ?
	                                                        [NSString stringWithUTF8String:"//text()[matches(.,'Veuillez entrer le numéro du destinataire')]"], nil]   // 4: Trigerred by entering "123" as "sms_recipient_number"
	                     error:&err];
	
	if (success) {
		if (err == nil) {
			return SS_SENDING_OK;
		} else {
			if (([err code] == 0) || ([err code] == 1)) {
				return SS_LOGIN_ERROR;
			} else  if ([err code] == 2) {
				return SS_QUOTA_EXCEEDED;
			} else {
				return SS_SENDING_ERROR; // Impossible to reach, 0790000000 is sucessfully sent
			}
		}
	} else {
		if ([[err domain] isEqualToString:NSURLErrorDomain]) {
			return SS_NO_INTERNET_ERROR;
		} else {
			return SS_PLUGIN_INTERNAL_ERROR;
		}
	}
}

- (void) dealloc {
	[login release];
	[password release];
	[super dealloc];
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

@end
