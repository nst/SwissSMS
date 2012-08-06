//
//  NSString+SMSSender.m
//  SMSRomandie
//
//  Created by Nicolas Seriot on 24.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "NSString+SMSSender.h"


@implementation NSString (SMSSender)

/*
- (NSString *)normalizedFrenchNumber {
	NSString *numbersOnly = [self removeCharsInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]];
	// +33619684891
	NSMutableString *normalizedNumber = [NSMutableString stringWithString:numbersOnly];
	
	switch([numbersOnly length]){
		case 12:
			if([normalizedNumber hasPrefix:@"+33"]){
				[normalizedNumber replaceOccurrencesOfString:@"+33" withString:@"0" options:nil range:NSMakeRange(0, 4)];
			}
			break;
		default:
			break;
	}

	return ([normalizedNumber hasPrefix:@"06"] && [normalizedNumber length] == 10) ? normalizedNumber : nil;
}
*/

- (NSString *) normalizedSwissGSMPhoneNumber {
	// no more '+'
	NSString *numbersOnly = [self stringByRemovingCharactersFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	NSMutableString *normalizedNumber = [NSMutableString stringWithString:numbersOnly];
	
	switch ([numbersOnly length]) {
		case 11:
			if([normalizedNumber hasPrefix:@"41"]) {
				[normalizedNumber replaceOccurrencesOfString:@"41" withString:@"0" options:0 range:NSMakeRange(0, 2)];
			}
			break;
		case 12:
			if([normalizedNumber hasPrefix:@"410"]) {
				[normalizedNumber replaceOccurrencesOfString:@"410" withString:@"0" options:0 range:NSMakeRange(0, 3)];
			}
			break;
		case 13:
			if ([normalizedNumber hasPrefix:@"0041"]) {
				[normalizedNumber replaceOccurrencesOfString:@"0041" withString:@"0" options:0 range:NSMakeRange(0, 4)];
			}
			break;
		case 14:
			if ([normalizedNumber hasPrefix:@"00410"]) {
				[normalizedNumber replaceOccurrencesOfString:@"00410" withString:@"0" options:0 range:NSMakeRange(0, 5)];
			}
			break;
			
		default:
			break;
	}
	
	// order swapped to avoid out of range in -substringToIndex:
	if (([normalizedNumber length] == 10) && [[NSString swissGSMPrefixes] containsObject:[normalizedNumber substringToIndex:3]]) {
		return normalizedNumber;
	}
	
	return nil;
}

- (NSString *)normalizedInternationalNumberWithZero {
	// 0033791234567
	NSString *numbersOnly = [self stringByRemovingCharactersFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]];
	
	NSMutableString *normalizedNumber = [NSMutableString stringWithString:numbersOnly];

	if([normalizedNumber hasPrefix:@"+"]) {
		[normalizedNumber replaceOccurrencesOfString:@"+" withString:@"00" options:(unsigned)NULL range:NSMakeRange(0, 4)];
	}
	
	if(([normalizedNumber length] == 10) && ([normalizedNumber hasPrefix:@"07"])) {
		// we assume the number to be a swiss mobile
		[normalizedNumber replaceOccurrencesOfString:@"0" withString:@"0041" options:(unsigned)NULL range:NSMakeRange(0, 1)];
	}
	
	if(![normalizedNumber hasPrefix:@"0"]) {
		return nil;
	}
	
	//NSLog(@"normalizedNumber %@", normalizedNumber);
	return normalizedNumber;
}

- (NSString *)normalizedInternationalNumberWithPlus {
	// +33791234567
	NSString *withZeros = [self normalizedInternationalNumberWithZero];
	if(!withZeros || [withZeros length] < 2) return nil;

	NSString *withPlus = [@"+" stringByAppendingString:[withZeros substringFromIndex:2]];
	return withPlus;
}

- (NSString *)escapeWithEncoding:(NSStringEncoding)encoding{
	// Convert to NSData then back to NSString
	// It must be done to allow lossy conversion, because stringByAddingPercentEscapesUsingEncoding may return nil otherwise
	NSString *lossyString = [[NSString alloc] initWithData:[self dataUsingEncoding:encoding allowLossyConversion:YES] encoding:encoding];
	NSString *escapedString = [lossyString stringByAddingPercentEscapesUsingEncoding:encoding];
	[lossyString release];

	NSMutableString *mutableString = [NSMutableString stringWithString:escapedString];

	[mutableString replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[escapedString length])];
	[mutableString replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[escapedString length])];
	[mutableString replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[escapedString length])];
	[mutableString replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[escapedString length])];

	return mutableString;
}

- (NSString *) stringByRemovingCharactersFromSet:(NSCharacterSet *) set{
	unsigned int length = [self length];
	unichar buf_src[length];
	unichar buf_dst[length];
	[self getCharacters:buf_src];
	
	int i;
	int j = 0;
	for(i = 0; i < length; i++) {
		if(![set characterIsMember:buf_src[i]]) {
			buf_dst[j++] = buf_src[i];
		}
	}
	return [NSString stringWithCharacters:buf_dst length:j];
}

+ (NSSet *) swissGSMPrefixes {
	return [NSSet setWithObjects:@"076", @"077", @"078", @"079", nil];
}

@end
