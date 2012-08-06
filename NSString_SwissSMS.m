//
//  NSString_SwissSMS.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 09.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "NSString_SwissSMS.h"
#import "AbstractSender.h"


@implementation NSString (SwissSMS)

+ (NSString *)bluePhoneEliteExportFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSArray *pathComponents = [NSArray arrayWithObjects:basePath, @"BluePhoneElite", @"SMS Archive", @"Local", @"contents.plist", nil];
    
	return [pathComponents componentsJoinedByString:@"/"];
}

-(NSString *)name {
	return self;
}

-(NSString *)phone {
	return [(AbstractSender *)[[NSApp delegate] valueForKey:@"smsSender"] normalizePhoneNumber:self];
}

-(NSData *)imageData {
	return nil;
}

-(NSData *)imageDataForCurrentIMStatus {
	return nil;
}

+ (NSString *) uuid {
	CFUUIDRef uuidRef = CFUUIDCreate(nil);
	NSString *newUUID = (NSString *)CFUUIDCreateString(nil, uuidRef);
	CFRelease(uuidRef);
	return [newUUID autorelease];
}

@end
