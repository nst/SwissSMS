#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@interface NetAppelINT : AbstractSender {
	NSString *cachedLogin;
	NSString *cachedPassword;
}

@end
