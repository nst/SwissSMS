#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@interface OrangeCH : AbstractSender {
	NSUInteger nbSentMessages;
	NSString *cachedLogin;
	NSString *cachedPassword;
	NSString *token;
	NSHTTPCookieAcceptPolicy userCookiePolicy;
    
    NSString *sunQueryParamsString;
}

@property (nonatomic, retain) NSString *cachedLogin;
@property (nonatomic, retain) NSString *cachedPassword;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSString *sunQueryParamsString;

@end
