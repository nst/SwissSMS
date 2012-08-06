#import "MjoyINT.h"
#import "SSSender.h"
#import "NSURL+SMSSender.h"

@implementation MjoyINT

- (NSString *)sidInHTML:(NSString *)s {
	// "/m/messages/3TMWIJYZTCEECDYDQYJJ3WZ55LNRMEF7BGDCGIVUJBUXRCJS6CWQ/index.htm"
	
	if(!s) return nil;
	
	NSRange r1 = [s rangeOfString:@"/m/messages/"];
	if(r1.location == NSNotFound) return nil;
	
	int index = r1.location+r1.length;
	if([s length] < index) return nil;
	
	s = [s substringFromIndex:r1.location+r1.length];
	
	NSRange r2 = [s rangeOfString:@"/"];
	if(r2.location == NSNotFound) return nil;
	
	NSString *aSid = [s substringToIndex:r2.location];
	return aSid;
}

- (void)setSid:(NSString *)aSid {
	[sid release];
	sid = aSid;
	[sid retain];
}

- (id)init {
	self = [super init];
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	userCookiePolicy = [cookieStorage cookieAcceptPolicy];
	[cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
	
	return self;
}

- (NSString *)userAgent {
	return @"Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en)";
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	
	[cachedLogin release];
	[cachedPassword release];
	cachedLogin = [login retain];
	cachedPassword = [password retain];
	
	if(login == nil || password == nil) {
		return SS_LOGIN_ERROR;
	}

	NSURL *url = [NSURL URLWithString:@"http://mjoy.com/m/login.htm"];
	NSString *urlLoginContent = [url stringWithUserAgent:[self userAgent]];
	
	if(!urlLoginContent) {
		return SS_NO_INTERNET_ERROR;
	}
	
//    if([urlLoginContent rangeOfString:@"outage.gif"].location != NSNotFound) {
//        return SS_SERVICE_UNAVAILABLE_ERROR;
//    }

    NSString *submitUrl = @"http://mjoy.com/m/login.htm";
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
	[postDictionary setValue:login          forKey:@"nickname"];
	[postDictionary setValue:password       forKey:@"password"];
	[postDictionary setValue:@"login"       forKey:@"loginButton"];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:submitUrl]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];
	[request setValue:submitUrl forHTTPHeaderField:@"Referer"];
	[request setHTTPShouldHandleCookies:YES];

    [postDictionary release];
	
    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[request release];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
	
	NSString *aSid = [self sidInHTML:urlContent];
	
	if(!aSid) return SS_LOGIN_ERROR;
	
	[self setSid:aSid];
	
//    if([urlContent rangeOfString:@"alreadyLoggedText"].location == NSNotFound) {
//        return SS_LOGIN_ERROR;
//    }
    
    return SS_LOGIN_OK;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    NSAssert(message != nil, @"message is nil");
    NSAssert(![message isEqualToString:@""], @"message is empty");
    NSAssert(number != nil, @"number is nil");
	
	if(!sid) return SS_SENDING_ERROR;
	
	NSString *urlString = [NSString stringWithFormat:@"http://mjoy.com/m/messages/%@/new.htm", sid];
	
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
	[postDictionary setValue:@""         forKey:@"name"];
	[postDictionary setValue:@""         forKey:@"number"];
	[postDictionary setValue:@""         forKey:@"from"];
	[postDictionary setValue:number      forKey:@"recipient"];
	[postDictionary setValue:message     forKey:@"msgdjwc"];
	[postDictionary setValue:@"Send"     forKey:@"send"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:10.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSUTF8StringEncoding]];
	[request setValue:urlString forHTTPHeaderField:@"Referer"];
	[request setHTTPShouldHandleCookies:YES];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];

	if(error) {
		NSLog(@"-- error: %@", [error localizedDescription]);
		return SS_SENDING_ERROR;
	}
	
    if([urlContent rangeOfString:@"Sorry,"].location != NSNotFound ||
	   [urlContent rangeOfString:@"Error report"].location != NSNotFound) {
		return SS_QUOTA_EXCEEDED;
	}
	
    if([urlContent rangeOfString:@"Message sent"].location == NSNotFound) {
        return SS_SENDING_ERROR;
    }
	
    return SS_SENDING_OK;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedInternationalNumberWithPlus];
}

- (void)dealloc {
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	[cookieStorage setCookieAcceptPolicy:userCookiePolicy];
	
	[cachedLogin release];
	[cachedPassword release];
	[super dealloc];
}

@end
