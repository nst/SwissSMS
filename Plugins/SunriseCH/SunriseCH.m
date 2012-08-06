//
//  SMSSunriseSender.h
//  SwissSMS
//
//  Created by Christian Rueegg on 30.04.07.
//  Copyright 2007-2009 Christian Rueegg. All rights reserved.
//

#import "SunriseCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation SunriseCH

-(id)init {
	self = [super init];
	mAvailableSMS = -1;
	mCookie = nil;
	
	return self;
}


- (void)dealloc {
	[mCookie release];
	[super dealloc];
}



- (NSString*)getTmpPath:(NSString*)fileName {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y%m%d %H.%M.%S.%F" allowNaturalLanguage:NO] autorelease];
	[dateFormatter setDateFormat:@"yyyyMMdd HH.mm.ss.SSS"];
	NSDate *date = [NSDate date];
	return [NSString stringWithFormat:@"./%@ %@", [dateFormatter stringFromDate:date], fileName];
}


-(NSString *)GetSMSPage {
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"http://mip.sunrise.ch/mip/dyn/sms/sms?.lang=de"]];
	[request setHTTPMethod:@"GET"];
	[request setValue:[NSString stringWithFormat:@"SMIP=%@;", mCookie] forHTTPHeaderField:@"Cookie"];
	[request setValue:@"SwissSMS/1.3" forHTTPHeaderField:@"User-Agent"];

	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	NSString *smsPageContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
//[smsPageContent writeToFile:[self getTmpPath:@"SunriseAvailable.html"] atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];

	return smsPageContent;
}


-(int)GetAvailableSMS:(NSString *)smsPageContent {
	if(!smsPageContent) {
		smsPageContent = [self GetSMSPage];
	}
	
	/* HTML response looks like this:
	<!-- SMS counters -->
	 <tr>
	 <td>
	 Gratis 100<br/>     --Fr   Gratuits 100<br/>    -- It   Gratis 96<br/>
	 Bezahlt 0                  Pay&#233;(s) 0               Pagati 0
	 </td> */

	int availableSMS = 0;
	@try {
		NSRange smsRange = [smsPageContent rangeOfString:@"<!-- SMS counters -->"];
		if(smsRange.location == NSNotFound) return availableSMS;
		NSRange smsRangeEnd = NSMakeRange(smsRange.location + smsRange.length, 256);  // number of SMS should follow after this

		NSRange freeRange = [smsPageContent rangeOfString:@"Gratis " options:NSCaseInsensitiveSearch range:smsRangeEnd];
		if(freeRange.location == NSNotFound) {
			freeRange = [smsPageContent rangeOfString:@"Gratuits " options:NSCaseInsensitiveSearch range:smsRangeEnd];
		}
		if(freeRange.location != NSNotFound) {
			freeRange.location += freeRange.length;
			freeRange.length = 6;  // max 5 digits
			NSRange freeNumberRange = [smsPageContent rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]
									options:NSCaseInsensitiveSearch
									range:freeRange];
			NSString *freeNumberString = [smsPageContent substringWithRange:NSMakeRange(freeRange.location, freeNumberRange.location - freeRange.location)];
			int freeSMS = [freeNumberString intValue];
			availableSMS += freeSMS > 0 && freeSMS < 99999? freeSMS: 0;
		}
		
		NSRange paidRange = [smsPageContent rangeOfString:@"Bezahlt " options:NSCaseInsensitiveSearch range:smsRangeEnd];
		if(paidRange.location == NSNotFound) {
			paidRange = [smsPageContent rangeOfString:@"Pay&#233;(s) " options:NSCaseInsensitiveSearch range:smsRangeEnd];
			if(paidRange.location == NSNotFound) {
				paidRange = [smsPageContent rangeOfString:@"Pagati " options:NSCaseInsensitiveSearch range:smsRangeEnd];
			}
		}
		if(paidRange.location != NSNotFound) {
			paidRange.location += paidRange.length;
			paidRange.length = 6;  // max 5 digits
			NSRange paidNumberRange = [smsPageContent rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]
									options:NSCaseInsensitiveSearch
									range:paidRange];
			NSString *paidNumberString = [smsPageContent substringWithRange:NSMakeRange(paidRange.location, paidNumberRange.location - paidRange.location)];
			int paidSMS = [paidNumberString intValue];
			availableSMS += paidSMS > 0 && paidSMS < 99999? paidSMS: 0;
		}
		
	} @catch (...) {
	}
	
	return availableSMS;
}


+ (NSString *)cookieFromHTTPResponse:(NSHTTPURLResponse *)response
{
	NSString *contentType = [[response allHeaderFields] objectForKey:@"Set-Cookie"];
	NSArray *parameters = [contentType componentsSeparatedByString:@"; "];
	unsigned count = [parameters count];
	for(int i = 0; i < count; i++) {
		NSString *parameter = [parameters objectAtIndex:i];
    NSRange sessionNameRange = [parameter rangeOfString:@"SMIP="];
    if (sessionNameRange.location != NSNotFound) {
      int sessionLocation = sessionNameRange.location + 5;
      NSRange parameterEndRange = NSMakeRange(sessionLocation, [parameter length] - sessionLocation);
      NSRange sessionEndRange = [parameter rangeOfString:@";" options:NSCaseInsensitiveSearch range:parameterEndRange];

      int sessionEndDelimiter = sessionEndRange.location=NSNotFound? [parameter length]:sessionEndRange.location;
      NSRange sessionRange = NSMakeRange(sessionLocation, sessionEndDelimiter-sessionLocation);
      return [parameter substringWithRange:sessionRange];
    }
  }

	return nil;
}


- (NSString *)getLoginPage:(NSString *)login password:(NSString *)password {
	if(login == nil || password == nil) {
		return nil;
	}

	[mCookie release];  // release old cookie
	mCookie = NULL;
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:login    forKey:@"username"];
	[postDictionary setValue:password forKey:@"password"];

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"http://mip.sunrise.ch/mip/dyn/login/login?SAMLRequest=fVLJTsMwEL0j8Q%2BW79nKIrCaVAWEqMQStYEDN9eZNAbHNh6nhb%2FHTVkPcPTM81tmZjx57RRZg0NpdE6zOKUEtDC11Kuc3leX0QmdFPt7Y%2BSdsmza%2B1bP4aUH9CT81MiGRk57p5nhKJFp3gEyL9hienPNRnHKrDPeCKMomV3ktLXKLBsluZBPq9pasMunpXzummdoZMttaDdt02pKHj5tjba2Zog9zDR6rn0opelplB5FaVZlx%2BzghGWHj5SUH0pnUu8S%2FGdruQMhu6qqMirvFtVAsJY1uNuAzunKmJWCWJhuK19yRLkOZe96oGSKCM4Hf%2BdGY9%2BBW4BbSwH38%2BsQ0nuLLEk2m038zZLwBHvtJIZXm3CBtBgGy4Zs7sdE%2F3fOP6Vp8U0%2BTn5QFR8L2%2BaYXZRGSfFGpkqZzbkD7r9CXBrXcf%2B3WhZnQ0XWUTNAWa%2FRgpCNhJqSpNip%2Fr6McC%2Fv"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];
	[request setValue:@"SwissSMS/1.3" forHTTPHeaderField:@"User-Agent"];

	[postDictionary release];
	
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
  
	mCookie = [SunriseCH cookieFromHTTPResponse: response];
	[mCookie retain];

	if(mCookie == nil) NSLog(@"Login Error: No sessionkey detected");
	if(error != nil) NSLog(@"Login Error: %@", error);
	NSString *loginPage = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];

//[loginPage writeToFile:[self getTmpPath:@"SunriseLogin.html"] atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];

	return loginPage;
}


- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	NSString *loginPage = [self getLoginPage:login password:password];
	if(loginPage == nil) return SS_NO_INTERNET_ERROR;

	if([loginPage rangeOfString:@"AuthnContext"].location == NSNotFound && // when authenticating
		[loginPage rangeOfString:@"SMSCommand"].location == NSNotFound) {   // when sending SMS
		return SS_LOGIN_ERROR;
	}
	mAvailableSMS = [self GetAvailableSMS:0];
	
	return SS_LOGIN_OK;
}


- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:number   forKey:@"recipient"];
	[postDictionary setValue:message  forKey:@"message"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"http://mip.sunrise.ch/mip/dyn/sms/sms?.lang=de"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];
	[request setValue:[NSString stringWithFormat:@"SMIP=%@;", mCookie] forHTTPHeaderField:@"Cookie"];

	[postDictionary release];
	
	NSURLResponse *response = nil;
	NSError       *error = nil;
	NSData        *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	NSString      *sendResult = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];

//[sendResult writeToFile:[self getTmpPath:@"SunriseSend.html"] atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];
	if([sendResult rangeOfString:@"SMS wurde an "].location == NSNotFound &&  // SMS wurde an 07XAAABBCC gesendet.
		[sendResult rangeOfString:@"Un SMS a &#233;t&#233; envoy&#233;"].location == NSNotFound &&
		[sendResult rangeOfString:@"L'SMS &#232; stato inviato a"].location == NSNotFound ) {  // L'SMS √® stato inviato a 07XAAABBCC.
			return SS_SENDING_ERROR;
	}

	int newAvailableSMS = [self GetAvailableSMS:sendResult];
	
	if(newAvailableSMS >= mAvailableSMS) {
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
