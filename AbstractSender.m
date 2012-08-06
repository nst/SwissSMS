//
//  AbstractSender.m
//  SMSRomandie
//
//  Created by Nicolas Seriot on 23.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "AbstractSender.h"
#import "NSString+SMSSender.h"

@implementation AbstractSender

static AbstractSender *sharedSender = nil;

- (void)encodeWithCoder:(NSCoder *)encoder {
	//NSLog(@"%@ encodeWithCoder:", self);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	//NSLog(@"%@ initWithCoder:", self);
	return nil;
}

+ (id)sharedSender {
    if (sharedSender == nil) {
        sharedSender = [[AbstractSender alloc] init];
    }
    return sharedSender;
}

- (BOOL)needsLoginAndPassword {
    NSNumber *n = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPNeedsAuthentication"];
	//NSLog(@"-- needsLoginAndPassword %@", n);
	return [n boolValue];
}

- (NSString *)name {
    NSString *s = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPName"];
	if (!s || [s length] == 0) {
		return @"Undefined";
	}
	return s;
}

- (int)maxChars {
    NSNumber *n = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPMaxChars"];
	if (n) {
		return [n intValue];
	}
	return 0;
}

- (id)init {
    self = [super init];
    return self;
}

- (void)dealloc {
    [imageData release];
    [super dealloc];
}

- (NSData *)imageData {
    if(imageData == nil) {
        NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:[self name] ofType:@"png"];
        imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    }
    return imageData;
}

- (unsigned)numberOfMessagesForString:(NSString *)s {
    unsigned shortLen = [self maxChars] - 5; // [x/x]
    unsigned longLen = [self maxChars] - 7; // [xx/xx]

    if([s length] <= [self maxChars]) {
        return 1;
    } else if ([s length] < shortLen * 9 ) {
        return 1 + [s length] / shortLen;
    } else {
        return 1 + [s length] / longLen;
    }
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
    return SS_LOGIN_ERROR;
}

- (SwissSMSSendingStatus) sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    return SS_SENDING_ERROR; // to be implemented in subclass
}

- (SwissSMSSendingStatus)sendMessage:(NSString *)message toNumber:(NSString *)number {
    if(!message || !number) {
        return SS_SENDING_ERROR;
    }
    	
    [[message retain] autorelease];
    [[number retain] autorelease];
    
    if([message length] <= [self maxChars]) {
		[message retain];
		return [self sendOneMessage:[message autorelease] toNumber:number];
    }

    unsigned len;
    if([message length] <= 9 * [self maxChars]) {
        len = [self maxChars] - 5;
    } else {
        len = [self maxChars] - 7;
    }
    
    // slice message
    NSMutableString *m = [NSMutableString stringWithString:message];
    NSString *slice;
    NSString *subMessage;
    unsigned msgNumber = 0;
    unsigned totalMessages = [message length] / len + 1;
    NSRange range;
    while([m length] > 0) {
        range = NSMakeRange(0,[m length] < len ? [m length] : len);
        slice = [m substringWithRange:range];
        subMessage = [NSString stringWithFormat:@"[%d/%d]%@", msgNumber+1, totalMessages, slice];
        
        SwissSMSSendingStatus status = [self sendOneMessage:subMessage toNumber:number];
        if(status != SS_SENDING_OK) {
            return status;
        }
        
        [m deleteCharactersInRange:range];
        msgNumber++;
    }
    
    return SS_SENDING_OK;
}

/*
+ (NSString *)phoneNumberFormat {
	return @"07[789][0-9]{7}";
}
*/

- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	return nil; // subclass responsability
}

- (NSString *)latestVersionNumber {
	return nil; // subclass responsability
}

- (NSString *)latestVersionURL {
	return nil; // subclass responsability
}

- (NSString *)pluginWebsiteURL {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPWebSite"];
}

- (NSString *)countryCode {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPCountryCode"];
}

- (NSString *)version {
	NSString *s = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPVersion"];
	return s ? s : @"0.0";
}

- (NSString *)author {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPAuthor"];
}

- (NSString *)apiVersion {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPAPIVersion"];
}

- (int)remainingMessagesAllowed {
	return 0; // subclass responsability
}

- (BOOL)logout {
	return FALSE; // subclass responsability
}

#pragma mark keychain storage

/* In the future plugin API, these service... functions will be replaced by keys/values in the Info.plist */
- (SecProtocolType)serviceProtocol {
	NSString *s = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPKProtocol"];
	if([[s lowercaseString] isEqualToString:@"https"]) {
		return kSecProtocolTypeHTTPS;
	} else {
		return kSecProtocolTypeHTTP;
	}
}

/* This must be overriden in the subclass, if not overriden, then it is assumed no log/pass is needed
   It must match what is saved in the keychain by Safari so that users can
   use 1 keychain item shared by Safari (and other browsers) and SwissSMS */
- (NSString *)serviceServerName {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SSPKServer"];
}

@end
