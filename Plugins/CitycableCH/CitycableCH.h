#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@interface CitycableCH : AbstractSender {
	NSString *cachedLogin;
	NSString *cachedPassword;
	NSString *session;
}

@end
