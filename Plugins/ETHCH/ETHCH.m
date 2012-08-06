#import "ETHCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation ETHCH

- (id)init {
	self = [super init];
	session = nil;
	return self;
}

- (void)setSessionFromString:(NSString *)s {
    NSRange sessionNameRange = [s rangeOfString:@"Sess="];
    int sessionLocation = sessionNameRange.location + 5; 

	NSRange sessionEndRange = [s rangeOfString:@"&" options:(unsigned)NULL range:NSMakeRange(sessionLocation, 60)];
	int sessionEndDelimiter = sessionEndRange.location;
    NSRange sessionRange = NSMakeRange(sessionLocation, sessionEndDelimiter-sessionLocation);
	[self setValue:[s substringWithRange:sessionRange] forKey:@"session"];
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	[cachedLogin release];
	[cachedPassword release];
	cachedLogin = [login retain];
	cachedPassword = [password retain];

	NSString *urlLoginContent = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://www.sms.ethz.ch/"]];
	
	if(!urlLoginContent) {
		return SS_NO_INTERNET_ERROR;
	}
	
	if(login == nil || password == nil) {
		return SS_LOGIN_ERROR;
	}
	
	NSLog(login,password);
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:login              forKey:@"username"];
	[postDictionary setValue:password           forKey:@"password"];
	[postDictionary setValue:@"listoriginators" forKey:@"action"];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://idn.ethz.ch/cgi-bin/sms/send.pl"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
//	NSLog(urlContent);
	
    if([urlContent rangeOfString:@"200"].location == NSNotFound) {
        return SS_LOGIN_ERROR;
    }
		
    return SS_LOGIN_OK;
}

/*
// logout
- (void)logout {
	NSURL *url = [NSURL URLWithString:@"http://www.orange.ch/myorange?.portal_action=.logoutUser&.portlet=sms"];
	NSString *s = [NSString stringWithContentsOfURL:url];
	if(s == 0) {
	}
}
*/

// send the message
- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    NSAssert(message != nil, @"message is nil");
    NSAssert(![message isEqualToString:@""], @"message is empty");
    NSAssert(number != nil, @"number is nil");
	/*
	#warning debug
	NSLog(@"simulated: %@ %@", number, message);
	return SS_SENDING_OK;
	*/
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
	[postDictionary setValue:cachedLogin    forKey:@"username"];
	[postDictionary setValue:cachedPassword forKey:@"password"];
	[postDictionary setValue:@"sendsms"     forKey:@"action"];
	[postDictionary setValue:@"auto"        forKey:@"originator"];
	[postDictionary setValue:number         forKey:@"number"];
	[postDictionary setValue:message        forKey:@"message"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://idn.ethz.ch/cgi-bin/sms/send.pl"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

//	if(error) {
//        return SS_SENDING_ERROR;
//	}

    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
//	NSLog(urlContent);
//	
//    if([urlContent rangeOfString:@"500"].location != NSNotFound) {
//        return SS_QUOTA_EXCEEDED;
//    }

    if([urlContent rangeOfString:@"200"].location == NSNotFound) {
        return SS_SENDING_ERROR;
    }
	
    return SS_SENDING_OK;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	NSString *s = [rawString normalizedSwissGSMPhoneNumber];
	if(!s) {
		s = [rawString normalizedInternationalNumberWithZero];
	}
	return s;
}

@end
