//
//  KeychainAccess.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 05.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "KeychainAccess.h"

#include <Security/SecKeychainItem.h>
#include <Security/SecAccess.h>
#include <Security/SecTrustedApplication.h>
#include <Security/SecACL.h>

@implementation KeychainAccess

+ (NSString *)internetHTMLFormPasswordForServer:(NSString *)serverName protocol:(SecProtocolType)protocol keychainItem:(SecKeychainItemRef *)keychainItem notFound:(BOOL *)notFound {

	UInt32 passwordLength;
	void *pswd = nil;
	
	OSStatus err = SecKeychainFindInternetPassword(NULL, strlen([serverName UTF8String]), [serverName UTF8String], /* securityDomain */ 0, NULL, /* accountName */ 0, NULL,
												   /* path */ 0, NULL, /* port */ 0, protocol, kSecAuthenticationTypeHTMLForm, &passwordLength, &pswd, keychainItem);
	
	*notFound = err == errSecItemNotFound;
	if (err != noErr) {	
		// TODO somehow report the error if it's not one of (errSecItemNotFound | userCanceledErr | errSecAuthFailed)
		// errSecAuthFailed happens when user clicks the Deny button
		return nil;
	}
	
	return [[[NSString alloc] initWithData:[NSData dataWithBytes:pswd length:passwordLength] encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSString *)loginForItem:(SecKeychainItemRef)keychainItem {
		NSString *username;

		SecKeychainAttributeList list;
		SecKeychainAttribute attr;
		
		list.count = 1;
		list.attr = &attr;
		
		attr.tag = kSecAccountItemAttr;

		OSStatus err;
		err = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);
		NSAssert1(err == noErr, @"SecKeychainItemCopyContent -> %lu", err);
		
		if (attr.data != NULL) {
			username = [[[NSString alloc] initWithData:[NSData dataWithBytes:attr.data length:attr.length] encoding:NSUTF8StringEncoding] autorelease];
		} else {
			NSLog(@"Login not found.");
			return nil;
		}
		
		SecKeychainItemFreeContent(&list, NULL);
		
		return username;
}

+ (void)addInternetHTMLFormPasswordForServer:(NSString *)serverName login:(NSString *)login password:(NSString *)password protocol:(SecProtocolType)protocol {
	OSStatus err = SecKeychainAddInternetPassword(NULL, strlen([serverName UTF8String]), [serverName UTF8String], /* securityDomain */ 0, NULL, strlen([login UTF8String]), [login UTF8String],
										 /* path */ 0, NULL, /*port */ 0, protocol, kSecAuthenticationTypeHTMLForm, strlen([password UTF8String]), [password UTF8String], NULL);

	if (err != noErr) {
		// Documentation says "The result code errSecNoDefaultKeychain indicates that no default keychain could be found."
		// What would a user without a keychain expect when he chose "Add to keychain" ?
		NSLog(@"Unable to set password for %@ (%ld)", serverName, err);
	}
}

@end
