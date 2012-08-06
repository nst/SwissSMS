//
//  NSDictionary+SMSSender.h
//  SMSRomandie
//
//  Created by Nicolas Seriot on 24.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (SMSSender)

- (NSData *)formDataWithEncoding:(NSStringEncoding)encoding;

@end
