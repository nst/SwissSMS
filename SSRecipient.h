//
//  SSRecipient.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 12.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractSender.h"

@protocol SSRecipientProtocol <NSObject>
-(NSData *)imageData;
-(NSString *)phone;
-(NSString *)name;
@end

@interface SSRecipient : NSObject {
}

+(id <SSRecipientProtocol>) findRecipientFromObject:(id)o sender:(AbstractSender *)sender;
+(id <SSRecipientProtocol>) findRecipientFromObject:(id)o;

@end
