//
//  KeychainAccess.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 05.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <Security/SecKeychain.h>

@interface KeychainAccess : NSObject {

}

+ (NSString *)internetHTMLFormPasswordForServer:(NSString *)serverName protocol:(SecProtocolType)protocol keychainItem:(SecKeychainItemRef *)keychainItem notFound:(BOOL *)notFound;
+ (NSString *)loginForItem:(SecKeychainItemRef)keychainItem;

+ (void)addInternetHTMLFormPasswordForServer:(NSString *)serverName login:(NSString *)login password:(NSString *)password protocol:(SecProtocolType)protocol;


@end
