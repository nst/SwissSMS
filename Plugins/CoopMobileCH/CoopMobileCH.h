//
//  SMSCoopMobileSender.h
//  SwissSMS
//
//  Created by CŽdric Luthi on 24.09.07.
//  Copyright 2007 CŽdric Luthi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"


@interface CoopMobileCH : AbstractSender {
	NSString *login;
	NSString *password;
}

@end
