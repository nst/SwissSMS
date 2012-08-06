//
//  YalloCH.m
//  SwissSMS
//
//  Created by Andre Anjos, 11.08.2008 
//  Copyright 2008 Andre Anjos. All rights reserved.
//

#import "YalloCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation YalloCH

-(id)init {
	self = [super init];
	mAvailableSMS = -1;
	
	return self;
}


-(int)GetAvailableSMS:(NSString *)smsPageContent {

	if(!smsPageContent) {
    // if we were not executing an action, just call the standard page, that will show us the SMSs left
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		[request setTimeoutInterval:5.0];
		[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [request setURL:[NSURL URLWithString:@"https://www.yallo.ch/kp/dyn/web/pub/home/home.do"]];
		[request setHTTPMethod:@"GET"];
    		
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		smsPageContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
	}
		
	/*
   <div id="sms_counter">
     24 SMS gratuits, 
     <a href="/kp/dyn/web/sec/rf/sms/start.do">50 SMS achetés</a>
   </div>
	*/
	int availableSMS = 0;
	
	@try {
    // [smsPageContent writeToFile:@"/Users/andre/Desktop/YalloCounter.html" atomically:YES encoding:NSISOLatin1StringEncoding error:nil];
    NSRange myRange = [smsPageContent rangeOfString:@"sms_counter"];
		if(myRange.location == NSNotFound) return availableSMS;
    NSString* tmp = @""; //have to pre-allocate!
    myRange.location += myRange.length;
    myRange.length = 32;
    tmp = [smsPageContent substringWithRange:myRange];
    NSRange freeNumberRange = [tmp rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
    tmp = [tmp substringWithRange:NSMakeRange(freeNumberRange.location, 2)];
    int freeSMS = [tmp intValue];
    availableSMS += freeSMS > 0 && freeSMS < 99999? freeSMS: 0;

    myRange = [smsPageContent rangeOfString:@"start.do"];
    if(myRange.location == NSNotFound) return availableSMS;
    myRange.location += myRange.length;
    myRange.length = 16;
    tmp = [smsPageContent substringWithRange:myRange];
    myRange.location = 0;
    NSRange paidNumberRange = [tmp rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
    tmp = [tmp substringWithRange:NSMakeRange(paidNumberRange.location, 2)];
    int paidSMS = [tmp intValue];
    availableSMS += paidSMS > 0 && paidSMS < 99999? paidSMS: 0;
  }
  @catch (NSException *exception) {
    NSLog(@"GetAvailableSMS: Caught %@: %@. Ignoring!", [exception name], [exception  reason]);
  }
	
	return availableSMS;
}

- (NSString *)loginInternal:(NSString *)login password:(NSString *)password {
	if(login == nil || password == nil) {
		return nil;
	}
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:login    forKey:@"j_username"];
	[postDictionary setValue:password forKey:@"j_password"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
  [request setURL:[NSURL URLWithString:@"https://www.yallo.ch/kp/dyn/web/j_security_check.do"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];
  [request setValue:@"https://www.yallo.ch/kp/dyn/web/pub/home/home.do" forHTTPHeaderField:@"Referer"];
	[postDictionary release];
	
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if(error != nil) NSLog(@"Error: %@", error);
	NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
	// [urlContent writeToFile:@"/Users/andre/Desktop/YalloLogin.html" atomically:YES encoding:NSISOLatin1StringEncoding error:nil];
	
	return urlContent;
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	NSString *urlContent = [self loginInternal:login password:password];
	if(urlContent == nil) return SS_LOGIN_ERROR;
	
	if([urlContent rangeOfString:@"acc.sms.SmsSendForm"].location == NSNotFound) { //if we don't get the send form
		return SS_SENDING_ERROR;
	}
	mAvailableSMS = [self GetAvailableSMS:urlContent];
  // NSLog(@"At login, available SMS = %d", mAvailableSMS);
	return SS_LOGIN_OK;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
	NSMutableString *formattedMessage = [message mutableCopy];
	[formattedMessage replaceOccurrencesOfString:@"[" withString:@"(" options:(unsigned)NULL range:NSMakeRange(0,[message length])];
	[formattedMessage replaceOccurrencesOfString:@"]" withString:@")" options:(unsigned)NULL range:NSMakeRange(0,[message length])];
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:number           forKey:@"destination"];
	[postDictionary setValue:formattedMessage forKey:@"message"];
	[postDictionary setValue:@"envoyer" forKey:@"send"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
  [request setURL:[NSURL URLWithString:@"https://www.yallo.ch/kp/dyn/web/sec/acc/sms/sendSms.do"]];
	[request setHTTPMethod:@"POST"];
  [request setValue:@"https://www.yallo.ch/kp/dyn/web/pub/home/home.do" forHTTPHeaderField:@"Referer"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];
	
	[formattedMessage release];
	[postDictionary release];
	
	NSURLResponse *response = nil;
	NSError       *error;
	NSData        *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	NSString      *sendResult = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
	// [sendResult writeToFile:@"/Users/andre/Desktop/YalloSend.html" atomically:YES encoding:NSISOLatin1StringEncoding error:nil];
  
	if([sendResult rangeOfString:@"Ihre Nachricht wurde an die Nummer"].location == NSNotFound &&
	   [sendResult rangeOfString:@"Votre message a"].location == NSNotFound &&
	   [sendResult rangeOfString:@"stato inviato"].location == NSNotFound && 
	   [sendResult rangeOfString:@"mensagem foi enviada"].location == NSNotFound && 
	   [sendResult rangeOfString:@"message was sent"].location == NSNotFound) {
		return SS_SENDING_ERROR;
	}
  
	int newAvailableSMS = [self GetAvailableSMS:sendResult];
  // NSLog(@"After sending, available SMS = %d", mAvailableSMS);
	if(newAvailableSMS <= 0) {
	  return SS_QUOTA_EXCEEDED;
	}
  
	mAvailableSMS = newAvailableSMS;
	return SS_SENDING_OK;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

@end
