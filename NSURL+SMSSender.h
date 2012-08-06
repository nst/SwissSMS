//
//  NSURL+SMSSender.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 30.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (SMSSender)

- (NSData *)dataWithUserAgent:(NSString *)userAgent;
- (NSString *)stringWithUserAgent:(NSString *)userAgent;

@end
