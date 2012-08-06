#import "OrangeCH.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"
#import "STHTTPRequest.h"

@implementation OrangeCH

@synthesize cachedLogin;
@synthesize cachedPassword;
@synthesize token;
@synthesize sunQueryParamsString;

- (id)init {
	self = [super init];
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	userCookiePolicy = [cookieStorage cookieAcceptPolicy];
	[cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
	
	nbSentMessages = 0;
    
	return self;
}

+ (NSString *)firstMatchOfPattern:(NSString *)p inString:(NSString *)s {
	NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:p
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    
    NSArray *matches = [regex matchesInString:s options:0 range:NSMakeRange(0, [s length])];
    
    if([matches count] == 0) return nil;
    
    NSTextCheckingResult *match = [matches objectAtIndex:0];
    
    NSRange matchRange = [match rangeAtIndex:1];
    
    return [s substringWithRange:matchRange];

}

+ (NSString *)sunQueryParamsString {
    STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://my.orange.ch/idmp/UI/Login?realm=my.orange.ch"];
    
    NSError *error = nil;
    NSString *body = [r startSynchronousWithError:&error];
    
    return [[self class] firstMatchOfPattern:@"name=\"SunQueryParamsString\" value=\"(\\S+)\"" inString:body];
    
//	NSError *error2 = nil;
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"name=\"SunQueryParamsString\" value=\"(\\S+)\""
//                                                                           options:NSRegularExpressionCaseInsensitive
//                                                                             error:&error2];
//    
//    
//    NSArray *matches = [regex matchesInString:body options:0 range:NSMakeRange(0, [body length])];
//    
//    if([matches count] == 0) return nil;
//    
//    NSTextCheckingResult *match = [matches objectAtIndex:0];
//    
//    NSRange matchRange = [match rangeAtIndex:1];
//    
//    return [body substringWithRange:matchRange];
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	    
    self.cachedLogin = login;
    self.cachedPassword = password;
        
    self.sunQueryParamsString = [[self class] sunQueryParamsString];

    NSLog(@"-- sunQueryParamsString: %@", sunQueryParamsString);
    
    if(sunQueryParamsString == nil) {
        return SS_LOGIN_ERROR;
    }
    
    STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://my.orange.ch/idmp/UI/Login"];
    
    r.POSTDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Basic", @"IDToken1", \
                        login, @"IDToken2", password, @"IDToken3", sunQueryParamsString, @"SunQueryParamsString", \
                        @"true", @"encoded", @"UTF-8", @"gx_charset", @"Basic", @"OCHAction", @"newsession", @"arg", nil];
    
    NSError *error = nil;
    NSString *s = [r startSynchronousWithError:&error]; // fill cookies

    /**/
    
    STHTTPRequest *r2 = [STHTTPRequest requestWithURLString:@"https://my.orange.ch/en/messaging/sms-composer.content"];
    
    NSError *error2 = nil;
    NSString *s2 = [r2 startSynchronousWithError:&error2];
    
    self.token = [[self class] firstMatchOfPattern:@"name=\"form\\[_token\\]\" value=\"(\\S+)\"" inString:s2];
    
    NSLog(@"-- token: %@", token);
    
    if(token == nil) {
        return SS_LOGIN_ERROR;
    }
    
    return SS_LOGIN_OK;    
}

// logout
- (BOOL)logout {
	NSURL *url = [NSURL URLWithString:@"http://www.orange.ch/myorange?.portal_action=.logoutUser&.portlet=sms"];
	return url != nil;
}

// send the message
- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    NSAssert(message != nil, @"message is nil");
    NSAssert(![message isEqualToString:@""], @"message is empty");
    NSAssert(number != nil, @"number is nil");
	
	if(nbSentMessages == 9) {
		[self logout];
		[self login:cachedLogin password:cachedPassword];
		nbSentMessages = 0;
	}

	nbSentMessages += 1;

    /**/
    
    if([number length] != 10) return SS_SENDING_ERROR;
    
    NSString *area = [number substringWithRange:NSMakeRange(1, 2)];
    NSString *n = [number substringWithRange:NSMakeRange(3, 7)];
    
	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:7];
	[postDictionary setValue:area    forKey:@"form[to][area]"];
	[postDictionary setValue:n       forKey:@"form[to][number]"];
	[postDictionary setValue:message forKey:@"form[message]"];
	[postDictionary setValue:token   forKey:@"form[_token]"];
	[postDictionary setValue:@"1"    forKey:@"submit"];
	[postDictionary setValue:@""     forKey:@"form[sentTillNow]"];
	[postDictionary setValue:@"1"    forKey:@"form[submitted]"];
	    
    STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://my.orange.ch/en/messaging/sms-composer.content"];
    
    r.POSTDictionary = postDictionary;
    
    NSError *error = nil;
    NSString *s = [r startSynchronousWithError:&error];
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:r.responseData options:0 error:&jsonError];
    
    if([[json valueForKey:@"status"] integerValue] == 1) {
        return SS_SENDING_OK;
    }
    
    return SS_SENDING_ERROR;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedSwissGSMPhoneNumber];
}

- (void)dealloc {
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	[cookieStorage setCookieAcceptPolicy:userCookiePolicy];
	
	[cachedLogin release];
	[cachedPassword release];
    [token release];
    [sunQueryParamsString release];

	[super dealloc];
}

@end
