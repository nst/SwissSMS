//
//  SMSSwisscomSender.m
//  SMSSwisscomSender
//
//  Created by Nicolas Seriot on 27.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//


#import "SwisscomXtraZoneCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation SwisscomXtraZoneCH

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
    if(login == nil || [login isEqualToString:@"SS_LOGIN_ERROR"] || password == nil || [password isEqualToString:@"SS_LOGIN_ERROR"]) {
        return SS_LOGIN_ERROR;
    }

    NSString *urlLoginContent = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://www.swisscom-mobile.ch/youth/sms_senden-fr.aspx?login"]];
    
	if(!urlLoginContent) {
		return SS_LOGIN_ERROR;
	}
    
    if([urlLoginContent rangeOfString:@"Login region content"].location == NSNotFound) {
        return SS_LOGIN_OK;
    }
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:8];
	[postDictionary setValue:login                          forKey:@"isiwebuserid"];
	[postDictionary setValue:password                       forKey:@"isiwebpasswd"];
    [postDictionary setValue:@"/selfreg/images/button_weiter_fr.gif" forKey:@"login"];
	[postDictionary setValue:@"No"                          forKey:@"isiwebjavascript"];
	[postDictionary setValue:@"mobile"                      forKey:@"isiwebappid"];
	[postDictionary setValue:@"authenticate"                forKey:@"isiwebmethod"];
	[postDictionary setValue:@"/youth/sms_senden-fr.aspx"   forKey:@"isiweburi"];
	[postDictionary setValue:@"login"                       forKey:@"isiwebargs"];

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://www.swisscom-mobile.ch/youth/sms_senden-fr.aspx?login"]];
    
    [request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    if([urlContent rangeOfString:@"TheAuthForm"].location != NSNotFound) {
        return SS_LOGIN_ERROR;
    }
    
    return SS_LOGIN_OK;
}

- (NSString *)removeDangerousCharactersFromString:(NSString *)dirty {
    NSMutableString *clean = [dirty mutableCopy];
    [clean replaceOccurrencesOfString:@"$" withString:@":" options:0 range:NSMakeRange(0,[clean length])];
    return [clean autorelease];
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    NSAssert(message != nil, @"message is nil");
    NSAssert(number != nil, @"number is nil");
    
    NSString *cleanMessage = [self removeDangerousCharactersFromString:message];

	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:7];
	[postDictionary setValue:cleanMessage forKey:@"CobYouthSMSSenden:txtMessage"];
	[postDictionary setValue:number       forKey:@"CobYouthSMSSenden:txtNewReceiver"];
	[postDictionary setValue:@""     forKey:@"__EVENTTARGET"];
	[postDictionary setValue:@""     forKey:@"__EVENTARGUMENT"];
	[postDictionary setValue:@"18"   forKey:@"__VIEWSTATE_SCM"];
	[postDictionary setValue:@""     forKey:@"__VIEWSTATE"];
	[postDictionary setValue:@"Envoyer" forKey:@"CobYouthSMSSenden:btnSend"];

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://www.swisscom-mobile.ch/youth/sms_senden-fr.aspx"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
    [urlContent writeToFile:@"/Users/nst/Desktop/sent.html"
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:nil];
    
    if([urlContent rangeOfString:@"CobYouthSMSSenden_lblSuccessfully"].location == NSNotFound) {
        return SS_SENDING_ERROR;
    }
    
    return SS_SENDING_OK;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

@end
