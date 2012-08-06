#import "CitycableCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation CitycableCH

- (id)init {
	self = [super init];
	session = nil;
	return self;
}

- (void)setSessionFromString:(NSString *)s {
    NSRange sessionNameRange = [s rangeOfString:@"Sess="];
    int sessionLocation = sessionNameRange.location + 5; 

	NSRange sessionEndRange = [s rangeOfString:@"&" options:0 range:NSMakeRange(sessionLocation, 60)];
	int sessionEndDelimiter = sessionEndRange.location;
    NSRange sessionRange = NSMakeRange(sessionLocation, sessionEndDelimiter-sessionLocation);
	[self setValue:[s substringWithRange:sessionRange] forKey:@"session"];
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	/*
	#warning debug
	NSLog(@"simulated: login %@ %@", login, password);
	return SS_LOGIN_OK;
	*/
	[cachedLogin release];
	[cachedPassword release];
	cachedLogin = [login retain];
	cachedPassword = [password retain];

	NSString *urlLoginContent = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://webmail.citycable.ch/trackerscim/index.php"]];
	
	if(!urlLoginContent) {
		return SS_NO_INTERNET_ERROR;
	}
	
	if(login == nil || password == nil) {
		return SS_LOGIN_ERROR;
	}
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
	[postDictionary setValue:login    forKey:@"t_login"];
	[postDictionary setValue:password forKey:@"t_pass"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://webmail.citycable.ch/trackerscim/index.php"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
    if([urlContent rangeOfString:@"aktion=T_INIT"].location == NSNotFound) {
        return SS_LOGIN_ERROR;
    }
	
    //[urlContent writeToFile:@"/Users/nst/Desktop/login_after.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];
	
	[self setSessionFromString:urlContent];
	
	//NSLog(@"session %@", session);
	
	if(!session) {
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
	
	if(!session) {
		return SS_PLUGIN_INTERNAL_ERROR;
	}

	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
	[postDictionary setValue:session       forKey:@"Sess"];
	[postDictionary setValue:@"T_WRITEM2S" forKey:@"aktion"];
	[postDictionary setValue:@"T_ENVSMS"   forKey:@"t_env"];
	[postDictionary setValue:number        forKey:@"nummobile"];
	[postDictionary setValue:message       forKey:@"textsms"];
	[postDictionary setValue:@"Envoyer"       forKey:@"sendsms"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://webmail.citycable.ch/trackerscim/tracker.php"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSISOLatin1StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if(error) {
        return SS_SENDING_ERROR;
	}

    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
    //[urlContent writeToFile:@"/Users/nst/Desktop/send_after.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];

    if([urlContent rangeOfString:@"Vous ne disposez plus de quota suffisant"].location != NSNotFound) {
        return SS_QUOTA_EXCEEDED;
    }

    if([urlContent rangeOfString:@"Le SMS a bien"].location == NSNotFound) {
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
