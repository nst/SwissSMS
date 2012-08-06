//
//  Send SMS.h
//  Send SMS
//
//  Created by Administrator on 19.09.07.
//  Copyright 2007 Cédric Luthi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface Send_SMS : AMBundleAction 
{
	NSString *swisssms_executable_path;
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
