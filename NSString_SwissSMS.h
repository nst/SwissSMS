//
//  NSString_SwissSMS.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 09.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SSRecipient.h>


@interface NSString (SwissSMS) <SSRecipientProtocol>

+ (NSString *) bluePhoneEliteExportFilePath;
+ (NSString *) uuid;

//- (NSString *)removeCharsInSet:(NSCharacterSet *)set;

@end
