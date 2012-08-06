//
//  NSDictionary+SMSSender.m
//  SMSRomandie
//
//  Created by Nicolas Seriot on 24.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "NSDictionary+SMSSender.h"
#import "NSString+SMSSender.h"

@implementation NSDictionary (SMSSender)

- (NSData *)formDataWithEncoding:(NSStringEncoding)encoding {
	NSArray *allKeys = [self allKeys];
	NSMutableArray *keyAndValues = [NSMutableArray arrayWithCapacity:[allKeys count]];
	
	NSEnumerator *e = [allKeys objectEnumerator];
	NSString *dictKey;
	while((dictKey = [e nextObject])){

		NSString *encodedKey = [dictKey escapeWithEncoding:encoding];
		NSString *encodedValue = [(NSString *)[self objectForKey:dictKey] escapeWithEncoding:encoding];
        
		NSString *keyAndValue = [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue];

		[keyAndValues addObject:keyAndValue];
	}
	
	NSString *s = [keyAndValues componentsJoinedByString:@"&"];
	return [s dataUsingEncoding:NSASCIIStringEncoding];
}

@end
