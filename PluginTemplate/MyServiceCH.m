#import "MyServiceCH.h"

@implementation MyServiceCH

- (SecProtocolType)serviceProtocol {
	return kSecProtocolTypeHTTPS;
}

- (NSString *)serviceServerName {
	return @"www.myservice.ch";
}

- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password {
	return SS_LOGIN_ERROR;
}

- (SwissSMSSendingStatus)sendOneMessage:(NSString *)message toNumber:(NSString *)number {
    return SS_SENDING_ERROR;
}

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString {
	return nil;
}

@end
