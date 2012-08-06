#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@interface MjoyINT : AbstractSender {
	int sentMessages;
	NSString *cachedLogin;
	NSString *cachedPassword;
	NSHTTPCookieAcceptPolicy userCookiePolicy;
	NSString *sid;
}

@end
