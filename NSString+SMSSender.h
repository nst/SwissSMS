//
//  NSString+SMSSender.h
//  SMSRomandie
//
//  Created by Nicolas Seriot on 24.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (SMSSender)

- (NSString *) normalizedSwissGSMPhoneNumber ;
//- (NSString *)normalizedFrenchNumber;
- (NSString *)normalizedInternationalNumberWithZero; // 0033791234567
- (NSString *)normalizedInternationalNumberWithPlus; // +33791234567

- (NSString *)escapeWithEncoding:(NSStringEncoding)encoding;
- (NSString *) stringByRemovingCharactersFromSet:(NSCharacterSet *) set;

+ (NSSet *) swissGSMPrefixes;

@end
