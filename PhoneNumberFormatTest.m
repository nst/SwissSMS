//
//  PhoneNumberFormatTest.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 18.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PhoneNumberFormatTest.h"
#import <SSSender/SSSender.h>

@implementation PhoneNumberFormatTest

- (void) setUp {
}

- (void) tearDown {
}

- (void) testnormalizedSwissGSMPhoneNumber {
	NSString *n = @"0781234567";
	NSString *s;
	int i;
	
	NSArray *good = [NSArray arrayWithObjects:n, @"+41781234567", @"0041781234567", @"078 / 1234567", nil];
	for(i = 0; i < [good count]; i++) {
		s = [good objectAtIndex:i];
		STAssertEqualObjects([s normalizedSwissGSMPhoneNumber], n, @"[NSString +normalizedSwissGSMPhoneNumber] did return %@ instead of %@", [s normalizedSwissGSMPhoneNumber], n);
	}

	NSArray *bad = [NSArray arrayWithObjects:@"0001234567", @"078123456", @"07812345678", @"abc", nil];
	for(i = 0; i < [bad count]; i++) {
		s = [bad objectAtIndex:i];
		STAssertNil([s normalizedSwissGSMPhoneNumber], @"[NSString +normalizedSwissGSMPhoneNumber] did return %@ instead of %@", [s normalizedSwissGSMPhoneNumber], nil);
	}
	
}

- (void) testNormalizedInternationalNumberWithZero {
	NSString *n = @"0033612345678";
	NSString *s;
	int i;
	
	NSArray *good = [NSArray arrayWithObjects:n, @"+33612345678", @"0033-6-12345678", nil];
	for(i = 0; i < [good count]; i++) {
		s = [good objectAtIndex:i];
		STAssertEqualObjects([s normalizedInternationalNumberWithZero], n, @"[NSString +normalizedInternationalNumberWithZero] did return %@ instead of %@", [s normalizedInternationalNumberWithZero], n);
	}

	NSArray *bad = [NSArray arrayWithObjects:@"9933012345678", @"abc", nil];
	for(i = 0; i < [bad count]; i++) {
		s = [bad objectAtIndex:i];
		STAssertNil([s normalizedInternationalNumberWithZero], @"[NSString +normalizedInternationalNumberWithZero] did return %@ instead of %@", [s normalizedInternationalNumberWithZero], nil);
	}
	
	n = @"0041781234567";

	good = [NSArray arrayWithObjects:n, @"+41781234567", @"0041781234567", @"0041-78-1234567", nil];
	for(i = 0; i < [good count]; i++) {
		s = [good objectAtIndex:i];
		STAssertEqualObjects([s normalizedInternationalNumberWithZero], n, @"[NSString +normalizedInternationalNumberWithZero] did return %@ instead of %@", [s normalizedInternationalNumberWithZero], n);
	}	
}

- (void) test {
	NSString *source = @"0795804712";
	NSString *result = [source normalizedInternationalNumberWithZero];
	STAssertEqualObjects(result, @"0041795804712", @"[NSString +normalizedInternationalNumberWithZero] did return %@ instead of %@", result, @"0041795804712");
	

}

@end
