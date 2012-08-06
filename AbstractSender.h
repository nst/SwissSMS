#import <Cocoa/Cocoa.h>
#import <Security/SecKeychain.h>

#define API_VERSION 0.1

@interface AbstractSender : NSObject {
    NSData *imageData;
}

typedef enum {
    SS_SENDING_OK = 0,
    SS_SENDING_ERROR,
    SS_LOGIN_OK,
	SS_LOGIN_ERROR,
    SS_KEYCHAIN_ERROR,
    SS_QUOTA_EXCEEDED,
    SS_NO_INTERNET_ERROR,
    SS_ADDRESS_BOOK_ERROR,
    SS_MESSAGE_ENCODING_ERROR,
	SS_SERVICE_UNAVAILABLE_ERROR,
	SS_CLI_ERROR,
	SS_PLUGIN_INTERNAL_ERROR,
} SwissSMSSendingStatus;

+ (id)sharedSender;

#pragma mark default implentation, don't redefine this

- (unsigned)numberOfMessagesForString:(NSString *)s;

#pragma mark default implentation, can be redefined by subclasses

// service image
- (NSData *)imageData;

// service name
- (NSString *)name;

// max chars allowed
- (int)maxChars;

// true is plugin needs login and password
- (BOOL)needsLoginAndPassword;

// return the country code according to wikipedia (TODO), use 'int' for international or undefined
- (NSString *)countryCode;

// plugin version number, increment from 0.1, use X.X or X.X.X. if not implemented, 0.0 is assumed
- (NSString *)version;

// author name
- (NSString *)author;

// the version of the API the plugin is using
- (NSString *)apiVersion;

#pragma mark mandatory subclass implentation

// login
- (SwissSMSSendingStatus)login:(NSString *)login password:(NSString *)password;

// send the message
- (SwissSMSSendingStatus)sendMessage:(NSString *)message toNumber:(NSString *)phoneNumber;

// returns a valid phone number for the service, else return nil
- (NSString *)normalizePhoneNumber:(NSString *)rawString;

#pragma mark optional subclass implentation

// update check
- (NSString *)latestVersionNumber;
- (NSString *)latestVersionURL;
- (NSString *)pluginWebsiteURL;

// remaining messages allowed
- (int)remainingMessagesAllowed;

// logout - will be performed on service change or application quiting
- (BOOL)logout;

#pragma mark keychain storage

- (SecProtocolType)serviceProtocol;
- (NSString *)serviceServerName;


@end
