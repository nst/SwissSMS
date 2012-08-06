#import "NetAppelINT.h"
#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation NetAppelINT

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {

	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
	[postDictionary setValue:@"menu"  forKey:@"part"];
	[postDictionary setValue:login forKey:@"username"];
	[postDictionary setValue:password   forKey:@"password"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://myaccount.netappel.fr/clx/index.php"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSWindowsCP1252StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
    //[urlContent writeToFile:@"/Users/nst/Desktop/NAlogin.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];

    if([urlContent rangeOfString:@"url=buy_credit.php"].location == NSNotFound) {
        return SS_LOGIN_ERROR;
    }
	
    return SS_LOGIN_OK;
}

- (BOOL)logout {
	NSString *s = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://myaccount.netappel.fr/clx/index.php?part=logoff"]];
	return s != nil;
}

- (NSString *)callerId {
	NSURL *url = [NSURL URLWithString:@"https://myaccount.netappel.fr/clx/websms2.php"];
	NSString *s = [NSString stringWithContentsOfURL:url];
	NSRange range = [s rangeOfString:@"<select name=\"callerid\">"];
	if(range.location == NSNotFound) {
		return nil;
	}
	
	int fromIndex = range.location + range.length;
	s = [s substringFromIndex:fromIndex];
	range = [s rangeOfString:@"<option value=\""];
	if(range.location == NSNotFound) {
		return nil;
	}
	
	fromIndex = range.location + range.length;
	s = [s substringFromIndex:fromIndex];
	range = [s rangeOfString:@"\">"];
	if(range.location == NSNotFound) {
		return nil;
	}

	int toIndex = range.location;
	
	//range = NSMakeRange(fromIndex, fromIndex - toIndex);
	NSString *r = [s substringToIndex:toIndex];
	return r;
	//return nil;
	
	//NSString *regexp = @"<select name=\"callerid\">\s*?<option value=\"(\+41792026073)\">";
	//NSPredicate *p = [NSPredicate predicateWithFormat:@"SELF MATCHES ", regexp, nil];
}

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
	//NSLog(@"sentMessages == %d", sentMessages);

	NSString *callerId = [self callerId];

	NSDictionary *postDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	[postDictionary setValue:@"send"     forKey:@"action"];
	[postDictionary setValue:@""         forKey:@"panel"];
	[postDictionary setValue:message     forKey:@"message"];
	[postDictionary setValue:callerId    forKey:@"callerid"]; // set to the login name if invalid
	[postDictionary setValue:number       forKey:@"bnrphonenumber"];
	[postDictionary setValue:@"no"       forKey:@"sendscheduled"];
	[postDictionary setValue:@"01"       forKey:@"day"];
	[postDictionary setValue:@"01"       forKey:@"month"];
	[postDictionary setValue:@"00"       forKey:@"hour"];
	[postDictionary setValue:@"00"       forKey:@"minute"];
	[postDictionary setValue:@"1"       forKey:@"gmt"];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setTimeoutInterval:5.0];
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setURL:[NSURL URLWithString:@"https://myaccount.netappel.fr/clx/websms2.php"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postDictionary formDataWithEncoding:NSWindowsCP1252StringEncoding]];

    [postDictionary release];

    NSURLResponse *response = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *urlContent = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    
    //[urlContent writeToFile:@"/Users/nst/Desktop/NAsent.html" atomically:YES encoding:NSMacOSRomanStringEncoding error:nil];
	
    if([urlContent rangeOfString:@"pour terminer cet appel"].location != NSNotFound) {
        return SS_QUOTA_EXCEEDED;
    }
		
    if([urlContent rangeOfString:@"Message envoy"].location == NSNotFound) {
        return SS_SENDING_ERROR;
    }
    
	return SS_SENDING_OK;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	if(!rawString) return nil;
	return [rawString normalizedInternationalNumberWithZero];
}

@end
