#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@interface ETHCH : AbstractSender {
	NSString *cachedLogin;
	NSString *cachedPassword;
	NSString *session;
}

@end
