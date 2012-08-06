//
//  NSURL+SMSSender.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 30.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSURL+SMSSender.h"


@implementation NSURL (SMSSender)

- (NSData *)dataWithUserAgent:(NSString *)userAgent {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
	NSHTTPURLResponse *response;
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	NSError *connectionError = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
	[request release];
	
	if (connectionError) {
		NSLog(@"-- error while retrieving %@: %@", self, [connectionError localizedDescription]);
		return nil;
	}
	
	return data;
}

- (NSString *)stringWithUserAgent:(NSString *)userAgent {
	NSData *data = [self dataWithUserAgent:userAgent];
	if(!data) return nil;
	return [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
}

@end
