//
//  SMSSunriseSender.h
//  SwissSMS
//
//  Created by Christian Rueegg on 30.04.07.
//  Copyright 2007 Christian Rueegg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"


@interface SunriseCH : AbstractSender {
  int mAvailableSMS;
  NSString *mCookie;
}

+ (NSString *)cookieFromHTTPResponse:(NSHTTPURLResponse *)response;

@end
