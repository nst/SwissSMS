//
//  NSFileManager_SwissSMS.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 25.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager_SwissSMS.h"


@implementation NSFileManager (SwissSMS)

- (BOOL)copyResource:(NSString *)sourcePath toChosenDestination:(NSString *)defaultDir {
	NSFileManager *fm = [NSFileManager defaultManager];

	BOOL isDir;
	BOOL fileExists = [fm fileExistsAtPath:defaultDir isDirectory:&isDir];
	if(!fileExists) {
		[fm createDirectoryAtPath:defaultDir attributes:nil];
	}

	NSString *destPath = [defaultDir stringByAppendingPathComponent:[sourcePath lastPathComponent]];

	if ([fm fileExistsAtPath:sourcePath]) {
		[fm removeFileAtPath:destPath handler:nil];
		return [fm copyPath:sourcePath toPath:destPath handler:nil];
	} else {
		return NO;
	}
}

@end
